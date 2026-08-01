import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/drift/app_database.dart';
import '../data/repositories/error_log_repository_impl.dart';
import '../domain/repositories/error_log_repository.dart';
import '../models/models.dart';
import 'revenuecat_service.dart';

/// App-wide error/exception/warning telemetry (#121).
///
/// Singleton so dedupe state (in-memory fingerprint → row id, this run only —
/// see [_seenThisRun]) is shared across every call site, including
/// [main.dart]'s `FlutterError.onError` / `PlatformDispatcher.onError` hooks,
/// which have no `BuildContext`/`WidgetRef` to reach a provider through.
/// Never lets a logging failure throw further — a broken logger must not
/// mask or replace the original error.
class ErrorLogService {
  ErrorLogService._({required ErrorLogRepository repository})
      : _repo = repository {
    // Platform is cheap/synchronous — safe at construction, which can
    // happen as early as the very first frame (e.g. a RenderFlex overflow
    // during initial layout). App version + Pro status are deferred (see
    // [initDeferredContext]) — RevenueCatService.isPro() triggers its own
    // init() internally, and doing that this early would reintroduce the
    // RT1 first-paint jank main.dart's _initDeferredSdks() exists to avoid.
    if (!kIsWeb) {
      _platform = Platform.operatingSystem;
    }
  }

  static ErrorLogService _instance = ErrorLogService._(
    repository: ErrorLogRepositoryImpl(AppDatabase.instance),
  );
  factory ErrorLogService() => _instance;

  final ErrorLogRepository _repo;

  /// Test-only seam — mirrors [AppDatabase.setInstanceForTesting].
  @visibleForTesting
  static void setInstanceForTesting(ErrorLogRepository repository) {
    _instance = ErrorLogService._(repository: repository);
  }

  @visibleForTesting
  static void resetInstanceForTests() {
    _instance = ErrorLogService._(
      repository: ErrorLogRepositoryImpl(AppDatabase.instance),
    );
  }

  /// Set once from `main.dart` (has `appRouter`, which this service must not
  /// import — that would pull the whole router into every call site).
  static String? Function()? routeHintProvider;

  // ── Best-effort context (app version / Pro / platform) ───────────────────

  String _appVersion = '';
  bool _isPro = false;
  String _platform = '';
  bool _deferredContextStarted = false;

  /// Call once, after first frame (RT1) — matches main.dart's
  /// `_initDeferredSdks()` timing. Safe to call more than once (no-ops after
  /// the first). Best-effort: errors logged before this runs, or before it
  /// resolves, just carry blank appVersion / isPro=false.
  void initDeferredContext() {
    if (_deferredContextStarted) return;
    _deferredContextStarted = true;
    unawaited(PackageInfo.fromPlatform().then((info) {
      _appVersion = info.version;
    }).catchError((_) {}));
    unawaited(RevenueCatService().isPro().then((pro) {
      _isPro = pro;
    }).catchError((_) {}));
    RevenueCatService().onCustomerInfoUpdated.listen((_) {
      unawaited(RevenueCatService().isPro().then((pro) {
        _isPro = pro;
      }).catchError((_) {}));
    });
  }

  // ── In-memory dedupe (this run only, per #121's "within a run") ──────────

  final Map<String, int> _seenThisRun = {};

  // ── Public API ─────────────────────────────────────────────────────────

  Future<void> logWarning(String message, {String? context}) =>
      _log(level: 'warning', rawMessage: message, context: context);

  Future<void> logError(String message,
          {StackTrace? stack, String? context}) =>
      _log(level: 'error', rawMessage: message, stack: stack, context: context);

  Future<void> logException(Object error, StackTrace? stack,
          {String? context}) =>
      _log(
        level: 'exception',
        rawMessage: error.toString(),
        stack: stack,
        context: context,
      );

  /// For `FlutterError.onError`. Always call the previous handler too (this
  /// only adds capture, it must not silence the normal debug red-screen).
  Future<void> logFlutterError(FlutterErrorDetails details) => _log(
        level: 'exception',
        rawMessage: details.exceptionAsString(),
        stack: details.stack,
        context: details.library == null
            ? details.context?.toString()
            : '${details.library}${details.context == null ? '' : ' — ${details.context}'}',
      );

