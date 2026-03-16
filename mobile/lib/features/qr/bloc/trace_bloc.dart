import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/trace_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class TraceEvent extends Equatable {
  @override List<Object?> get props => [];
}

class TraceByBatchCode extends TraceEvent {
  final String batchCode;
  TraceByBatchCode(this.batchCode);
  @override List<Object?> get props => [batchCode];
}

class TraceByQrCode extends TraceEvent {
  final String qrCode;
  TraceByQrCode(this.qrCode);
  @override List<Object?> get props => [qrCode];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class TraceState extends Equatable {
  @override List<Object?> get props => [];
}

class TraceInitial extends TraceState {}
class TraceLoading extends TraceState {}

class TraceLoaded extends TraceState {
  final TraceResponse trace;
  TraceLoaded(this.trace);
  @override List<Object?> get props => [trace];
}

class TraceError extends TraceState {
  final String message;
  TraceError(this.message);
  @override List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class TraceBloc extends Bloc<TraceEvent, TraceState> {
  final Dio _dio = ApiClient.create();

  TraceBloc() : super(TraceInitial()) {
    on<TraceByBatchCode>(_onTraceByBatchCode);
    on<TraceByQrCode>(_onTraceByQrCode);
  }

  Future<void> _onTraceByBatchCode(TraceByBatchCode event, Emitter<TraceState> emit) async {
    emit(TraceLoading());
    try {
      final response = await _dio.get('/trace/batch/${event.batchCode}');
      emit(TraceLoaded(TraceResponse.fromJson(response.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Ürün bulunamadı';
      emit(TraceError(msg));
    }
  }

  Future<void> _onTraceByQrCode(TraceByQrCode event, Emitter<TraceState> emit) async {
    emit(TraceLoading());
    try {
      final response = await _dio.get('/trace/qr/${event.qrCode}');
      emit(TraceLoaded(TraceResponse.fromJson(response.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'QR kod geçersiz';
      emit(TraceError(msg));
    }
  }
}
