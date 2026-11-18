import 'package:flutter_test/flutter_test.dart';
import 'package:fitzone_frontend/main.dart';

void main() {
  testWidgets('FitZoneApp se puede construir', (WidgetTester tester) async {
    await tester.pumpWidget(const FitZoneApp());
    // El arranque consulta almacenamiento y servicios de red; basta verificar
    // que el widget raíz se monta sin la antigua prueba del contador.
    expect(find.byType(FitZoneApp), findsOneWidget);
  });
}
