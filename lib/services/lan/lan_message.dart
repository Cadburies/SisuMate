import 'dart:convert';

/// Wire format shared by all LAN services: { channel, type, payload }.
/// channel  — 'game' | 'share'  (routes to the correct service handler)
/// type     — channel-specific event name
/// payload  — arbitrary JSON data for that event
class LanMessage {
  final String channel;
  final String type;
  final Map<String, dynamic> payload;

  const LanMessage({
    required this.channel,
    required this.type,
    required this.payload,
  });

  factory LanMessage.fromJson(Map<String, dynamic> json) => LanMessage(
        channel: json['channel'] as String,
        type: json['type'] as String,
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      );

  String encode() => jsonEncode({
        'channel': channel,
        'type': type,
        'payload': payload,
      });

  static LanMessage decode(String raw) =>
      LanMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
