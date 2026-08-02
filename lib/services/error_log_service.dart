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

  /// Set once from `main.dart` — the registered [ProviderBreadcrumbs]
  /// observer's recent events, oldest first. Only consulted for
  /// `exception`-level entries (see `_log`).
  static List<String> Function()? providerBreadcrumbsProvider;

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
  ///
  /// Must render via [FlutterErrorDetails.toString] (→
  /// `toDiagnosticsNode().toStringDeep()`), NOT hand-reconstruct from
  /// `exceptionAsString()` + raw `informationCollector()` nodes. The
  /// offending widget's `file:line:col` (from `--track-widget-creation`) for
  /// a `RenderFlex` overflow is injected by
  /// `debugTransformDebugCreator`/`_describeRelevantUserCode`
  /// (`widget_inspector.dart`) as a `FlutterErrorDetails.propertiesTransformer`
  /// — that transform only runs when something calls through
  /// `toDiagnosticsNode()` (which is what `FlutterError.dumpErrorToConsole`
  /// does), never when `informationCollector()` is called and `.toString()`n
  /// is taken directly on its raw nodes. Calling `informationCollector()`
  /// directly (the previous approach here) silently produced only the
  /// truncated `debugCreator: Row ← Column ← …` ownership-chain text with no
  /// location at all — confirmed against the Flutter SDK source
  /// (`foundation/assertions.dart` `_FlutterErrorDetailsNode.builder`) after
  /// #159/#160/#161 shipped with `sourceFile: null` despite this exact
  /// append already being in place (the fix for #138 addressed a different,
  /// narrower gap and didn't catch this one).
  Future<void> logFlutterError(FlutterErrorDetails details) {
    return _log(
      level: 'exception',
      rawMessage: details.toString(),
      stack: details.stack,
      context: details.library == null
          ? details.context?.toString()
          : '${details.library}${details.context == null ? '' : ' — ${details.context}'}',
    );
  }

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
        ..occurrences = 1
        ..debugBreadcrumbs = level == 'exception' ? _safeBreadcrumbs() : null;
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

  String? _safeBreadcrumbs() {
    try {
      final events = providerBreadcrumbsProvider?.call();
      if (events == null || events.isEmpty) return null;
      return _redactSecrets(events.join('\n'));
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

  /// `--track-widget-creation` locations (as opposed to real stack-trace
  /// frames, which always use `package:` URIs) are embedded by the compiler
  /// as the absolute on-disk path of whoever built the debug APK —
  /// `file:///Users/.../SisuMate/lib/ui/.../foo.dart:LINE:COL` — not a
  /// `package:` URI. `_appFrame` alone never matches that, so the "relevant
  /// error-causing widget" line `logFlutterError` now surfaces (via
  /// `details.toString()`) still fell through to `sourceFile: null` even
  /// after that fix. Match it and normalize `lib/` hits to the same
  /// `package:sisu_mate/` shape used elsewhere so `sourceFile`/Touches stay
  /// portable across machines; `test/` hits (only ever seen under `flutter
  /// test`, never in a shipped app) are kept as a plain repo-relative path.
  static final _appFrameFileUri = RegExp(
      r'file:///\S*?/(lib|test)/([A-Za-z0-9_/\.]+\.dart):(\d+):(\d+)');

  String? _extractSourceFile(String? stackText, String message) {
    for (final text in [stackText, message]) {
      if (text == null) continue;
      final pkg = _appFrame.firstMatch(text);
      if (pkg != null) return pkg.group(0);
      final fileUri = _appFrameFileUri.firstMatch(text);
      if (fileUri != null) {
        final root = fileUri.group(1)!;
        final rest = fileUri.group(2)!;
        final line = fileUri.group(3)!;
        final col = fileUri.group(4)!;
        return root == 'lib'
            ? 'package:sisu_mate/$rest:$line:$col'
            : '$root/$rest:$line:$col';
      }
    }
    return null;
  }

  /// Digits vary run-to-run for the same underlying bug (a pixel-overflow
  /// amount, an id, a byte count) — normalize them out so those still dedupe
  /// to one fingerprint instead of spamming a new row per exact value.
  static final _digits = RegExp(r'\d+(\.\d+)?');

  /// Flutter's `Element`/`State`/`RenderObject` `toString()` appends a
  /// short, non-deterministic hashCode suffix per instance, e.g.
  /// `CocktailBatchScreenState#2aca9` — mixed alphanumeric, so `_digits`
  /// alone doesn't normalize it, and two occurrences of the exact same bug
  /// (same widget, same crash) fingerprint differently and dedupe fails
  /// (found live: #139 was a straight duplicate of #140 because of this).
  /// Must run before `_digits` — normalize the whole `#hex` token first.
  static final _widgetHashSuffix = RegExp(r'#[0-9a-fA-F]{3,8}\b');

  String _fingerprint({
    required String level,
    required String? sourceFile,
    required String message,
  }) {
    final normalizedMessage = message
        .replaceAll(_widgetHashSuffix, '#')
        .replaceAll(_digits, '#');
    final basis = '$level|${sourceFile ?? ''}|$normalizedMessage';
    // FNV-1a is a plain 64-bit int, which on native platforms Dart treats as
    // *signed* — `int.toUnsigned(64)` is a no-op here (64 is already the
    // type's full native width, so there's no wider representation to
    // reinterpret from), so `toRadixString` still prints a leading '-' when
    // the top bit is set. That broke a GitHub search query built from
    // "Fingerprint: <hash>" (found live: #138's idempotency check). Split
    // into two 32-bit halves instead — each masked half is always < 2^32,
    // so it's never negative regardless of the original sign.
    final raw = _fnv1a64(basis);
    final hi = (raw >> 32) & 0xFFFFFFFF;
    final lo = raw & 0xFFFFFFFF;
    return hi.toRadixString(16).padLeft(8, '0') +
        lo.toRadixString(16).padLeft(8, '0');
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
