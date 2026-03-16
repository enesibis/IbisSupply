import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/quality_check_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class QualityEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadMyChecks extends QualityEvent {}

class LoadBatches extends QualityEvent {}

class CreateCheck extends QualityEvent {
  final String batchId;
  final String result;
  final double? temperature;
  final double? humidity;
  final bool contaminationDetected;
  final String? notes;

  CreateCheck({
    required this.batchId,
    required this.result,
    this.temperature,
    this.humidity,
    required this.contaminationDetected,
    this.notes,
  });

  @override List<Object?> get props => [batchId, result];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class QualityState extends Equatable {
  @override List<Object?> get props => [];
}

class QualityInitial extends QualityState {}
class QualityLoading extends QualityState {}

class ChecksLoaded extends QualityState {
  final List<QualityCheckResponse> checks;
  ChecksLoaded(this.checks);
  @override List<Object?> get props => [checks];
}

class BatchesLoaded extends QualityState {
  final List<Map<String, dynamic>> batches;
  BatchesLoaded(this.batches);
  @override List<Object?> get props => [batches];
}

class CheckCreated extends QualityState {
  final QualityCheckResponse check;
  CheckCreated(this.check);
  @override List<Object?> get props => [check];
}

class QualityError extends QualityState {
  final String message;
  QualityError(this.message);
  @override List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class QualityBloc extends Bloc<QualityEvent, QualityState> {
  final Dio _dio = ApiClient.create();

  QualityBloc() : super(QualityInitial()) {
    on<LoadMyChecks>(_onLoadMyChecks);
    on<LoadBatches>(_onLoadBatches);
    on<CreateCheck>(_onCreateCheck);
  }

  Future<void> _onLoadMyChecks(LoadMyChecks event, Emitter<QualityState> emit) async {
    emit(QualityLoading());
    try {
      final response = await _dio.get('/quality-checks');
      final checks = (response.data as List)
          .map((e) => QualityCheckResponse.fromJson(e))
          .toList();
      emit(ChecksLoaded(checks));
    } on DioException catch (e) {
      emit(QualityError(e.response?.data?['message'] ?? 'Yüklenemedi'));
    }
  }

  Future<void> _onLoadBatches(LoadBatches event, Emitter<QualityState> emit) async {
    emit(QualityLoading());
    try {
      final response = await _dio.get('/batches');
      final batches = (response.data as List).cast<Map<String, dynamic>>();
      emit(BatchesLoaded(batches));
    } on DioException catch (e) {
      emit(QualityError(e.response?.data?['message'] ?? 'Batch listesi yüklenemedi'));
    }
  }

  Future<void> _onCreateCheck(CreateCheck event, Emitter<QualityState> emit) async {
    emit(QualityLoading());
    try {
      final response = await _dio.post('/quality-checks', data: {
        'batchId': event.batchId,
        'result': event.result,
        'temperature': event.temperature,
        'humidity': event.humidity,
        'contaminationDetected': event.contaminationDetected,
        'notes': event.notes,
      });
      emit(CheckCreated(QualityCheckResponse.fromJson(response.data)));
    } on DioException catch (e) {
      emit(QualityError(e.response?.data?['message'] ?? 'Kontrol kaydedilemedi'));
    }
  }
}
