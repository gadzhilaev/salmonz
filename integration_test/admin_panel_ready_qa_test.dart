import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Admin UI removed from Flutter; use admin-web on :3001.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('skipped: Flutter admin removed in favor of admin-web', (tester) async {
    // intentionally empty
  }, skip: true);
}
