// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KAIWAI';

  @override
  String get locating => 'Locating...';

  @override
  String get myLocation => 'My location';

  @override
  String spotsNearby(int count) {
    return '$count spots nearby';
  }

  @override
  String withinDistance(int meters) {
    return 'Within ${meters}m';
  }

  @override
  String get enterSpot => 'ENTER';

  @override
  String get loginRequired => 'Login required';

  @override
  String get checkInFailed => 'Check-in failed';

  @override
  String get noSpotsNearby => 'No spots in this area.';

  @override
  String get couldNotLoadSpots => 'Could not load spots.';

  @override
  String get couldNotGetLocation => 'Could not get location.';

  @override
  String get notesTab => '界隈ノート';

  @override
  String get rankingTab => 'ランキング';

  @override
  String get loading => 'LOADING...';

  @override
  String get dataLoadFailed => 'DATA LOAD FAILED';

  @override
  String get retry => 'RETRY';

  @override
  String get noContentYet => 'NO CONTENT YET';

  @override
  String get tapToRead => 'TAP TO READ';

  @override
  String get noCheckInsYet => 'NO CHECK-INS YET';

  @override
  String get radiusSuffix => 'M RADIUS';

  @override
  String get localTimeLabel => 'LOCAL';

  @override
  String get errorLoadData => 'Failed to load data';

  @override
  String get warningPrivate => '/// WARNING /// PRIVATE ///';
}
