import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/farm_record_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class FarmEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadMyFarmRecords extends FarmEvent {}

class LoadBatchesForFarm extends FarmEvent {}

class CreateFarmRecord extends FarmEvent {
  final String batchId;
  final String? fieldLocation;
  final String? plantingDate;
  final String? harvestDate;
  final String? irrigationType;
  final double? totalIrrigationHours;
  final String? pesticides;
  final String? fertilizers;
  final String? notes;

  CreateFarmRecord({
    required this.batchId,
    this.fieldLocation,
    this.plantingDate,
    this.harvestDate,
    this.irrigationType,
    this.totalIrrigationHours,
    this.pesticides,
    this.fertilizers,
    this.notes,
  });

  @override List<Object?> get props => [batchId];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class FarmState extends Equatable {
  @override List<Object?> get props => [];
}

class FarmInitial extends FarmState {}
class FarmLoading extends FarmState {}

class FarmRecordsLoaded extends FarmState {
  final List<FarmRecordResponse> records;
  FarmRecordsLoaded(this.records);
  @override List<Object?> get props => [records];
}

class FarmBatchesLoaded extends FarmState {
  final List<Map<String, dynamic>> batches;
  FarmBatchesLoaded(this.batches);
  @override List<Object?> get props => [batches];
}

class FarmRecordCreated extends FarmState {
  final FarmRecordResponse record;
  FarmRecordCreated(this.record);
  @override List<Object?> get props => [record];
}

class FarmError extends FarmState {
  final String message;
  FarmError(this.message);
  @override List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class FarmBloc extends Bloc<FarmEvent, FarmState> {
  final Dio _dio = ApiClient.create();

  FarmBloc() : super(FarmInitial()) {
    on<LoadMyFarmRecords>(_onLoadMine);
    on<LoadBatchesForFarm>(_onLoadBatches);
    on<CreateFarmRecord>(_onCreate);
  }

  Future<void> _onLoadMine(LoadMyFarmRecords event, Emitter<FarmState> emit) async {
    emit(FarmLoading());
    try {
      final response = await _dio.get('/farm-records');
      final records = (response.data as List)
          .map((e) => FarmRecordResponse.fromJson(e))
          .toList();
      emit(FarmRecordsLoaded(records));
    } on DioException catch (e) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      final errType = e.type.toString();
      print('[FarmBloc] LoadMine hata: type=$errType status=$statusCode data=$data');
      emit(FarmError((data is Map ? data['message'] : null) ?? 'Yüklenemedi ($errType ${statusCode ?? 'no-resp'})'));
    }
  }

  Future<void> _onLoadBatches(LoadBatchesForFarm event, Emitter<FarmState> emit) async {
    emit(FarmLoading());
    try {
      final response = await _dio.get('/batches');
      final batches = (response.data as List).cast<Map<String, dynamic>>();
      emit(FarmBatchesLoaded(batches));
    } on DioException catch (e) {
      final data = e.response?.data;
      emit(FarmError((data is Map ? data['message'] : null) ?? 'Batch listesi yüklenemedi'));
    }
  }

  Future<void> _onCreate(CreateFarmRecord event, Emitter<FarmState> emit) async {
    emit(FarmLoading());
    try {
      final response = await _dio.post('/farm-records', data: {
        'batchId': event.batchId,
        'fieldLocation': event.fieldLocation,
        'plantingDate': event.plantingDate,
        'harvestDate': event.harvestDate,
        'irrigationType': event.irrigationType,
        'totalIrrigationHours': event.totalIrrigationHours,
        'pesticides': event.pesticides,
        'fertilizers': event.fertilizers,
        'notes': event.notes,
      });
      emit(FarmRecordCreated(FarmRecordResponse.fromJson(response.data)));
    } on DioException catch (e) {
      final data = e.response?.data;
      emit(FarmError((data is Map ? data['message'] : null) ?? 'Kayıt oluşturulamadı'));
    }
  }
}
