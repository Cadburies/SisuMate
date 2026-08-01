import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../providers/shopping_provider.dart';
import '../../services/join_boat_service.dart';

/// Crew join-a-boat flow: enter the share code the captain gave you. Signs in
/// anonymously, redeems the code (server-side membership), and makes the boat
/// active + synced. No Pro required — you ride on the owner's Pro.
class JoinBoatScreen extends ConsumerStatefulWidget {
  const JoinBoatScreen({super.key});

  @override
  ConsumerState<JoinBoatScreen> createState() => _JoinBoatScreenState();
}

class _JoinBoatScreenState extends ConsumerState<JoinBoatScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the boat code from the captain.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final flow = JoinBoatService(
        auth: ref.read(authServiceProvider),
        boats: ref.read(boatRepositoryProvider),
        settings: ref.read(userSettingsRepositoryProvider),
        enrollment: ref.read(boatEnrollmentServiceProvider),
        sync: ref.read(syncServiceProvider),
      );
      final joined = await flow.join(code);

      ref.invalidate(userSettingsProvider);
      ref.invalidate(activeBoatProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined “${joined.name}”. Syncing…')),
      );
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _error = JoinBoatService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Boat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.groups, size: 64, color: SisuColors.proOnline),
              const SizedBox(height: 16),
              Text(
                'Enter the boat code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the captain for the boat’s share code. Joining links this '
                'device to that boat and syncs its lists — you don’t need Pro.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  hintText: 'e.g. 4F2K9X',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _busy ? null : _join(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _join,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_busy ? 'Joining…' : 'Join boat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercases share-code input as it's typed.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
