import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/location_service.dart';
import '../../services/shopping_item_local_guide.dart';
import '../../services/weather_service.dart';
import '../settings/llm_api_key_dialog.dart';

/// #317 / #334 — per-item shopping helper: offline guide first, optional LLM.
///
/// Prefills from the [ShoppingItem] (never an empty customs form). Customs
/// red-flags are part of the offline pack. Live nearest-shop / price / walk
/// uses grounded search + coarse location only — never raw GPS.
class ShoppingItemAiDialog extends ConsumerStatefulWidget {
  final ShoppingItem item;
  final LocationService locationService;
  final Future<String?> Function({
    required double lat,
    required double lon,
  })? reverseGeocode;
  final LlmClientService? llm;

  const ShoppingItemAiDialog({
    super.key,
    required this.item,
    this.locationService = const LocationService(),
    this.reverseGeocode,
    this.llm,
  });

  @override
  ConsumerState<ShoppingItemAiDialog> createState() =>
      _ShoppingItemAiDialogState();
}

class _ShoppingItemAiDialogState extends ConsumerState<ShoppingItemAiDialog> {
  late final TextEditingController _regionCtrl;
  late final String _offlineReport;
  late final LlmClientService _llm = widget.llm ?? LlmClientService();
  LlmResult? _llmResult;
  bool _llmLoading = false;
  String? _locationNotice;

  @override
  void initState() {
    super.initState();
    _regionCtrl = TextEditingController();
    _offlineReport = ShoppingItemLocalGuide.formatForItem(widget.item);
  }

  @override
  void dispose() {
    _regionCtrl.dispose();
    super.dispose();
  }

  bool _hasActiveKey(Boat? boat) {
    final key = boat?.activeLlmApiKeyEntry?.apiKey.trim();
    return key != null && key.isNotEmpty;
  }

  /// No token → Settings / **AI API Keys** so they can paste a provider key.
  Future<void> _routeToAiKeys() async {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      Navigator.of(context).pop();
      router.push(AppRoutes.settingsAiKeys);
      return;
    }
    // Widget tests (and any tree without GoRouter) open the same dialog
    // Settings uses, with the exact "AI API Keys" copy.
    await showLlmApiKeyDialog(context, ref);
  }

  Future<void> _runImprove() async {
    setState(() {
      _llmLoading = true;
      _llmResult = null;
      _locationNotice = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    if (!mounted) return;
    if (!_hasActiveKey(boat)) {
      setState(() => _llmLoading = false);
      await _routeToAiKeys();
      return;
    }
    final item = widget.item;
    final result = await _llm.complete(
      boat: boat,
      systemPrompt: 'You are a boat provisioning shopping assistant. '
          'Given a shopping-list line and optional region/country, suggest: '
          '(1) local product names and common brand names, '
          '(2) store types (supermarket, market, chandlery, pharmacy…), '
          '(3) a rough relative price band if you know one, '
          '(4) any customs/import cautions for yachts. '
          'Be concise with bullets. Do NOT invent live shop addresses, '
          'GPS distances, or real-time stock. Not official customs advice '
          'and not live Maps results.',
      prompt: jsonEncode(LlmPayloadBuilder.shoppingGuideQuery(
        itemName: item.name,
        origin: item.origin,
        quantity: item.quantity,
        unit: item.unit,
        notes: item.notes,
        region: _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        lastPurchasePrice: item.lastPurchasePrice,
        lastPurchasePlace: item.lastPurchasePlace,
      )),
    );
    if (mounted) {
      setState(() {
        _llmResult = result;
        _llmLoading = false;
      });
    }
  }

  Future<String?> _coarseFromGps() async {
    final loc = await widget.locationService.getCurrentPosition();
    if (!loc.isSuccess) return null;
    final pos = loc.position!;
    final geocode = widget.reverseGeocode ??
        ({required double lat, required double lon}) =>
            WeatherService().reverseGeocode(lat: lat, lon: lon);
    return geocode(lat: pos.latitude, lon: pos.longitude);
  }

  Future<void> _runShopFinder() async {
    setState(() {
      _llmLoading = true;
      _llmResult = null;
      _locationNotice = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    if (!mounted) return;
    if (!_hasActiveKey(boat)) {
      setState(() => _llmLoading = false);
      await _routeToAiKeys();
      return;
    }

    var coarse = _regionCtrl.text.trim();
    if (coarse.isEmpty) {
      coarse = (await _coarseFromGps())?.trim() ?? '';
    }
    if (!mounted) return;
    if (coarse.isEmpty) {
      setState(() {
        _llmLoading = false;
        _locationNotice =
            'Turn on location, or type a city / region above, then try again.';
      });
      return;
    }

    final item = widget.item;
    final result = await _llm.completeWithSearch(
      boat: boat,
      systemPrompt: 'You are a live local shopping assistant for a yacht '
          'or charter crew. Using current web search for the given coarse '
          'area (city/region only — never invent GPS coordinates): '
          '(1) name the closest real store/shop that sells this item, '
          '(2) the typical shelf price there for the stated pack/quantity '
          '(local currency if known), '
          '(3) approximate walking distance and time from a typical '
          'marina or town-center starting point in that area, '
          '(4) one short tip (hours, shuttle, cash-only) if known. '
          'If you cannot find a real named shop, say so and give the '
          'nearest store type plus a typical price band — do not invent '
          'a shop name. Never output raw coordinates. Cite sources. '
          'This is not official pricing and not a live Maps pin.',
      prompt: jsonEncode(LlmPayloadBuilder.shoppingShopFinderQuery(
        itemName: item.name,
        origin: item.origin,
        quantity: item.quantity,
        unit: item.unit,
        notes: item.notes,
        coarseLocation: coarse,
        lastPurchasePrice: item.lastPurchasePrice,
        lastPurchasePlace: item.lastPurchasePlace,
      )),
    );
    if (mounted) {
      setState(() {
        _llmResult = result;
        _llmLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final qty = item.quantity < 1 ? 1 : item.quantity;
    final unit = (item.unit != null && item.unit!.trim().isNotEmpty)
        ? ' ${item.unit!.trim()}'
        : '';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shop: ${item.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '×$qty$unit · origin ${item.origin}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Region / country (optional AI)',
                  helperText:
                      'e.g. Turkey, Martinique — used if GPS is off or denied',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_locationNotice != null) ...[
                Text(
                  _locationNotice!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              if (_llmLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: _runShopFinder,
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Find nearest shop (online)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _runImprove,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Improve with AI (online)'),
                ),
              ],
              if (_llmResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  _llmResult!.status == LlmResultStatus.success
                      ? (_llmResult!.text ?? '')
                      : (_llmResult!.errorMessage ?? 'AI unavailable'),
                  style: const TextStyle(height: 1.35),
                ),
                if (_llmResult!.status == LlmResultStatus.success &&
                    _llmResult!.citations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final c in _llmResult!.citations)
                    Text(
                      c.title == null || c.title!.isEmpty
                          ? c.url
                          : '${c.title} — ${c.url}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ],
              const SizedBox(height: 8),
              Text(
                'Offline guide always works. Find nearest shop needs an AI '
                'API key + internet — estimates only, not official pricing '
                'or a live Maps pin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _offlineReport,
                style: const TextStyle(height: 1.35),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_llmResult?.status == LlmResultStatus.noKeyConfigured ||
            _llmResult?.status == LlmResultStatus.groundedSearchUnsupported)
          TextButton(
            onPressed: _routeToAiKeys,
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
