import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/auth_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/auth_storage.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String role;
  final String fullName;
  final String email;
  final String? orgName;
  AuthAuthenticated({
    required this.role,
    required this.fullName,
    required this.email,
    this.orgName,
  });
  @override
  List<Object?> get props => [role, fullName, email];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Dio _dio = ApiClient.create();

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheckAuth(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final loggedIn = await AuthStorage.isLoggedIn();
    if (loggedIn) {
      final role = await AuthStorage.getRole() ?? '';
      final fullName = await AuthStorage.getFullName() ?? '';
      final email = await AuthStorage.getEmail() ?? '';
      final orgName = await AuthStorage.getOrgName();
      emit(AuthAuthenticated(role: role, fullName: fullName, email: email, orgName: orgName));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': event.email,
        'password': event.password,
      });
      final auth = AuthResponse.fromJson(response.data);
      await AuthStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      await AuthStorage.saveUserInfo(
        role: auth.role,
        fullName: auth.fullName,
        email: auth.email,
        orgName: auth.organizationName,
      );
      emit(AuthAuthenticated(
        role: auth.role,
        fullName: auth.fullName,
        email: auth.email,
        orgName: auth.organizationName,
      ));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Giriş başarısız. Bilgileri kontrol edin.';
      emit(AuthError(message));
    } catch (_) {
      emit(AuthError('Bağlantı hatası. Sunucu çalışıyor mu?'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await AuthStorage.clear();
    emit(AuthUnauthenticated());
  }
}
