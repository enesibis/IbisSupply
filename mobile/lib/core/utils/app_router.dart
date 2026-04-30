import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screen/login_screen.dart';
import '../../features/dashboard/screen/dashboard_screen.dart';
import '../../features/qr/screen/qr_public_screen.dart';
import '../../features/batch/screen/batch_list_screen.dart';
import '../../features/shipment/screen/shipment_list_screen.dart';
import '../../features/qr/screen/product_trace_screen.dart';
import '../../features/quality/screen/quality_list_screen.dart';
import '../../features/quality/screen/quality_create_screen.dart';
import '../../features/admin/screen/admin_user_list_screen.dart';
import '../../features/admin/screen/admin_user_create_screen.dart';
import '../../features/auth/screen/register_screen.dart';
import '../../features/customer/screen/my_products_screen.dart';
import '../../features/customer/screen/complaint_screen.dart';
import '../../features/farm/screen/farm_list_screen.dart';
import '../../features/farm/screen/farm_create_screen.dart';
import '../../features/farm/screen/farm_detail_screen.dart';
import '../../features/batch/screen/batch_detail_screen.dart';
import '../../features/batch/screen/batch_create_screen.dart';
import '../../features/batch/model/batch_model.dart';
import '../../features/farm/model/farm_record_model.dart';
import '../../features/alerts/screen/alerts_screen.dart';
import '../../features/profile/screen/profile_screen.dart';
import '../../features/chat/screen/chat_screen.dart';

GoRouter buildAppRouter(Listenable refreshListenable) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: refreshListenable,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final loc = state.matchedLocation;

    // Splash: AuthInitial iken bekle, sonuç gelince yönlendir
    if (loc == '/splash') {
      if (authState is AuthAuthenticated) return '/dashboard';
      if (authState is AuthUnauthenticated) return '/login';
      return null; // AuthInitial → splash'ta kal
    }

    final isLoginRoute = loc == '/login';
    final isPublicRoute = loc.startsWith('/qr-public') ||
        loc.startsWith('/product-trace') ||
        loc == '/register';

    if (isPublicRoute) return null;

    if (authState is AuthUnauthenticated && !isLoginRoute) return '/login';
    if (authState is AuthAuthenticated && isLoginRoute) return '/dashboard';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/my-products',
      builder: (context, state) => const MyProductsScreen(),
    ),
    GoRoute(
      path: '/complaint',
      builder: (context, state) => ComplaintScreen(
        prefillBatchCode: state.uri.queryParameters['batchCode'],
      ),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/qr-public',
      builder: (context, state) => const QrPublicScreen(),
    ),
    GoRoute(
      path: '/batches',
      builder: (context, state) => const BatchListScreen(),
    ),
    GoRoute(
      path: '/shipments',
      builder: (context, state) => const ShipmentListScreen(),
    ),
    GoRoute(
      path: '/product-trace/:batchCode',
      builder: (context, state) => ProductTraceScreen(
        batchCode: state.pathParameters['batchCode']!,
      ),
    ),
    GoRoute(
      path: '/quality-checks',
      builder: (context, state) => const QualityListScreen(),
    ),
    GoRoute(
      path: '/quality-checks/create',
      builder: (context, state) => const QualityCreateScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUserListScreen(),
    ),
    GoRoute(
      path: '/admin/users/create',
      builder: (context, state) => const AdminUserCreateScreen(),
    ),
    GoRoute(
      path: '/batches/create',
      builder: (context, state) => const BatchCreateScreen(),
    ),
    GoRoute(
      path: '/batches/detail',
      builder: (context, state) => BatchDetailScreen(
        batch: state.extra as BatchResponse,
      ),
    ),
    GoRoute(
      path: '/farm-records',
      builder: (context, state) => const FarmListScreen(),
    ),
    GoRoute(
      path: '/farm-records/create',
      builder: (context, state) => const FarmCreateScreen(),
    ),
    GoRoute(
      path: '/farm-records/detail',
      builder: (context, state) => FarmDetailScreen(
        record: state.extra as FarmRecordResponse,
      ),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // CheckAuthStatus main.dart'taki BlocProvider'da zaten tetikleniyor.
    // refreshListenable sayesinde auth durumu değişince router otomatik yönlendirir.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF07111F), Color(0xFF0B1A33), Color(0xFF0F2550)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => const Icon(
                      LucideIcons.truck,
                      color: Color(0xFF1565C0),
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gıda Tedarik Zinciri',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 52),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
