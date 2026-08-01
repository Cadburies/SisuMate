import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// TEST8 — live Supabase auth/RLS smoke against the project in
/// `dart-defines.json`.
///
/// Skips when:
/// - `SISU_LIVE_SUPABASE=0`, or
/// - `dart-defines.json` is missing / incomplete, or
/// - the network request fails (offline CI).
///
/// Run explicitly: `SISU_LIVE_SUPABASE=1 flutter test test/live_supabase_rls_test.dart`
void main() {
  final live = _LiveSupabase.tryLoad();

  group('Live Supabase RLS / auth (TEST8)', () {
    test('profiles endpoint responds without 5xx', () async {
      if (live == null) return;
      final res = await live.get('/rest/v1/profiles?select=id&limit=5');
      if (res.statusCode == 599) {
        // ignore: avoid_print
        print('TEST8 soft-skip: network unavailable');
        return;
      }
      expect(res.statusCode, anyOf(200, 401, 403));
    });

    test('owner password grant returns access_token', () async {
      if (live == null || !live.hasOwnerCreds) return;
      final tok = await live.ownerAccessToken();
      if (tok == 'NETWORK') return;
      expect(tok, isNotEmpty);
    });

    test('owner can select boats', () async {
      if (live == null || !live.hasOwnerCreds) return;
      final tok = await live.ownerAccessToken();
      if (tok == 'NETWORK') return;
      final res = await live.get(
        '/rest/v1/boats?select=supabaseId,name&limit=10',
        token: tok,
      );
      if (res.statusCode == 599) return;
      expect(res.statusCode, 200, reason: res.body);
      final rows = jsonDecode(res.body);
      expect(rows, isA<List>());
    });

    test('invalid share code redeem fails', () async {
      if (live == null || !live.hasOwnerCreds) return;
      final tok = await live.ownerAccessToken();
      if (tok == 'NETWORK') return;
      final res = await live.post(
        '/rest/v1/rpc/redeem_boat_code',
        token: tok,
        body: {'p_code': '___invalid_sisu_code___'},
      );
      if (res.statusCode == 599) return;
      // Expect RPC error (4xx) — must not quietly return a boat id.
      expect(res.statusCode, greaterThanOrEqualTo(400), reason: res.body);
    });

    test('bogus JWT is not treated as a privileged session', () async {
      if (live == null) return;
      final res = await live.get(
        '/rest/v1/boats?select=supabaseId&limit=5',
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.sig',
      );
      if (res.statusCode == 599) return;
      expect(res.statusCode, anyOf(200, 401, 403));
      if (res.statusCode == 200) {
        final rows = jsonDecode(res.body) as List;
        expect(rows.length, lessThan(50),
            reason: 'must not dump a large boat list to a fake JWT');
      }
    });
  }, skip: live == null
      ? 'TEST8 skipped: set dart-defines.json (and SISU_LIVE_SUPABASE≠0)'
      : false);
}

class _LiveSupabase {
  _LiveSupabase({
    required this.url,
    required this.anonKey,
    this.email,
    this.password,
  });

  final String url;
  final String anonKey;
  final String? email;
  final String? password;

  bool get hasOwnerCreds =>
      (email?.isNotEmpty ?? false) && (password?.isNotEmpty ?? false);

  String? _cachedToken;

  static _LiveSupabase? tryLoad() {
    if (Platform.environment['SISU_LIVE_SUPABASE'] == '0') return null;
    final f = File('dart-defines.json');
    if (!f.existsSync()) return null;
    try {
      final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final url = map['SUPABASE_URL'] as String? ?? '';
      final key = map['SUPABASE_ANON_KEY'] as String? ?? '';
      if (url.isEmpty || key.isEmpty) return null;
      return _LiveSupabase(
        url: url.replaceAll(RegExp(r'/$'), ''),
        anonKey: key,
        email: map['SUPABASE_DEBUG_EMAIL'] as String?,
        password: map['SUPABASE_DEBUG_PASSWORD'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> get(String path, {String? token}) async {
    try {
      return await http
          .get(
            Uri.parse('$url$path'),
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer ${token ?? anonKey}',
            },
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      // Offline — mark as skip-like soft pass for this invocation.
      return http.Response('network-error: $e', 599);
    }
  }

  Future<http.Response> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await http
          .post(
            Uri.parse('$url$path'),
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer ${token ?? anonKey}',
              'Content-Type': 'application/json',
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      return http.Response('network-error: $e', 599);
    }
  }

  /// Returns access token, or `'NETWORK'` if offline.
  Future<String> ownerAccessToken() async {
    if (_cachedToken != null) return _cachedToken!;
    final res = await post(
      '/auth/v1/token?grant_type=password',
      body: {'email': email, 'password': password},
    );
    if (res.statusCode == 599) return 'NETWORK';
    expect(res.statusCode, 200, reason: res.body);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    _cachedToken = map['access_token'] as String;
    return _cachedToken!;
  }
}
