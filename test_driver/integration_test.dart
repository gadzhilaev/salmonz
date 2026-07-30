import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final dir = Directory('docs/screenshots');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final file = File('docs/screenshots/$name.png');
          await file.writeAsBytes(bytes);
          // ignore: avoid_print
          print('Wrote ${file.path} (${bytes.length} bytes)');
          return true;
        },
  );
}
