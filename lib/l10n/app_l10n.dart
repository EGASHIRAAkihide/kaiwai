import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Hand-written localizations delegate for English and Japanese.
///
/// This class is intentionally kept dependency-free (no code generation).
/// Every string is a simple getter — easy to audit, translate, and extend.
///
/// ── How to use ────────────────────────────────────────────────────────────
///   final l10n = AppL10n.of(context);
///   Text(l10n.enterSpot)
///
/// ── Migrating to generated localizations ─────────────────────────────────
/// When the string count grows large, switch to code-generated l10n:
///   1. Add `generate: true` under `flutter:` in pubspec.yaml.
///   2. Run `flutter pub get` to trigger `flutter gen-l10n`.
///   3. Replace `AppL10n.of(context)` → `AppLocalizations.of(context)`.
///   See l10n.yaml at the project root for the generator configuration.
///
/// ── Adding a new locale ───────────────────────────────────────────────────
///   1. Add the Locale to [supportedLocales].
///   2. Add a corresponding case to [_isJa] or introduce a new helper.
///   3. Add the corresponding app_XX.arb file in lib/l10n/.
class AppL10n {
  const AppL10n._(this._locale);

  final Locale _locale;

  bool get _isJa => _locale.languageCode == 'ja';

  // ── Lookup ──────────────────────────────────────────────────────────────

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ??
        const AppL10n._(Locale('en'));
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// All locales supported by the app.
  ///
  /// Must stay in sync with the ARB files in lib/l10n/ and with
  /// [_AppL10nDelegate.isSupported].
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ja'),
  ];

  /// Full set of delegates to pass to [MaterialApp.localizationsDelegates].
  ///
  /// Includes the Flutter-provided delegates for Material, Widgets and
  /// Cupertino components so that built-in widgets (date pickers etc.)
  /// are also localized.
  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  // ── General ─────────────────────────────────────────────────────────────

  String get appTitle => _isJa ? '界隈' : 'KAIWAI';
  String get locating => _isJa ? '位置確認中...' : 'Locating...';
  String get myLocation => _isJa ? '現在地' : 'My location';

  // ── Map screen ──────────────────────────────────────────────────────────

  String spotsNearby(int count) =>
      _isJa ? '$count スポット' : '$count spots nearby';

  String withinDistance(int meters) =>
      _isJa ? '${meters}m 以内' : 'Within ${meters}m';

  String get enterSpot => _isJa ? '界隈に入る' : 'ENTER';
  String get loginRequired => _isJa ? 'ログインが必要です' : 'Login required';
  String get checkInFailed =>
      _isJa ? 'チェックインに失敗しました' : 'Check-in failed';

  // ── Error / status ──────────────────────────────────────────────────────

  String get noSpotsNearby =>
      _isJa ? '近くにスポットがありません。' : 'No spots in this area.';

  String get couldNotLoadSpots =>
      _isJa ? 'スポットを読み込めませんでした。' : 'Could not load spots.';

  String get couldNotGetLocation =>
      _isJa ? '位置情報を取得できませんでした。' : 'Could not get location.';

  String get errorLoadData =>
      _isJa ? 'データの読み込みに失敗しました' : 'Failed to load data';

  // ── Spot detail screen ──────────────────────────────────────────────────

  /// Tab labels are intentionally kept in Japanese — they are brand terms
  /// that define the product vocabulary for all locales.
  String get notesTab => '界隈ノート';
  String get rankingTab => 'ランキング';

  String get loading => _isJa ? '読込中...' : 'LOADING...';
  String get dataLoadFailed => _isJa ? 'データ読み込み失敗' : 'DATA LOAD FAILED';
  String get retry => _isJa ? '再試行' : 'RETRY';

  String get noContentYet =>
      _isJa ? 'まだコンテンツがありません' : 'NO CONTENT YET';

  String get tapToRead => _isJa ? 'タップして読む' : 'TAP TO READ';
  String get noCheckInsYet =>
      _isJa ? 'まだチェックインがありません' : 'NO CHECK-INS YET';

  String get beFirstToEnter => _isJa ? '最初に入ろう' : 'BE THE FIRST';

  String get radiusSuffix => _isJa ? 'M 範囲' : 'M RADIUS';
  String get localTimeLabel => _isJa ? '現地時刻' : 'LOCAL';
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ja'].contains(locale.languageCode);

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n._(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppL10n> old) => false;
}
