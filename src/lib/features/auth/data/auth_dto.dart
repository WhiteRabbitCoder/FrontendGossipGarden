class UserRegister {
  final String email;
  final String password;
  final String name;

  UserRegister({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'username': name,
    };
  }
}

class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}

class GoogleUrlResponse {
  final String status;
  final String url;

  GoogleUrlResponse({
    required this.status,
    required this.url,
  });

  factory GoogleUrlResponse.fromJson(Map<String, dynamic> json) {
    return GoogleUrlResponse(
      status: json['status'],
      url: json['url'],
    );
  }
}
