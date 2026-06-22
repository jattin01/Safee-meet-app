import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/messaging/domain/entities/message_entity.dart';
import 'package:safee_meet/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:safee_meet/features/messaging/presentation/bloc/messaging_bloc.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

final _conversation = ConversationEntity(
  id: 'c1',
  partnerId: 'u2',
  partnerName: 'Bob Jones',
  partnerVerificationLevel: 'level1',
  unreadCount: 1,
  updatedAt: DateTime(2025, 6, 10, 12, 0),
);

final _message = MessageEntity(
  id: 'msg1',
  conversationId: 'c1',
  senderId: 'u1',
  content: 'Hello!',
  type: MessageType.text,
  status: MessageStatus.delivered,
  createdAt: DateTime(2025, 6, 10, 12, 1),
);

final _message2 = MessageEntity(
  id: 'msg2',
  conversationId: 'c1',
  senderId: 'u1',
  content: 'Reply!',
  type: MessageType.text,
  status: MessageStatus.sent,
  createdAt: DateTime(2025, 6, 10, 12, 2),
);

void main() {
  late MockMessagingRepository repository;
  late StreamController<MessageEntity> streamController;

  setUp(() {
    repository = MockMessagingRepository();
    streamController = StreamController<MessageEntity>.broadcast();
    when(() => repository.messageStream(any()))
        .thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  MessagingBloc _bloc() => MessagingBloc(repository);

  group('ConversationsLoaded event', () {
    blocTest<MessagingBloc, MessagingState>(
      'emits [MessagingLoading, ConversationsState] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.getConversations())
            .thenAnswer((_) async => Right([_conversation]));
      },
      act: (bloc) => bloc.add(const ConversationsLoaded()),
      expect: () => [
        const MessagingLoading(),
        ConversationsState([_conversation]),
      ],
    );

    blocTest<MessagingBloc, MessagingState>(
      'emits [MessagingLoading, MessagingError] on failure',
      build: _bloc,
      setUp: () {
        when(() => repository.getConversations())
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const ConversationsLoaded()),
      expect: () => [
        const MessagingLoading(),
        isA<MessagingError>(),
      ],
    );
  });

  group('ConversationOpened event', () {
    blocTest<MessagingBloc, MessagingState>(
      'emits [MessagingLoading, ChatState] on success',
      build: _bloc,
      setUp: () {
        when(() => repository.getMessages(any()))
            .thenAnswer((_) async => Right([_message]));
      },
      act: (bloc) => bloc.add(const ConversationOpened('c1')),
      expect: () => [
        const MessagingLoading(),
        ChatState(conversationId: 'c1', messages: [_message]),
      ],
    );

    blocTest<MessagingBloc, MessagingState>(
      'emits [MessagingLoading, MessagingError] on failure',
      build: _bloc,
      setUp: () {
        when(() => repository.getMessages(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Load failed')));
      },
      act: (bloc) => bloc.add(const ConversationOpened('c1')),
      expect: () => [
        const MessagingLoading(),
        isA<MessagingError>(),
      ],
    );
  });

  group('MessageSent event', () {
    blocTest<MessagingBloc, MessagingState>(
      'appends sent message to ChatState messages list',
      build: _bloc,
      seed: () => ChatState(conversationId: 'c1', messages: [_message]),
      setUp: () {
        when(() => repository.sendMessage(
              conversationId: any(named: 'conversationId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => Right(_message2));
      },
      act: (bloc) => bloc.add(const MessageSent(
        conversationId: 'c1',
        content: 'Reply!',
      )),
      expect: () => [
        ChatState(conversationId: 'c1', messages: [_message], isSending: true),
        ChatState(conversationId: 'c1', messages: [_message, _message2]),
      ],
    );
  });
}
