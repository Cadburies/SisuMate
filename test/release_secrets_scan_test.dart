import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SEC3 — always-on source/asset guards (no APK required).
/// Complements `scripts/scan_release_secrets.sh` for archive scanning.
void main() {
  final root = Directory.current.path;

  String read(String rel) => File('$root/$rel').readAsStringSync();

  test('pubspec does not package secrets/ or Play SA JSON as Flutter assets',
      () {
    final pub = read('pubspec.yaml');
    // Assets section must not list secrets paths.
    final assetsBlock = RegExp(
      r'assets:\s*\n((?:[ \t]+-[ \t]+.+\n)*)',
      multiLine: true,
    ).allMatches(pub);
    for (final m in assetsBlock) {
      final block = m.group(1) ?? '';
      expect(block, isNot(contains('secrets/')),
          reason: 'never ship secrets/ inside the APK');
      expect(block.toLowerCase(), isNot(contains('service-account')),
          reason: 'Play SA JSON must not be a Flutter asset');
    }
  });

  test('secrets/ is gitignored (except README)', () {
    final gi = read('.gitignore');
    expect(gi, contains('secrets/**'));
    expect(gi, contains('!secrets/README.md'));
    expect(gi, contains('dart-defines.json'));
  });

  test('lib/ does not hardcode service_role or Play SA asset paths', () {
    final lib = Directory('$root/lib');
    final offenders = <String>[];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      if (text.contains('service_role') ||
          text.contains('assets/service-account') ||
          text.contains('google-play-service-account')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });

  test('assets/ tree has no private-key PEM or service_account JSON type', () {
    final assets = Directory('$root/assets');
    if (!assets.existsSync()) return;
    final offenders = <String>[];
    for (final f in assets.listSync(recursive: true).whereType<File>()) {
      // Skip large binary-ish by extension
      final name = f.path.toLowerCase();
      if (name.endsWith('.jpg') ||
          name.endsWith('.png') ||
          name.endsWith('.webp') ||
          name.endsWith('.ttf')) {
        continue;
      }
      String text;
      try {
        text = f.readAsStringSync();
      } catch (_) {
        continue;
      }
      if (text.contains('BEGIN PRIVATE KEY') ||
          text.contains('BEGIN RSA PRIVATE KEY') ||
          text.contains('"type": "service_account"') ||
          text.contains('"type":"service_account"')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });
}
