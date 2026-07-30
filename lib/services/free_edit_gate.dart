import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';

/// FREE-EDITS: lets a Free user try a handful of completions/edits before
/// locking behind the paywall, as an upgrade teaser (access_tiers.md's
/// "Mark items complete / add notes" row is otherwise a hard Free ❌). Pro is
/// always unlimited. The counter lives in `UserSettings` (local-only — Free
/// never syncs, so this never touches Supabase).
class FreeEditGate {
  const FreeEditGate._();

  static const int freeEditAllowance = 5;

  /// Returns true if the action should proceed: Pro (unlimited), or a Free
  /// try was available and has now been consumed. Returns false once a Free
  /// user has used up [freeEditAllowance] tries — caller should show the
  /// upgrade prompt instead of performing the action.
  static Future<bool> tryConsume(WidgetRef ref) async {
    if (ref.read(isProProvider).value ?? false) return true;

    final settings = await ref.read(userSettingsProvider.future);
    if (settings == null) return false;
    if (settings.freeEditsUsed >= freeEditAllowance) return false;

    settings.freeEditsUsed += 1;
    await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
    ref.invalidate(userSettingsProvider);
    return true;
  }

  /// Free tries left, or null if the user is Pro (unlimited — nothing to show).
  static Future<int?> remaining(WidgetRef ref) async {
    if (ref.read(isProProvider).value ?? false) return null;
    final settings = await ref.read(userSettingsProvider.future);
    final used = settings?.freeEditsUsed ?? 0;
    return (freeEditAllowance - used).clamp(0, freeEditAllowance);
  }
}
