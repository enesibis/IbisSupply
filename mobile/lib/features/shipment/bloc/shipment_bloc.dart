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
  CreateShipment({
    required this.batchId,
    required this.fromLocation,
    required this.toLocation,
    this.vehiclePlate,
    this.notes,
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

class ShipmentError extends ShipmentState {
  final String message;
  ShipmentError(this.message);
  @override List<Object?> get props => [message];
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
}
