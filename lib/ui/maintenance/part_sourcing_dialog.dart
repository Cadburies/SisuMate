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
import '../../services/maintenance_local_explain.dart';
import '../../services/weather_service.dart';

enum _Phase { locating, needsManualLocation, ready }

/// #217 / #208 / #402: compatible-part hints for one maintenance task.
///
/// The offline spec is shown immediately. A coarse city (GPS reverse-geocode
/// or typed) only names where to ask — raw coordinates are never shown and
/// never sent to the LLM. "Improve with AI" is optional.
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
  ConsumerState<PartSourcingDialog> createState() => _PartSourcingDialogState();
}

class _PartSourcingDialogState extends ConsumerState<PartSourcingDialog> {
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();
  final _manualLocationCtrl = TextEditingController();

  _Phase _phase = _Phase.locating;
  String? _locationNotice;
  String? _coarse;
  LlmResult? _llm;
  bool _llmLoading = false;
  late String _local;

  @override
  void initState() {
    super.initState();
    _local = _spec();
    _detectLocation();
  }

  @override
  void dispose() {
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  String get _partDescription => [
    widget.item.title,
    widget.item.description,
  ].where((s) => s != null && s.isNotEmpty).join('. ');

  String _spec() => MaintenanceLocalExplain.partSpec(
    title: widget.item.title,
    description: widget.item.description,
    coarseLocation: _coarse,
  );

  String? get _locationForQuery {
    final known = _coarse?.trim();
    if (known != null && known.isNotEmpty) return known;
    final typed = _manualLocationCtrl.text.trim();
    return typed.isEmpty ? null : typed;
  }

  Future<void> _detectLocation() async {
    final result = await _locationService.getCurrentPosition();
    if (!mounted) return;

    switch (result.failureReason) {
      case LocationFailureReason.serviceDisabled:
        setState(() {
          _phase = _Phase.needsManualLocation;
          _locationNotice =
              'Turn on location services, or enter your city/region below.';
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
        // Never fall back to raw coordinates — an unresolved reverse-geocode
        // is not a coarse location, so the manual path is the only
        // privacy-safe option left.
        if (coarse == null || coarse.isEmpty) {
          setState(() {
            _phase = _Phase.needsManualLocation;
            _locationNotice =
                'Could not resolve your area — enter your city/region below.';
          });
          return;
        }
        _applyLocation(coarse);
    }
  }

  void _applyLocation(String? coarse) {
    setState(() {
      _coarse = coarse;
      _phase = _Phase.ready;
      _local = _spec();
    });
  }

  Future<void> _improve() async {
    setState(() {
      _llmLoading = true;
      _llm = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.partSourcingQuery(
      partDescription: _partDescription,
      coarseLocation: _locationForQuery,
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt:
          'You are a boat maintenance parts-sourcing assistant. '
          'Given a part/maintenance task description and (if provided) a '
          'coarse location, suggest known cross-compatible part numbers, '
          'thread/o-ring/seal specs, and the kind of local supplier likely '
          'to stock something compatible nearby. Be concise. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) {
      setState(() {
        _llmLoading = false;
        _llm = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI: Find a compatible part',
              overflow: TextOverflow.ellipsis,
            ),
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
              _buildLocation(context),
              const SizedBox(height: 12),
              Text(_local),
              if (_llm != null) ...[
                const SizedBox(height: 12),
                _LlmView(result: _llm!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_llm?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: (_phase == _Phase.locating || _llmLoading)
              ? null
              : _improve,
          child: const Text('Improve with AI (online)'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildLocation(BuildContext context) {
    switch (_phase) {
      case _Phase.locating:
        return const LinearProgressIndicator();
      case _Phase.needsManualLocation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_locationNotice != null) ...[
              Text(
                _locationNotice!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _manualLocationCtrl,
              decoration: const InputDecoration(
                labelText: 'Your city / region',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitManualLocation(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _applyLocation(null),
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
      case _Phase.ready:
        return const SizedBox.shrink();
    }
  }

  void _submitManualLocation() {
    final typed = _manualLocationCtrl.text.trim();
    _applyLocation(typed.isEmpty ? null : typed);
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
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
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

class _LlmView extends StatelessWidget {
  final LlmResult result;
  const _LlmView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status == LlmResultStatus.success) {
      return Text(result.text ?? '');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(result.errorMessage ?? 'Something went wrong.')),
      ],
    );
  }
}
