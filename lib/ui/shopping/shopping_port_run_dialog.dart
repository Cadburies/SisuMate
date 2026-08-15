import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/bar_ingredient_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../services/error_log_service.dart';
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/location_service.dart';
import '../../services/shopping_port_run.dart';
import '../../services/weather_service.dart';
import '../settings/llm_api_key_dialog.dart';

/// Opens [ShoppingPortRunDialog] for every visible shopping line.
void openShoppingPortRun(BuildContext context, WidgetRef ref) {
  final cats = ref.read(shoppingCategoriesProvider).asData?.value ?? [];
  final items = <ShoppingItem>[];
  for (final c in cats) {
    final catItems = ref
            .read(shoppingItemsByCategoryProvider(c.supabaseId))
            .asData
            ?.value ??
        [];
    items.addAll(catItems.where((it) => !it.isHidden));
  }
  showDialog<void>(
    context: context,
    builder: (_) => ShoppingPortRunDialog(items: items),
  );
}

/// #337 — whole-list port run: offline groups first, optional live shop names.
class ShoppingPortRunDialog extends ConsumerStatefulWidget {
  final List<ShoppingItem> items;
  final LocationService locationService;
  final Future<String?> Function({
    required double lat,
    required double lon,
  })? reverseGeocode;
  final LlmClientService? llm;

  const ShoppingPortRunDialog({
    super.key,
    required this.items,
    this.locationService = const LocationService(),
    this.reverseGeocode,
    this.llm,
  });

  @override
  ConsumerState<ShoppingPortRunDialog> createState() =>
      _ShoppingPortRunDialogState();
}

class _ShoppingPortRunDialogState extends ConsumerState<ShoppingPortRunDialog> {
  late final TextEditingController _portCtrl;
  late final LlmClientService _llm = widget.llm ?? LlmClientService();
  late PortRunSheet _sheet;
  LlmResult? _llmResult;
  bool _loading = false;
  bool _applying = false;
  String? _notice;
  String? _proseFallback;

  @override
  void initState() {
    super.initState();
    _portCtrl = TextEditingController();
    _sheet = _rebuildOffline();
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    super.dispose();
  }

  PortRunSheet _rebuildOffline({String? coarse}) {
    final guests = ref.read(guestProfilesProvider).asData?.value ?? const [];
    final pantry =
        ref.read(pantryIngredientsProvider).asData?.value ?? const [];
    final bar = ref.read(barIngredientsProvider).asData?.value ?? const [];
    return ShoppingPortRun.planOffline(
      items: widget.items,
      guests: guests,
      pantry: pantry,
      bar: bar,
      coarseLocation: coarse ?? _portCtrl.text,
    );
  }

  bool _hasActiveKey(Boat? boat) {
    final key = boat?.activeLlmApiKeyEntry?.apiKey.trim();
    return key != null && key.isNotEmpty;
  }

  Future<void> _routeToAiKeys() async {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      Navigator.of(context).pop();
      router.push(AppRoutes.settingsAiKeys);
      return;
    }
    await showLlmApiKeyDialog(context, ref);
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

