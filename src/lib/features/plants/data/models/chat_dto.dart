class ChatMessageRequest {
  final String message;
  final String language;
  final String responseFormat;

  ChatMessageRequest({
    required this.message,
    this.language = 'es',
    this.responseFormat = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'language': language,
      'response_format': responseFormat,
    };
  }
}

class ChatMessageResponse {
  final String reply;
  final String plantId;
  final DateTime timestamp;
  final String? audioUrl;

  ChatMessageResponse({
    required this.reply,
    required this.plantId,
    required this.timestamp,
    this.audioUrl,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      reply: json['reply'],
      plantId: json['plant_id'],
      timestamp: DateTime.parse(json['timestamp']),
      audioUrl: json['audio_url'],
    );
  }
}

class ChatHistoryResponse {
  final String plantId;
  final List<ChatMessage> messages;

  ChatHistoryResponse({
    required this.plantId,
    required this.messages,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ChatHistoryResponse(
      plantId: json['plant_id'],
      messages: (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList(),
    );
  }
}

class ChatMessage {
  final String role; // 'user', 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class VoiceOption {
  final String voiceId;
  final String name;
  final String gender;
  final String style;
  final String lang;
  final bool recommended;

  VoiceOption({
    required this.voiceId,
    required this.name,
    required this.gender,
    required this.style,
    required this.lang,
    required this.recommended,
  });

  factory VoiceOption.fromJson(Map<String, dynamic> json) {
    return VoiceOption(
      voiceId: json['voice_id'],
      name: json['name'],
      gender: json['gender'],
      style: json['style'],
      lang: json['lang'],
      recommended: json['recommended'] ?? false,
    );
  }
}

class VoicesResponse {
  final String plantId;
  final String currentVoiceId;
  final List<VoiceOption> options;

  VoicesResponse({
    required this.plantId,
    required this.currentVoiceId,
    required this.options,
  });

  factory VoicesResponse.fromJson(Map<String, dynamic> json) {
    return VoicesResponse(
      plantId: json['plant_id'],
      currentVoiceId: json['current_voice_id'],
      options: (json['options'] as List)
          .map((e) => VoiceOption.fromJson(e))
          .toList(),
    );
  }
}

class SetVoiceRequest {
  final String voiceId;

  SetVoiceRequest({required this.voiceId});

  Map<String, dynamic> toJson() {
    return {'voice_id': voiceId};
  }
}
