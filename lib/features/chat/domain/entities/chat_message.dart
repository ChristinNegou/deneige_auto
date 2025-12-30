import 'package:equatable/equatable.dart';

enum MessageType { text, image, location, system }

class ChatMessage extends Equatable {
  final String id;
  final String reservationId;
  final String senderId;
  final String senderRole;
  final String? senderName;
  final String? senderPhoto;
  final String content;
  final MessageType messageType;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.reservationId,
    required this.senderId,
    required this.senderRole,
    this.senderName,
    this.senderPhoto,
    required this.content,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  bool get isFromClient => senderRole == 'client';
  bool get isFromWorker => senderRole == 'worker';

  @override
  List<Object?> get props => [
        id,
        reservationId,
        senderId,
        senderRole,
        content,
        messageType,
        isRead,
        createdAt,
      ];
}