  // ── Internals ──────────────────────────────────────────────────────────

  Future<void> _log({
    required String level,
    required String rawMessage,
    StackTrace? stack,
    String? context,
  }) async {
    try {
      final message = _redactSecrets(
        context == null ? rawMessage : '$context: $rawMessage',
      );
      final stackText =
          stack == null ? null : _redactSecrets(stack.toString());
      final sourceFile = _extractSourceFile(stackText, message);
      final fingerprint =
          _fingerprint(level: level, sourceFile: sourceFile, message: message);

      final existingId = _seenThisRun[fingerprint];
      if (existingId != null) {
        await _repo.incrementOccurrences(existingId);
        return;
      }

      final entry = ErrorLogEntry()
        ..level = level
        ..message = message
        ..stackTrace = stackText
        ..sourceFile = sourceFile
        ..routeHint = _safeRouteHint()
        ..appVersion = _appVersion
        ..platform = _platform
        ..isPro = _isPro
        ..fingerprint = fingerprint
        ..occurrences = 1;
      final id = await _repo.insert(entry);
      _seenThisRun[fingerprint] = id;
    } catch (e) {
      if (kDebugMode) {
        // A broken logger must never crash the app or mask the original
        // error — print and move on.
        // ignore: avoid_print
        print('ErrorLogService: failed to log ($level): $e');
      }
    }
  }

  String? _safeRouteHint() {
    try {
      return routeHintProvider?.call();
    } catch (_) {
      return null;
    }
  }

  /// First `package:sisu_mate/...dart:LINE:COL` frame in the stack, or (for
  /// framework-only stacks like a `RenderFlex` overflow, which never reach
  /// app code) the same pattern scanned out of the formatted message/details
  /// text, where `--track-widget-creation` attaches the offending widget's
  /// creation location.
  static final _appFrame =
      RegExp(r'package:sisu_mate/[A-Za-z0-9_/\.]+\.dart:\d+:\d+');

  String? _extractSourceFile(String? stackText, String message) {
    final inStack = stackText == null ? null : _appFrame.firstMatch(stackText);
    if (inStack != null) return inStack.group(0);
    final inMessage = _appFrame.firstMatch(message);
    return inMessage?.group(0);
  }

  /// Digits vary run-to-run for the same underlying bug (a pixel-overflow
  /// amount, an id, a byte count) — normalize them out so those still dedupe
  /// to one fingerprint instead of spamming a new row per exact value.
  static final _digits = RegExp(r'\d+(\.\d+)?');

  String _fingerprint({
    required String level,
    required String? sourceFile,
    required String message,
  }) {
    final normalizedMessage = message.replaceAll(_digits, '#');
    final basis = '$level|${sourceFile ?? ''}|$normalizedMessage';
    return _fnv1a64(basis).toRadixString(16).padLeft(16, '0');
  }

  /// FNV-1a 64-bit — deterministic, dependency-free (no `package:crypto`),
  /// good enough for local dedupe grouping (not a security hash).
  static int _fnv1a64(String input) {
    const prime = 0x100000001b3;
    var hash = 0xcbf29ce484222325;
    for (final byte in input.codeUnits) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash;
  }

  static final _bearer =
      RegExp(r'Bearer\s+[A-Za-z0-9\-_.]+', caseSensitive: false);
  static final _keyValueSecret = RegExp(
    r'''(["']?(?:Authorization|apikey|api_key|access_token|refresh_token)["']?\s*[:=]\s*)["'][^"']*["']''',
    caseSensitive: false,
  );

  /// SEC3 — never persist auth headers/tokens/Supabase keys in a logged
  /// message or stack.
  static String _redactSecrets(String input) {
    var out = input.replaceAll(_bearer, 'Bearer [redacted]');
    out = out.replaceAllMapped(
        _keyValueSecret, (m) => '${m[1]}"[redacted]"');
    return out;
  }
}
