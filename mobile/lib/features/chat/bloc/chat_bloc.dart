import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ChatMessage extends Equatable {
  final String role;    // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  @override
  List<Object?> get props => [role, content];
}

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class SendChatMessage extends ChatEvent {
  final String message;
  const SendChatMessage(this.message);
  @override
  List<Object?> get props => [message];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatMessagesState extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatMessagesState({required this.messages, this.isLoading = false});

  ChatMessagesState copyWith({List<ChatMessage>? messages, bool? isLoading}) =>
      ChatMessagesState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [messages, isLoading];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatMessagesState(messages: [])) {
    on<SendChatMessage>(_onSend);
  }

  Future<void> _onSend(SendChatMessage event, Emitter<ChatState> emit) async {
    final current = state is ChatMessagesState
        ? (state as ChatMessagesState)
        : const ChatMessagesState(messages: []);

    final userMsg = ChatMessage(role: 'user', content: event.message);
    final withUser = current.copyWith(
      messages: [...current.messages, userMsg],
      isLoading: true,
    );
    emit(withUser);

    try {
      final dio = ApiClient.create();
      final response = await dio.post('/chat', data: {
        'message': event.message,
        'history': current.messages.map((m) => m.toJson()).toList(),
      });

      final reply = response.data['reply'] as String? ?? 'Yanıt alınamadı.';
      final assistantMsg = ChatMessage(role: 'assistant', content: reply);

      emit(withUser.copyWith(
        messages: [...withUser.messages, assistantMsg],
        isLoading: false,
      ));
    } catch (_) {
      const errMsg = ChatMessage(
        role: 'assistant',
        content: 'Bir hata oluştu. Lütfen tekrar deneyin.',
      );
      emit(withUser.copyWith(
        messages: [...withUser.messages, errMsg],
        isLoading: false,
      ));
    }
  }
}
