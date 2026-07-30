import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import '../../models/models.dart';
import 'lan_engine.dart';
import 'lan_message.dart';

const String _kChannel = 'share';

abstract class _T {
  static const request = 'request'; // client → host: I'm connected, send content
  static const content = 'content'; // host → client: here is the shared payload
}

/// The kind of content carried by a [SharePayload].
enum ShareKind { recipe, crew }

/// A self-contained bundle of shareable content sent over the LAN.
///
/// Serialised entirely from the domain models' own `toJson`/`fromJson`, so the
/// wire format stays in lock-step with how the app persists these records.
/// A recipe payload carries the [Recipe] plus its [RecipeIngredient]s; a crew
/// payload carries a list of [CrewMember]s.
class SharePayload {
  final ShareKind kind;
  final Recipe? recipe;
  final List<RecipeIngredient> ingredients;
  final List<CrewMember> crew;

  const SharePayload._({
    required this.kind,
    this.recipe,
    this.ingredients = const [],
    this.crew = const [],
  });

  factory SharePayload.recipe(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) =>
      SharePayload._(
        kind: ShareKind.recipe,
        recipe: recipe,
        ingredients: ingredients,
      );

  factory SharePayload.crew(List<CrewMember> members) =>
      SharePayload._(kind: ShareKind.crew, crew: members);

  factory SharePayload.fromJson(Map<String, dynamic> json) {
    final kind = ShareKind.values.byName(json['kind'] as String);
    switch (kind) {
      case ShareKind.recipe:
        return SharePayload.recipe(
          Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
          ((json['ingredients'] as List?) ?? const [])
              .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case ShareKind.crew:
        return SharePayload.crew(
          ((json['crew'] as List?) ?? const [])
              .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (recipe != null) 'recipe': recipe!.toJson(),
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'crew': crew.map((c) => c.toJson()).toList(),
      };
}

/// Content-sharing protocol layer on top of [LanEngine].
///
/// Unlike [GameLanService] there is no lobby or ongoing session: a host offers
/// a single [SharePayload], and every client that connects pulls a copy of it.
///
/// HOST flow:
///   1. [hostShare] — starts the mDNS broadcast + WebSocket server and holds
///      the payload to hand out.
///   2. Listen to [recipients] to see each device that pulled the content.
///   3. [endSession] — stops broadcasting.
///
/// CLIENT flow:
///   1. [scanForShares] — begins mDNS discovery; watch [discoveredShares].
///   2. [joinShare] — connects and requests the offered content.
///   3. Listen to [incomingContent] for the [SharePayload]; persist it via the
///      normal repositories (the service never touches the DB/Supabase itself).
class ShareLanService {
  final LanEngine _engine;
  bool _isHost = false;
  SharePayload? _offered;

  final _contentCtrl = StreamController<SharePayload>.broadcast();
  final _recipientCtrl = StreamController<String>.broadcast();

  /// Payloads pushed by a host; a client receives one per successful join.
  Stream<SharePayload> get incomingContent => _contentCtrl.stream;

  /// Host-side: emits the peer-id of each client that pulled the content.
  Stream<String> get recipients => _recipientCtrl.stream;

  /// Mirrors [LanEngine.discoveredServices].
  Stream<List<BonsoirService>> get discoveredShares =>
      _engine.discoveredServices;

  bool get isHost => _isHost;

  ShareLanService(this._engine) {
    _engine.incoming.listen(_dispatch);
  }

  // ── Host ───────────────────────────────────────────────────────────────────

  /// Start offering [payload] under the discoverable name [shareName].
  Future<void> hostShare({
    required String shareName,
    required SharePayload payload,
  }) async {
    _isHost = true;
    _offered = payload;
    await _engine.startHost(shareName);
  }

  // ── Client ─────────────────────────────────────────────────────────────────

  /// Begin scanning for offered content on the local network.
  Future<void> scanForShares() => _engine.startDiscovery();

  /// Connect to [service] and request the content it is offering.
  Future<void> joinShare({required BonsoirService service}) async {
    _isHost = false;
    await _engine.connectToService(service);
    _engine.sendToHost(const LanMessage(
      channel: _kChannel,
      type: _T.request,
      payload: {},
    ));
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> endSession() async {
    _isHost = false;
    _offered = null;
    await _engine.dispose();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _dispatch(({String peerId, LanMessage message}) record) {
    final peerId = record.peerId;
    final msg = record.message;
    if (msg.channel != _kChannel) return;

    switch (msg.type) {
      case _T.request:
        final payload = _offered;
        if (_isHost && payload != null) {
          _engine.sendTo(
            peerId,
            LanMessage(
              channel: _kChannel,
              type: _T.content,
              payload: payload.toJson(),
            ),
          );
          _recipientCtrl.add(peerId);
        }

      case _T.content:
        if (!_isHost) {
          _contentCtrl.add(SharePayload.fromJson(msg.payload));
        }
    }
  }
}
