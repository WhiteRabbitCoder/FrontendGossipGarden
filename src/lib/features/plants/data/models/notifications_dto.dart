class NotificationEvent {
  final String type; // 'chat_message' or 'proactive_alert'
  final String plantId;
  final String plantNickname;
  final String message;
  final String? audioUrl;
  final DateTime timestamp;

  NotificationEvent({
    required this.type,
    required this.plantId,
    required this.plantNickname,
    required this.message,
    this.audioUrl,
    required this.timestamp,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      type: json['type'],
      plantId: json['plant_id'],
      plantNickname: json['plant_nickname'] ?? '',
      message: json['message'],
      audioUrl: json['audio_url'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class HistoryEvent {
  final String eventId;
  final String plantId;
  final String type;
  final String message;
  final DateTime createdAt;

  HistoryEvent({
    required this.eventId,
    required this.plantId,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      eventId: json['event_id'],
      plantId: json['plant_id'],
      type: json['type'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationsHistoryResponse {
  final List<HistoryEvent> events;

  NotificationsHistoryResponse({
    required this.events,
  });

  factory NotificationsHistoryResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsHistoryResponse(
      events: (json['events'] as List)
          .map((e) => HistoryEvent.fromJson(e))
          .toList(),
    );
  }
}

class DeviceTokenCreate {
  final String token;
  final String platform; // 'ios', 'android', 'web'

  DeviceTokenCreate({
    required this.token,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
    };
  }
}
