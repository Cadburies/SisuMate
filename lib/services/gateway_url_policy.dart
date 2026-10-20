/// #436 — which instrument-gateway URLs may carry credentials in cleartext.
///
/// Boat-LAN gateways (DataHub, YDWG, a local Home Assistant) are plain HTTP
/// on a private network. Anything reachable over the internet must use HTTPS
/// before a token or password goes to it, or anyone on the path can read it
/// and feed the app fake positions.
class GatewayUrlPolicy {
  const GatewayUrlPolicy._();

  static final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

  /// Private, loopback, link-local, mDNS (`.local`), `.home.arpa` and
  /// single-label names (resolved by the boat router's DNS).
  static bool isLocalHost(String rawHost) {
    var host = rawHost.trim().toLowerCase();
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    if (host.isEmpty) return false;
    if (host == 'localhost') return true;

    final m = _ipv4.firstMatch(host);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      return a == 10 ||
          a == 127 ||
          (a == 192 && b == 168) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 169 && b == 254);
    }
    if (host.contains(':')) {
      // IPv6: loopback, link-local fe80::/10, unique-local fc00::/7.
      return host == '::1' ||
          RegExp(r'^fe[89ab][0-9a-f]?:').hasMatch(host) ||
          RegExp(r'^f[cd][0-9a-f]{0,2}:').hasMatch(host);
    }
    return host.endsWith('.local') ||
        host.endsWith('.home.arpa') ||
        !host.contains('.');
  }

  /// Trims, drops a trailing `/`, and adds a scheme when missing: `http://`
  /// only for a local host, `https://` otherwise.
  static String normalizeBase(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return t;
    while (t.endsWith('/')) {
      t = t.substring(0, t.length - 1);
    }
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final host = Uri.tryParse('http://$t')?.host ?? '';
    return '${isLocalHost(host) ? 'http' : 'https'}://$t';
  }

  /// True for an `http://` URL whose host is not on the local network.
  static bool isCleartextToPublic(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'http' || uri.host.isEmpty) return false;
    return !isLocalHost(uri.host);
  }
}
