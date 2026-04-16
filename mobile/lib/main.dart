import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
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
  late final _AuthRouterNotifier _routerNotifier;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(CheckAuthStatus());
    _routerNotifier = _AuthRouterNotifier(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _routerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'IbisSupply',
        theme: AppTheme.light,
        routerConfig: buildAppRouter(_routerNotifier),
        debugShowCheckedModeBanner: false,
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
