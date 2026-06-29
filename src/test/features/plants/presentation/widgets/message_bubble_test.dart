import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gossip_garden/features/plants/presentation/widgets/message_bubble.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final transparentPng = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
    return Stream<List<int>>.value(transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MyHttpOverrides();
  });

  Widget createTestWidget(ChatMessage message) {
    return MaterialApp(
      home: Scaffold(
        body: MessageBubble(message: message),
      ),
    );
  }

  group('MessageBubble Tests', () {
    testWidgets('Renders base64 image using Image.memory', (tester) async {
      final validBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      
      final message = ChatMessage(
        id: '1',
        content: 'Mira esto',
        sender: 'user',
        source: 'no-data',
        confidence: 'high',
        timestamp: DateTime.now(),
        imageBase64: validBase64,
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      final memoryImageFinder = find.byType(Image);
      expect(memoryImageFinder, findsOneWidget);
      
      final Image imageWidget = tester.widget(memoryImageFinder);
      expect(imageWidget.image is MemoryImage, isTrue);
    });

    testWidgets('Renders network image using Image.network', (tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Mira esto',
        sender: 'user',
        source: 'no-data',
        confidence: 'high',
        timestamp: DateTime.now(),
        imageUrl: 'https://firebase.local/img.png',
      );

      await tester.pumpWidget(createTestWidget(message));
      // No use pumpAndSettle para imágenes de red falsas que nunca se resuelven visualmente
      await tester.pump();

      final networkImageFinder = find.byType(Image);
      expect(networkImageFinder, findsOneWidget);
      
      final Image imageWidget = tester.widget(networkImageFinder);
      expect(imageWidget.image is NetworkImage, isTrue);
    });

    testWidgets('Handles corrupt base64 gracefully without crashing', (tester) async {
      final message = ChatMessage(
        id: '1',
        content: 'Mira esto',
        sender: 'user',
        source: 'no-data',
        confidence: 'high',
        timestamp: DateTime.now(),
        imageBase64: 'corrupt-string-@@@',
      );

      await tester.pumpWidget(createTestWidget(message));
      await tester.pumpAndSettle();

      // Debe haber renderizado el widget de error (Icono broken_image)
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });
  });
}
