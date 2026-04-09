import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class CustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends CustomerEvent {}

class AddFavorite extends CustomerEvent {
  final String batchCode;
  AddFavorite(this.batchCode);
  @override
  List<Object?> get props => [batchCode];
}

class RemoveFavorite extends CustomerEvent {
  final String batchCode;
  RemoveFavorite(this.batchCode);
  @override
  List<Object?> get props => [batchCode];
}

class LoadMyComplaints extends CustomerEvent {}

class SubmitComplaint extends CustomerEvent {
  final String subject;
  final String description;
  final String? batchCode;
  SubmitComplaint({required this.subject, required this.description, this.batchCode});
  @override
  List<Object?> get props => [subject, description, batchCode];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class CustomerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}

class FavoritesLoaded extends CustomerState {
  final List<Map<String, dynamic>> favorites;
  FavoritesLoaded(this.favorites);
  @override
  List<Object?> get props => [favorites];
}

class FavoriteAdded extends CustomerState {
  final String productName;
  FavoriteAdded(this.productName);
  @override
  List<Object?> get props => [productName];
}

class FavoriteRemoved extends CustomerState {}

class ComplaintsLoaded extends CustomerState {
  final List<Map<String, dynamic>> complaints;
  ComplaintsLoaded(this.complaints);
  @override
  List<Object?> get props => [complaints];
}

class ComplaintSubmitted extends CustomerState {}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final Dio _dio = ApiClient.create();

  CustomerBloc() : super(CustomerInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddFavorite>(_onAddFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
    on<LoadMyComplaints>(_onLoadComplaints);
    on<SubmitComplaint>(_onSubmitComplaint);
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final response = await _dio.get('/user/favorites');
      final list = (response.data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      emit(FavoritesLoaded(list));
    } on DioException catch (e) {
      emit(CustomerError(e.response?.data?['message'] ?? 'Favoriler yüklenemedi'));
    }
  }

  Future<void> _onAddFavorite(AddFavorite event, Emitter<CustomerState> emit) async {
    try {
      final response = await _dio.post('/user/favorites', data: {'batchCode': event.batchCode});
      emit(FavoriteAdded(response.data['productName'] ?? ''));
    } on DioException catch (e) {
      emit(CustomerError(e.response?.data?['message'] ?? 'Favoriye eklenemedi'));
    }
  }

  Future<void> _onRemoveFavorite(RemoveFavorite event, Emitter<CustomerState> emit) async {
    try {
      await _dio.delete('/user/favorites/${event.batchCode}');
      emit(FavoriteRemoved());
    } on DioException catch (e) {
      emit(CustomerError(e.response?.data?['message'] ?? 'Favoriden çıkarılamadı'));
    }
  }

  Future<void> _onLoadComplaints(LoadMyComplaints event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final response = await _dio.get('/complaints/my');
      final list = (response.data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      emit(ComplaintsLoaded(list));
    } on DioException catch (e) {
      emit(CustomerError(e.response?.data?['message'] ?? 'Şikayetler yüklenemedi'));
    }
  }

  Future<void> _onSubmitComplaint(SubmitComplaint event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      await _dio.post('/complaints', data: {
        'subject': event.subject,
        'description': event.description,
        'batchCode': event.batchCode,
      });
      emit(ComplaintSubmitted());
    } on DioException catch (e) {
      emit(CustomerError(e.response?.data?['message'] ?? 'Şikayet gönderilemedi'));
    }
  }
}
