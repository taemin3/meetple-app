import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/realtime/chat_client_message_id.dart';
import 'package:meetple/data/realtime/stomp_chat_realtime_client.dart';

void main() {
  test('converts HTTP API base URLs to the STOMP WebSocket endpoint', () {
    expect(chatWebSocketUrl('http://localhost:8080'), 'ws://localhost:8080/ws');
    expect(
      chatWebSocketUrl('https://api.meetple.example/v1/'),
      'wss://api.meetple.example/v1/ws',
    );
  });

  test('parses the backend STOMP success envelope', () {
    final message = parseStompChatMessage('''
      {
        "status": 200,
        "success": true,
        "code": 20000,
        "message": "요청에 성공했습니다.",
        "data": {
          "id": 31,
          "roomId": 10,
          "sequence": 7,
          "clientMessageId": "8d36a57b-fbd1-4910-a02d-91ddcbaf8911",
          "senderId": 2,
          "senderNickname": "민준",
          "senderProfileImageUrl": null,
          "content": "곧 도착해요.",
          "createdAt": "2026-08-04T09:30:00"
        }
      }
    ''');

    expect(message.id, 31);
    expect(message.roomId, 10);
    expect(message.sequence, 7);
    expect(message.senderNickname, '민준');
    expect(message.content, '곧 도착해요.');
  });

  test('parses CHAT_ACCESS_REVOKED as a terminal realtime error', () {
    final error = parseStompChatControl('''
      {
        "type": "CHAT_ACCESS_REVOKED",
        "reason": "PARTICIPATION_APPROVAL_REVOKED",
        "roomId": 10
      }
    ''');

    expect(error.isAccessRevoked, isTrue);
    expect(error.reason, 'PARTICIPATION_APPROVAL_REVOKED');
    expect(error.roomId, 10);
    expect(error.message, contains('참여 승인'));
  });

  test('generates a valid UUID v4 client message id', () {
    final generator = ChatClientMessageIdGenerator(random: Random(7));

    expect(
      generator.generate(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('recognizes unauthorized STOMP errors for token refresh', () {
    expect(
      isUnauthorizedStompError(
        body: '{"status":401,"message":"expired"}',
      ),
      isTrue,
    );
    expect(
      isUnauthorizedStompError(headerMessage: '401 Unauthorized'),
      isTrue,
    );
    expect(
      isUnauthorizedStompError(
        body: '{"status":403,"message":"forbidden"}',
      ),
      isFalse,
    );
  });
}
