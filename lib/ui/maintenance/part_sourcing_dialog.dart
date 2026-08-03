import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';

enum _Phase { locating, needsManualLocation, querying, done }

/// #217 / #208: "find a compatible replacement part near me" — reached only
/// via the distinct AI badge on a maintenance tile (`maintenance_items_
/// screen.dart`'s `_showAiMenu`), never blended into the item's offline
/// Complete/Hide/Delete actions. Reuses `LocationService` (already extracted
/// from `weather_screen.dart` for GPS-lock, #213) and `WeatherService.
/// reverseGeocode` (already truncates to a short city/region label, #213/
/// WX-adjacent) — never sends the boat's exact GPS coordinates to the LLM,
/// only that coarse label, and falls back to a manually-typed location (same
/// pattern as the weather screen) when permission is denied, the location
/// service is off, or reverse-geocoding itself fails.
class PartSourcingDialog extends ConsumerStatefulWidget {
  final ChecklistItem item;
  final LocationService? locationService;
  final http.Client? geocodeHttpClient;

  const PartSourcingDialog({
    super.key,
    required this.item,
    this.locationService,
    this.geocodeHttpClient,
  });

  @override
  ConsumerState<PartSourcingDialog> createState() =>
      _PartSourcingDialogState();
}

class _PartSourcingDialogState extends ConsumerState<PartSourcingDialog> {
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();
  final _manualLocationCtrl = TextEditingController();

  _Phase _phase = _Phase.locating;
  String? _locationNotice;
  LlmResult? _result;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  String get _partDescription => [widget.item.title, widget.item.description]
      .where((s) => s != null && s.isNotEmpty)
      .join('. ');

  Future<void> _detectLocation() async {
    final result = await _locationService.getCurrentPosition();
    if (!mounted) return;

    switch (result.failureReason) {
      case LocationFailureReason.serviceDisabled:
        setState(() {
          _phase = _Phase.needsManualLocation;
          _locationNotice = 'Turn on location services, or enter your '
              'city/region below.';
        });
        return;
      case LocationFailureReason.permissionDenied:
        setState(() {
          _phase = _Phase.needsManualLocation;
          _locationNotice =
              'Location permission denied — enter your city/region below.';
        });
        return;
      case LocationFailureReason.error:
        setState(() {
          _phase = _Phase.needsManualLocation;
          _locationNotice =
              'Could not get location — enter your city/region below.';
        });
        return;
      case null:
        final pos = result.position!;
        final coarse = await WeatherService().reverseGeocode(
          lat: pos.latitude,
          lon: pos.longitude,
          client: widget.geocodeHttpClient,
        );
        if (!mounted) return;
        // Never fall back to raw coordinates here — if reverse-geocoding
        // itself fails, the location is unresolved, not "coarse", so the
        // manual-entry path is the only privacy-safe option left.
        if (coarse == null || coarse.isEmpty) {
          setState(() {
            _phase = _Phase.needsManualLocation;
            _locationNotice =
                'Could not resolve your area — enter your city/region below.';
          });
          return;
        }
        await _query(coarseLocation: coarse);
    }
  }

  Future<void> _query({String? coarseLocation}) async {
    setState(() => _phase = _Phase.querying);
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.partSourcingQuery(
      partDescription: _partDescription,
      coarseLocation: coarseLocation,
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat maintenance parts-sourcing assistant. '
          'Given a part/maintenance task description and (if provided) a '
          'coarse location, suggest known cross-compatible part numbers, '
          'thread/o-ring/seal specs, and the kind of local supplier likely '
          'to stock something compatible nearby. Be concise. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) {
      setState(() {
        _phase = _Phase.done;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('AI: Find a compatible part',
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DisclaimerBanner(),
              const SizedBox(height: 12),
              _buildBody(context),
            ],
          ),
        ),
      ),
      actions: [
        if (_result?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case _Phase.locating:
      case _Phase.querying:
        return const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        );
      case _Phase.needsManualLocation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_locationNotice != null) ...[
              Text(_locationNotice!,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _manualLocationCtrl,
              decoration: const InputDecoration(
                labelText: 'Your city / region',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => _submitManualLocation(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _query(),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: _submitManualLocation,
                  child: const Text('Search'),
                ),
              ],
            ),
          ],
        );
      case _Phase.done:
        return _ResultView(result: _result!);
    }
  }

  void _submitManualLocation() {
    final typed = _manualLocationCtrl.text.trim();
    _query(coarseLocation: typed.isEmpty ? null : typed);
  }
}

/// Acceptance (#217): must be prominent and unmissable — this is general
/// knowledge, not a live parts catalog or verified stock check.
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI suggestion from general knowledge only — not a live parts '
              'catalog or verified stock check. Confirm thread pitch, '
              'o-ring size, and supplier details before ordering or '
              'installing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final LlmResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status == LlmResultStatus.success) {
      return Text(result.text ?? '');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline,
            size: 18, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(result.errorMessage ?? 'Something went wrong.'),
        ),
      ],
    );
  }
}
