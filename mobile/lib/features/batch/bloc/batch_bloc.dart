import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../model/batch_model.dart';
import '../../../core/api/api_client.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class BatchEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadBatches extends BatchEvent {}

class LoadProducts extends BatchEvent {}

class CreateBatch extends BatchEvent {
  final String productId;
  final double quantity;
  final String unit;
  final String productionDate;
  final String expiryDate;
  final String? originLocation;
  CreateBatch({
    required this.productId,
    required this.quantity,
    required this.unit,
    required this.productionDate,
    required this.expiryDate,
    this.originLocation,
  });
  @override List<Object?> get props => [productId, quantity, unit, productionDate, expiryDate];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class BatchState extends Equatable {
  @override List<Object?> get props => [];
}

class BatchInitial extends BatchState {}
class BatchLoading extends BatchState {}

class BatchListLoaded extends BatchState {
  final List<BatchResponse> batches;
  BatchListLoaded(this.batches);
  @override List<Object?> get props => [batches];
}

class ProductsLoaded extends BatchState {
  final List<ProductItem> products;
  ProductsLoaded(this.products);
  @override List<Object?> get props => [products];
}

class BatchCreated extends BatchState {
  final BatchResponse batch;
  BatchCreated(this.batch);
  @override List<Object?> get props => [batch];
}

class BatchError extends BatchState {
  final String message;
  BatchError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class BatchBloc extends Bloc<BatchEvent, BatchState> {
  final Dio _dio = ApiClient.create();

  BatchBloc() : super(BatchInitial()) {
    on<LoadBatches>(_onLoadBatches);
    on<LoadProducts>(_onLoadProducts);
    on<CreateBatch>(_onCreateBatch);
  }

  Future<void> _onLoadBatches(LoadBatches event, Emitter<BatchState> emit) async {
    emit(BatchLoading());
    try {
      final res = await _dio.get('/batches');
      final list = (res.data as List).map((e) => BatchResponse.fromJson(e)).toList();
      emit(BatchListLoaded(list));
    } catch (e) {
      emit(BatchError('Batch listesi yüklenemedi'));
    }
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<BatchState> emit) async {
    emit(BatchLoading());
    try {
      final res = await _dio.get('/products');
      final list = (res.data as List).map((e) => ProductItem.fromJson(e)).toList();
      emit(ProductsLoaded(list));
    } catch (e) {
      emit(BatchError('Ürün listesi yüklenemedi'));
    }
  }

  Future<void> _onCreateBatch(CreateBatch event, Emitter<BatchState> emit) async {
    emit(BatchLoading());
    try {
      final res = await _dio.post('/batches', data: {
        'productId': event.productId,
        'quantity': event.quantity,
        'unit': event.unit,
        'productionDate': event.productionDate,
        'expiryDate': event.expiryDate,
        'originLocation': event.originLocation,
      });
      emit(BatchCreated(BatchResponse.fromJson(res.data)));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Batch oluşturulamadı';
      emit(BatchError(msg));
    }
  }
}
