import 'package:chess/core/credits/credits.dart';
import 'package:chess/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every declared license file is bundled and not empty', () async {
    final assets = credits.map((c) => c.licenseAsset).nonNulls.toList();
    expect(assets, isNotEmpty);
    for (final asset in assets) {
      final text = await rootBundle.loadString(asset);
      expect(text.trim(), isNotEmpty, reason: asset);
    }
  });

  test('the classic piece set ships its BSD notice', () {
    final classic = credits.singleWhere((c) => c.title == 'Bộ quân Cổ điển');
    expect(classic.license, 'BSD');
    expect(classic.licenseAsset, isNotNull);
  });

  test('asset licenses are registered under the credit title', () async {
    final entries = await assetLicenses().toList();
    expect(entries, hasLength(1));
    expect(entries.single.packages, ['Bộ quân Cổ điển']);
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Colin M.L. Burnett'));
    expect(text, contains('Redistributions in binary form'));
  });
}
