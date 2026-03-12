// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '界隈';

  @override
  String get locating => '位置確認中...';

  @override
  String get myLocation => '現在地';

  @override
  String spotsNearby(int count) {
    return '$count スポット';
  }

  @override
  String withinDistance(int meters) {
    return '${meters}m 以内';
  }

  @override
  String get enterSpot => '界隈に入る';

  @override
  String get loginRequired => 'ログインが必要です';

  @override
  String get checkInFailed => 'チェックインに失敗しました';

  @override
  String get noSpotsNearby => '近くにスポットがありません。';

  @override
  String get couldNotLoadSpots => 'スポットを読み込めませんでした。';

  @override
  String get couldNotGetLocation => '位置情報を取得できませんでした。';

  @override
  String get notesTab => '界隈ノート';

  @override
  String get rankingTab => 'ランキング';

  @override
  String get loading => '読込中...';

  @override
  String get dataLoadFailed => 'データ読み込み失敗';

  @override
  String get retry => '再試行';

  @override
  String get noContentYet => 'まだコンテンツがありません';

  @override
  String get tapToRead => 'タップして読む';

  @override
  String get noCheckInsYet => 'まだチェックインがありません';

  @override
  String get radiusSuffix => 'M 範囲';

  @override
  String get localTimeLabel => '現地時刻';

  @override
  String get errorLoadData => 'データの読み込みに失敗しました';

  @override
  String get warningPrivate => '/// 立入禁止 /// プライベート ///';
}