  Future<void> _nameShops() async {
    setState(() {
      _loading = true;
      _notice = null;
      _proseFallback = null;
      _llmResult = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    if (!mounted) return;
    if (!_hasActiveKey(boat)) {
      setState(() => _loading = false);
      await _routeToAiKeys();
      return;
    }

    var coarse = _portCtrl.text.trim();
    if (coarse.isEmpty) {
      coarse = (await _coarseFromGps())?.trim() ?? '';
      if (coarse.isNotEmpty && mounted) {
        _portCtrl.text = coarse;
      }
    }
    if (!mounted) return;
    if (coarse.isEmpty) {
      setState(() {
        _loading = false;
        _notice =
            'Type the marina / city above (or turn on location) so we can name real shops.';
      });
      return;
    }

    final guests = ref.read(guestProfilesProvider).asData?.value ?? const [];
    final pending = widget.items
        .where((i) => !i.isHidden && !i.isBought)
        .take(40)
        .toList();
    final result = await _llm.completeWithSearch(
      boat: boat,
      systemPrompt: 'You plan a walking shop run for a yacht charter crew. '
          'Reply with JSON only (no markdown, no citation markers) matching: '
          '{"area":"","stops":[{"shop":"","kind":"supermarket|liquor|chandlery|pharmacy",'
          '"walk":"from the main marina","hours":"","till":"",'
          '"items":[{"name":"exact list name","say":"local till name"}]}],'
          '"skip":[],"allergens":[],"tillTotal":"","tips":[]}. '
          'Use the given weekday. Split the list across 1–3 real named shops. '
          'Prefer one supermarket that covers food, then liquor/chandlery only '
          'if needed. Never invent GPS. If a shop is unsure, say so in tips '
          'instead of fabricating a name. Estimates only, not a live Maps pin.',
      prompt: jsonEncode(LlmPayloadBuilder.shoppingPortRunQuery(
        coarseLocation: coarse,
        weekday: ShoppingPortRun.weekdayName(DateTime.now()),
        items: pending.map((i) => (
              name: i.name,
              origin: i.origin,
              quantity: i.quantity,
              unit: i.unit,
              lastPurchasePrice: i.lastPurchasePrice,
              lastPurchasePlace: i.lastPurchasePlace,
            )),
        guests: guests.map((g) => (
              firstName: g.name.trim().split(RegExp(r'\s+')).firstOrNull ??
                  'Guest',
              allergens: g.allergenRestrictions,
              diets: g.dietaryRequirements,
            )),
      )),
    );
    if (!mounted) return;

    if (result.status != LlmResultStatus.success) {
      setState(() {
        _llmResult = result;
        _loading = false;
      });
      return;
    }

    final parsed = ShoppingPortRun.tryParseLive(
      result.text ?? '',
      items: widget.items,
    );
    setState(() {
      _loading = false;
      _llmResult = result;
      if (parsed != null) {
        _sheet = parsed;
        _proseFallback = null;
      } else {
        _proseFallback = ShoppingPortRun.cleanProse(result.text ?? '');
      }
    });
  }

  Future<void> _writeShopsOntoList() async {
    if (!_sheet.fromLiveSearch) return;
    setState(() => _applying = true);
    final repo = ref.read(shoppingRepositoryProvider);
    var n = 0;
    try {
      for (final stop in _sheet.stops) {
        for (final line in stop.lines) {
          n += await repo.applyPricePlaceToPendingByName(
            name: line.name,
            place: stop.shopLabel,
          );
        }
      }
    } catch (e, st) {
      // Unexpected I/O — user already sees a snack if we can; still log.
      await ErrorLogService().logException(
        e,
        st,
        context: 'shopping: write port-run shops onto list',
      );
    }
    if (!mounted) return;
    setState(() => _applying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wrote shop names onto $n list line${n == 1 ? '' : 's'}')),
    );
  }

  Future<void> _copyRun() async {
    final buf = StringBuffer()
      ..writeln('Port run — ${_sheet.area}')
      ..writeln(_sheet.tillSummary);
    for (final stop in _sheet.stops) {
      buf.writeln();
      buf.writeln(stop.shopLabel);
      if (stop.walk != null) buf.writeln('  ${stop.walk}');
      if (stop.hours != null) buf.writeln('  ${stop.hours}');
      for (final line in stop.lines) {
        buf.writeln(
          '  • ${line.name} ${line.qtyLabel}'
          '${line.localName == null ? '' : '  (${line.localName})'}',
        );
      }
    }
    for (final n in _sheet.allergenNotes) {
      buf.writeln('⚠ $n');
    }
    for (final n in _sheet.skipNotes) {
      buf.writeln('→ $n');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Port run copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.items.where((i) => !i.isHidden && !i.isBought).length;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.directions_walk,
              color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Port run · $pending to buy',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _portCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marina / city',
                  helperText: 'Used for live shop names. Offline run works without it.',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => setState(() {
                  _sheet = _rebuildOffline(coarse: _portCtrl.text);
                }),
              ),
              const SizedBox(height: 8),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_notice!,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                FilledButton.icon(
                  onPressed: _nameShops,
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Name the shops (live)'),
                ),
              if (_llmResult != null &&
                  _llmResult!.status != LlmResultStatus.success) ...[
                const SizedBox(height: 8),
                Text(
                  _llmResult!.errorMessage ?? 'AI unavailable',
                  style: const TextStyle(height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Text(_sheet.area, style: Theme.of(context).textTheme.titleSmall),
              if (_sheet.tillSummary.isNotEmpty)
                Text(_sheet.tillSummary,
                    style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              if (_proseFallback != null)
                Text(_proseFallback!, style: const TextStyle(height: 1.35))
              else
                for (final stop in _sheet.stops) _StopCard(stop: stop),
              if (_sheet.allergenNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Guest watch',
                    style: Theme.of(context).textTheme.titleSmall),
                for (final n in _sheet.allergenNotes)
                  Text('• $n', style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_sheet.skipNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final n in _sheet.skipNotes)
                  Text('• $n', style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_sheet.tips.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final t in _sheet.tips.take(3))
                  Text(t, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_sheet.fromLiveSearch &&
                  _llmResult?.citations.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                for (final c in _llmResult!.citations)
                  Text(
                    c.title == null || c.title!.isEmpty
                        ? c.url
                        : '${c.title} — ${c.url}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                'Offline groups always work. Live names are estimates — not a '
                'Maps pin or official price list.',
                style: Theme.of(context).textTheme.bodySmall,
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
          onPressed: _copyRun,
          child: const Text('Copy'),
        ),
        if (_sheet.fromLiveSearch)
          TextButton(
            onPressed: _applying ? null : _writeShopsOntoList,
            child: _applying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Write shops onto list'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final PortRunStop stop;
  const _StopCard({required this.stop});

  static String _say(PortRunLine line) {
    final say = line.localName?.trim();
    if (say == null || say.isEmpty) return '';
    if (say.toLowerCase() == line.name.toLowerCase()) return '';
    return ' — $say';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stop.shopLabel,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (stop.walk != null)
              Text(stop.walk!, style: theme.textTheme.bodySmall),
            if (stop.hours != null)
              Text(stop.hours!, style: theme.textTheme.bodySmall),
            if (stop.till != null)
              Text(stop.till!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            for (final line in stop.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${line.name} ${line.qtyLabel}'
                  '${_say(line)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
