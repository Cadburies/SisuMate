import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../providers/shopping_provider.dart';
import '../../services/auth_service.dart';
import '../../services/error_log_service.dart';

/// Owner account flow at Pro upgrade: create an email+password account and the
/// first boat (which crew later join by code), or sign back in on a new device.
class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _boatController = TextEditingController();
  bool _signInMode = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _boatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final boatName = _boatController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (!_signInMode && boatName.isEmpty) {
      setState(() => _error = 'Give your boat a name.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final auth = ref.read(authServiceProvider);
    try {
      if (_signInMode) {
        await auth.signIn(email, password);
      } else {
        await auth.signUp(email, password);
        try {
          await auth.signIn(email, password);
        } catch (_) {
          // Email confirmation is on: account made, but no session yet.
          setState(() {
            _info = 'Account created. Confirm it via the email we sent, then '
                'sign in.';
            _signInMode = true;
          });
          return;
        }
      }

      if (auth.currentUser == null) {
        setState(() => _error = 'Sign-in did not complete. Try again.');
        return;
      }

      if (!_signInMode) {
        await _createOwnedBoat(auth, boatName);
      }

      // Owner is Pro → start sync (also fine for a returning owner).
      await ref.read(syncServiceProvider).ensureStarted();

      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e, st) {
      unawaited(ErrorLogService()
          .logException(e, st, context: 'account_setup_screen: _submit'));
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createOwnedBoat(AuthService auth, String boatName) async {
    // Adopt-and-rename the seeded default boat into a persisted GUID (SHARE-ENROLL).
    final guid = await ref
        .read(boatEnrollmentServiceProvider)
        .enroll(name: boatName, ownerId: auth.currentUser?.id);
    // Push the boat so Supabase DB-generates its shareCode, then stamp ownership.
    final boat = await ref.read(boatRepositoryProvider).getBoatById(guid);
    if (boat != null) {
      await ref.read(boatRepositoryProvider).updateBoat(boat);
      try {
        await auth.claimBoatOwnership(guid);
      } catch (e) {
        // Best-effort; the boat still syncs under permissive RLS.
        unawaited(ErrorLogService().logWarning(
          'claimBoatOwnership failed for $guid: $e',
          context: 'account_setup_screen: _createOwnedBoat',
        ));
      }
    }

    final settings = await ref.read(userSettingsProvider.future);
    if (settings != null) {
      settings.activeBoatSupabaseId = guid;
      await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
    }
    ref.invalidate(userSettingsProvider);
    ref.invalidate(activeBoatProvider);
    ref.invalidate(boatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signInMode ? 'Sign In' : 'Create Boat Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.sailing, size: 64, color: SisuColors.proOnline),
              const SizedBox(height: 16),
              Text(
                _signInMode
                    ? 'Sign in to your boat account'
                    : 'Create your boat account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _signInMode
                    ? 'Use the email and password you set up.'
                    : 'Tip: use a shared boat email (e.g. the boat’s own '
                        'address) so it’s easy to manage as a crew.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (!_signInMode) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _boatController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Boat name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_boat_outlined),
                  ),
                ),
              ],
              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(
                  _info!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SisuColors.proOnline),
                ),
              ],
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
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_signInMode ? Icons.login : Icons.check),
                label: Text(_signInMode
                    ? 'Sign in'
                    : (_busy ? 'Creating…' : 'Create account')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _signInMode = !_signInMode;
                          _error = null;
                          _info = null;
                        }),
                child: Text(_signInMode
                    ? 'Need an account? Create one'
                    : 'Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
