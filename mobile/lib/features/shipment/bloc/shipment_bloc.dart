import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/shipment_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class ShipmentEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadShipments extends ShipmentEvent {}

class CreateShipment extends ShipmentEvent {
  final String batchId;
  final String fromLocation;
  final String toLocation;
  final String? vehiclePlate;
  final String? notes;
  final double? distanceKm;
  final double? plannedHours;
  final String? vehicleType;
  final String? weatherCondition;
  final String? trafficLevel;
  CreateShipment({
    required this.batchId,
    required this.fromLocation,
    required this.toLocation,
    this.vehiclePlate,
    this.notes,
    this.distanceKm,
    this.plannedHours,
    this.vehicleType,
    this.weatherCondition,
    this.trafficLevel,
  });
  @override List<Object?> get props => [batchId, fromLocation, toLocation];
}

class AddShipmentEvent extends ShipmentEvent {
  final String shipmentId;
  final String eventType;
  final String? locationAddress;
  final String? notes;
  final double? temperature;
  AddShipmentEvent({
    required this.shipmentId,
    required this.eventType,
    this.locationAddress,
    this.notes,
    this.temperature,
  });
  @override List<Object?> get props => [shipmentId, eventType];
}

class DeliverShipment extends ShipmentEvent {
  final String shipmentId;
  DeliverShipment(this.shipmentId);
  @override List<Object?> get props => [shipmentId];
}

class LoadShipmentDetail extends ShipmentEvent {
  final String shipmentId;
  LoadShipmentDetail(this.shipmentId);
  @override List<Object?> get props => [shipmentId];
}

class DeleteShipment extends ShipmentEvent {
  final String id;
  DeleteShipment(this.id);
  @override List<Object?> get props => [id];
}

class LoadAnomalyResult extends ShipmentEvent {
  final String shipmentId;
  LoadAnomalyResult(this.shipmentId);
  @override List<Object?> get props => [shipmentId];
}

class LoadDelayResult extends ShipmentEvent {
  final String shipmentId;
  LoadDelayResult(this.shipmentId);
  @override List<Object?> get props => [shipmentId];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class ShipmentState extends Equatable {
  @override List<Object?> get props => [];
}

class ShipmentInitial extends ShipmentState {}
class ShipmentLoading extends ShipmentState {}

class ShipmentListLoaded extends ShipmentState {
  final List<ShipmentResponse> shipments;
  ShipmentListLoaded(this.shipments);
  @override List<Object?> get props => [shipments];
}

class ShipmentDetailLoaded extends ShipmentState {
  final ShipmentResponse shipment;
  ShipmentDetailLoaded(this.shipment);
  @override List<Object?> get props => [shipment];
}

class ShipmentCreated extends ShipmentState {
  final ShipmentResponse shipment;
  ShipmentCreated(this.shipment);
  @override List<Object?> get props => [shipment];
}

class ShipmentEventAdded extends ShipmentState {
  final ShipmentResponse shipment;
  ShipmentEventAdded(this.shipment);
  @override List<Object?> get props => [shipment];
}

class ShipmentDeleted extends ShipmentState {}

class ShipmentError extends ShipmentState {
  final String message;
  ShipmentError(this.message);
  @override List<Object?> get props => [message];
}

class AnomalyResultLoaded extends ShipmentState {
  final bool isAnomaly;
  final String riskLevel;
  final double riskScore;
  final String? anomalyType;
  final String recommendedAction;
  final bool hasData;
  AnomalyResultLoaded({
    required this.isAnomaly,
    required this.riskLevel,
    required this.riskScore,
    this.anomalyType,
    required this.recommendedAction,
    required this.hasData,
  });
  @override List<Object?> get props => [isAnomaly, riskLevel, riskScore];
}

class DelayResultLoaded extends ShipmentState {
  final bool hasData;
  final bool delayPredicted;
  final double delayProbability;
  final double estimatedDelayHours;
  final String delayRiskLevel;
  final List<String> delayReasons;
  final String recommendation;
  final String? message;
  DelayResultLoaded({
    required this.hasData,
    this.delayPredicted = false,
    this.delayProbability = 0,
    this.estimatedDelayHours = 0,
    this.delayRiskLevel = 'LOW',
    this.delayReasons = const [],
    this.recommendation = '',
    this.message,
  });
  @override List<Object?> get props => [hasData, delayPredicted, delayRiskLevel];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final Dio _dio = ApiClient.create();

  ShipmentBloc() : super(ShipmentInitial()) {
    on<LoadShipments>(_onLoadShipments);
    on<CreateShipment>(_onCreateShipment);
    on<AddShipmentEvent>(_onAddEvent);
    on<DeliverShipment>(_onDeliver);
    on<LoadShipmentDetail>(_onLoadDetail);
    on<LoadAnomalyResult>(_onLoadAnomaly);
    on<LoadDelayResult>(_onLoadDelay);
    on<DeleteShipment>(_onDeleteShipment);
  }

