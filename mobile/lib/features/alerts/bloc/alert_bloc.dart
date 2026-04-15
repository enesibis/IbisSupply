import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/alert_model.dart';
import '../../../core/api/api_client.dart';

// Events
abstract class AlertEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadAlerts extends AlertEvent {}
class ResolveAlert extends AlertEvent {
  final String id;
  ResolveAlert(this.id);
  @override List<Object?> get props => [id];
}

// States
abstract class AlertState extends Equatable {
  @override List<Object?> get props => [];
}
class AlertInitial extends AlertState {}
class AlertLoading extends AlertState {}
class AlertsLoaded extends AlertState {
  final List<AlertModel> alerts;
  AlertsLoaded(this.alerts);
  @override List<Object?> get props => [alerts];
}
class AlertError extends AlertState {
  final String message;
  AlertError(this.message);
  @override List<Object?> get props => [message];
}

// Bloc
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final Dio _dio = ApiClient.create();

  AlertBloc() : super(AlertInitial()) {
    on<LoadAlerts>(_onLoad);
    on<ResolveAlert>(_onResolve);
  }

  Future<void> _onLoad(LoadAlerts event, Emitter<AlertState> emit) async {
    emit(AlertLoading());
    try {
      final response = await _dio.get('/alerts');
      final alerts = (response.data as List)
          .map((e) => AlertModel.fromJson(e))
          .toList();
      emit(AlertsLoaded(alerts));
    } on DioException catch (e) {
      final data = e.response?.data;
      emit(AlertError((data is Map ? data['message'] : null) ?? 'Yüklenemedi'));
    }
  }

  Future<void> _onResolve(ResolveAlert event, Emitter<AlertState> emit) async {
    try {
      await _dio.patch('/alerts/${event.id}/resolve');
      add(LoadAlerts());
    } on DioException catch (_) {}
  }
}
