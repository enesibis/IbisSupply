import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/theme_cubit.dart';
import 'core/utils/app_router.dart' show buildAppRouter;
import 'features/auth/bloc/auth_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IbisSupplyApp());
}

class IbisSupplyApp extends StatefulWidget {
  const IbisSupplyApp({super.key});

  @override
  State<IbisSupplyApp> createState() => _IbisSupplyAppState();
}

class _IbisSupplyAppState extends State<IbisSupplyApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final _AuthRouterNotifier _routerNotifier;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(CheckAuthStatus());
    _themeCubit = ThemeCubit()..load();
    _routerNotifier = _AuthRouterNotifier(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _themeCubit.close();
    _routerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'IbisSupply',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: buildAppRouter(_routerNotifier),
            debugShowCheckedModeBanner: false,
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}

/// GoRouter'ın AuthBloc state değişimlerini dinlemesi için Listenable köprüsü.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