  Future<void> _onDeleteShipment(DeleteShipment event, Emitter<ShipmentState> emit) async {
    try {
      await _dio.delete('/shipments/${event.id}');
      emit(ShipmentDeleted());
    } on DioException catch (e) {
      emit(ShipmentError(e.response?.data?['error'] ?? 'Silinemedi'));
    }
  }

  Future<void> _onLoadShipments(LoadShipments event, Emitter<ShipmentState> emit) async {
    emit(ShipmentLoading());
    try {
      final res = await _dio.get('/shipments');
      final list = (res.data as List).map((e) => ShipmentResponse.fromJson(e)).toList();
      emit(ShipmentListLoaded(list));
    } catch (e) {
      emit(ShipmentError('Sevkiyat listesi yüklenemedi'));
    }
  }

  Future<void> _onCreateShipment(CreateShipment event, Emitter<ShipmentState> emit) async {
    emit(ShipmentLoading());
    try {
      final res = await _dio.post('/shipments', data: {
        'batchId': event.batchId,
        'fromLocation': event.fromLocation,
        'toLocation': event.toLocation,
        'vehiclePlate': event.vehiclePlate,
        'notes': event.notes,
        if (event.distanceKm != null) 'distanceKm': event.distanceKm,
        if (event.plannedHours != null) 'plannedHours': event.plannedHours,
        if (event.vehicleType != null) 'vehicleType': event.vehicleType,
        if (event.weatherCondition != null) 'weatherCondition': event.weatherCondition,
        if (event.trafficLevel != null) 'trafficLevel': event.trafficLevel,
      });
      emit(ShipmentCreated(ShipmentResponse.fromJson(res.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Sevkiyat oluşturulamadı';
      emit(ShipmentError(msg));
    }
  }

  Future<void> _onAddEvent(AddShipmentEvent event, Emitter<ShipmentState> emit) async {
    emit(ShipmentLoading());
    try {
      await _dio.post('/shipments/${event.shipmentId}/events', data: {
        'eventType': event.eventType,
        'locationAddress': event.locationAddress,
        'notes': event.notes,
        'temperature': event.temperature,
      });
      final res = await _dio.get('/shipments/${event.shipmentId}');
      emit(ShipmentEventAdded(ShipmentResponse.fromJson(res.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Olay eklenemedi';
      emit(ShipmentError(msg));
    }
  }

  Future<void> _onDeliver(DeliverShipment event, Emitter<ShipmentState> emit) async {
    emit(ShipmentLoading());
    try {
      final res = await _dio.put('/shipments/${event.shipmentId}/deliver');
      emit(ShipmentEventAdded(ShipmentResponse.fromJson(res.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Teslimat güncellenemedi';
      emit(ShipmentError(msg));
    }
  }

  Future<void> _onLoadDetail(LoadShipmentDetail event, Emitter<ShipmentState> emit) async {
    emit(ShipmentLoading());
    try {
      final res = await _dio.get('/shipments/${event.shipmentId}');
      emit(ShipmentDetailLoaded(ShipmentResponse.fromJson(res.data)));
    } catch (e) {
      emit(ShipmentError('Sevkiyat detayı yüklenemedi'));
    }
  }

  Future<void> _onLoadAnomaly(LoadAnomalyResult event, Emitter<ShipmentState> emit) async {
    try {
      final res = await _dio.get('/shipments/${event.shipmentId}/anomaly');
      final data = res.data as Map<String, dynamic>;
      emit(AnomalyResultLoaded(
        isAnomaly: data['isAnomaly'] as bool? ?? false,
        riskLevel: data['riskLevel'] as String? ?? 'UNKNOWN',
        riskScore: (data['riskScore'] as num?)?.toDouble() ?? 0.0,
        anomalyType: data['anomalyType'] as String?,
        recommendedAction: data['recommendedAction'] as String? ?? '',
        hasData: data['hasData'] as bool? ?? false,
      ));
    } catch (_) {
      // Sessizce başarısız ol — anomali yüklenemezse UI'ı bozmayalım
    }
  }

  Future<void> _onLoadDelay(LoadDelayResult event, Emitter<ShipmentState> emit) async {
    try {
      final res = await _dio.get('/shipments/${event.shipmentId}/delay');
      final data = res.data as Map<String, dynamic>;
      final hasData = data['hasData'] as bool? ?? false;
      if (!hasData) {
        emit(DelayResultLoaded(hasData: false, message: data['message'] as String?));
        return;
      }
      emit(DelayResultLoaded(
        hasData: true,
        delayPredicted: data['delayPredicted'] as bool? ?? false,
        delayProbability: (data['delayProbability'] as num?)?.toDouble() ?? 0.0,
        estimatedDelayHours: (data['estimatedDelayHours'] as num?)?.toDouble() ?? 0.0,
        delayRiskLevel: data['delayRiskLevel'] as String? ?? 'LOW',
        delayReasons: (data['delayReasons'] as List?)?.cast<String>() ?? [],
        recommendation: data['recommendation'] as String? ?? '',
      ));
    } catch (_) {
      // Sessizce başarısız ol
    }
  }
}
