import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.reservationId,
    required super.senderId,
    required super.senderRole,
    super.senderName,
    super.senderPhoto,
    required super.content,
    super.messageType,
    super.imageUrl,
    super.latitude,
    super.longitude,
    super.isRead,
    super.readAt,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Gérer senderId qui peut être un objet ou un string
    final sender = json['senderId'];
    String senderId;
    String? senderName;
    String? senderPhoto;

    if (sender is Map<String, dynamic>) {
      senderId = sender['_id'] as String? ?? '';
      senderName =
          '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'.trim();
      senderPhoto = sender['profilePhoto'] as String?;
    } else {
      senderId = sender as String? ?? '';
    }

    // Gérer reservationId qui peut être un objet ou un string
    final reservationIdRaw = json['reservationId'];
    String reservationId;
    if (reservationIdRaw is Map<String, dynamic>) {
      reservationId = reservationIdRaw['_id'] as String? ?? '';
    } else {
      reservationId = reservationIdRaw as String? ?? '';
    }

    MessageType messageType;
    switch (json['messageType'] as String? ?? 'text') {
      case 'image':
        messageType = MessageType.image;
        break;
      case 'location':
        messageType = MessageType.location;
        break;
      case 'system':
        messageType = MessageType.system;
        break;
      default:
        messageType = MessageType.text;
    }

    final location = json['location'] as Map<String, dynamic>?;

    return ChatMessageModel(
      id: json['_id'] as String? ?? '',
      reservationId: reservationId,
      senderId: senderId,
      senderRole: json['senderRole'] as String? ?? 'client',
      senderName: senderName,
      senderPhoto: senderPhoto,
      content: json['content'] as String? ?? '',
      messageType: messageType,
      imageUrl: json['imageUrl'] as String?,
      latitude: location?['latitude'] as double?,
      longitude: location?['longitude'] as double?,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'messageType': messageType.name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (latitude != null && longitude != null)
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
    };
  }
}
