import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:gossip_garden/core/config/app_config.dart';

void main() {
  group('Backend API Connection', () {
    test('Can connect to the deployed backend and fetch /api/v1/health', () async {
      final backendUrl = AppConfig.deployedBackendUrl;
      final uri = Uri.parse('$backendUrl/api/v1/health');
      
      try {
        final response = await http.get(uri);
        expect(
          response.statusCode, 
          200, 
          reason: 'Failed to connect to backend at $uri. Status code: ${response.statusCode}'
        );
      } catch (e) {
        fail('Exception occurred while connecting to $uri: $e');
      }
    });
  });
}
