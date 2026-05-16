// Smoke test de arranque de la app.
//
// No depende de auth async, secure-storage ni red: solo verifica que el
// árbol de widgets monta sin excepciones y que el gate inicial de auth
// muestra el indicador de carga.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gossip_garden/main.dart';

void main() {
  testWidgets('App arranca sin excepciones', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
