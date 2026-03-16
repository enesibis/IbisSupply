import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/user_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AdminEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadUsers extends AdminEvent {}

class CreateUser extends AdminEvent {
  final String fullName, email, password, role;
  final String? phone;
  CreateUser({required this.fullName, required this.email, required this.password, required this.role, this.phone});
  @override List<Object?> get props => [email];
}

class UpdateRole extends AdminEvent {
  final String userId, role;
  UpdateRole({required this.userId, required this.role});
  @override List<Object?> get props => [userId, role];
}

class ToggleActive extends AdminEvent {
  final String userId;
  ToggleActive(this.userId);
  @override List<Object?> get props => [userId];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AdminState extends Equatable {
  @override List<Object?> get props => [];
}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

class UsersLoaded extends AdminState {
  final List<UserResponse> users;
  UsersLoaded(this.users);
  @override List<Object?> get props => [users];
}

class UserCreated extends AdminState {
  final UserResponse user;
  UserCreated(this.user);
  @override List<Object?> get props => [user];
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
  @override List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final Dio _dio = ApiClient.create();

  AdminBloc() : super(AdminInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateRole>(_onUpdateRole);
    on<ToggleActive>(_onToggleActive);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final response = await _dio.get('/admin/users');
      final users = (response.data as List).map((e) => UserResponse.fromJson(e)).toList();
      emit(UsersLoaded(users));
    } on DioException catch (e) {
      emit(AdminError(e.response?.data?['message'] ?? 'Yüklenemedi'));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final response = await _dio.post('/admin/users', data: {
        'fullName': event.fullName,
        'email': event.email,
        'password': event.password,
        'phone': event.phone,
        'role': event.role,
      });
      emit(UserCreated(UserResponse.fromJson(response.data)));
    } on DioException catch (e) {
      emit(AdminError(e.response?.data?['message'] ?? 'Kullanıcı oluşturulamadı'));
    }
  }

  Future<void> _onUpdateRole(UpdateRole event, Emitter<AdminState> emit) async {
    try {
      await _dio.put('/admin/users/${event.userId}/role', data: {'role': event.role});
      add(LoadUsers());
    } on DioException catch (e) {
      emit(AdminError(e.response?.data?['message'] ?? 'Rol güncellenemedi'));
    }
  }

  Future<void> _onToggleActive(ToggleActive event, Emitter<AdminState> emit) async {
    try {
      await _dio.put('/admin/users/${event.userId}/toggle-active');
      add(LoadUsers());
    } on DioException catch (e) {
      emit(AdminError(e.response?.data?['message'] ?? 'Durum güncellenemedi'));
    }
  }
}
