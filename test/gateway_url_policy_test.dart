import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/gateway_url_policy.dart';

/// #436: credentials and tokens must never go over cleartext HTTP to a
/// public host; boat-LAN gateways may stay on plain HTTP.
void main() {
  group('isLocalHost', () {
    test('private, loopback, link-local and mDNS hosts are local', () {
      for (final h in [
        'localhost', '127.0.0.1', '10.0.0.5', '192.168.10.31', '172.16.0.1',
        '172.31.255.254', '169.254.10.1', 'homeassistant.local',
        'homeassistant', 'router.home.arpa', '::1', 'fe80::1', 'fd12::3',
      ]) {
        expect(GatewayUrlPolicy.isLocalHost(h), isTrue, reason: h);
      }
    });

    test('public addresses and names are not local', () {
      for (final h in [
        '8.8.8.8', '172.32.0.1', '172.15.0.1', 'remote.rdsensing.com',
        'abc.ui.nabu.casa', '2001:4860::8888', '',
      ]) {
        expect(GatewayUrlPolicy.isLocalHost(h), isFalse, reason: h);
      }
    });
  });

  group('normalizeBase', () {
    test('bare LAN host gets http, bare public host gets https', () {
      expect(GatewayUrlPolicy.normalizeBase('192.168.1.20:8123'),
          'http://192.168.1.20:8123');
      expect(GatewayUrlPolicy.normalizeBase('homeassistant.local:8123'),
          'http://homeassistant.local:8123');
      expect(GatewayUrlPolicy.normalizeBase('abc.ui.nabu.casa'),
          'https://abc.ui.nabu.casa');
      expect(GatewayUrlPolicy.normalizeBase('203.0.113.7:8123'),
          'https://203.0.113.7:8123');
    });

    test('explicit scheme is kept, trailing slash trimmed', () {
      expect(GatewayUrlPolicy.normalizeBase(' http://example.com/ '),
          'http://example.com');
      expect(GatewayUrlPolicy.normalizeBase('https://10.0.0.2/'),
          'https://10.0.0.2');
      expect(GatewayUrlPolicy.normalizeBase(''), '');
    });
  });

  test('isCleartextToPublic', () {
    expect(GatewayUrlPolicy.isCleartextToPublic('http://example.com'), isTrue);
    expect(GatewayUrlPolicy.isCleartextToPublic('http://remote.rdsensing.com:36121'),
        isTrue);
    expect(GatewayUrlPolicy.isCleartextToPublic('http://192.168.1.2'), isFalse);
    expect(GatewayUrlPolicy.isCleartextToPublic('https://example.com'), isFalse);
    expect(GatewayUrlPolicy.isCleartextToPublic('not a url'), isFalse);
  });
}
