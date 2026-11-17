import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'EduSnap'**
  String get app_title;

  /// No description provided for @homepage_title.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get homepage_title;

  /// No description provided for @detail_title.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail_title;

  /// No description provided for @add_title.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_title;

  /// No description provided for @edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit_title;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @btn_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btn_back;

  /// No description provided for @btn_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btn_save;

  /// No description provided for @btn_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btn_update;

  /// No description provided for @btn_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btn_edit;

  /// No description provided for @btn_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btn_cancel;

  /// No description provided for @btn_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btn_delete;

  /// No description provided for @btn_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btn_ok;

  /// No description provided for @btn_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get btn_settings;

  /// No description provided for @btn_add_entry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get btn_add_entry;

  /// No description provided for @btn_photo_camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get btn_photo_camera;

  /// No description provided for @btn_photo_gallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get btn_photo_gallery;

  /// No description provided for @btn_photo_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get btn_photo_remove;

  /// No description provided for @btn_open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get btn_open_settings;

  /// No description provided for @homepage_empty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get homepage_empty;

  /// No description provided for @entry_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get entry_untitled;

  /// No description provided for @entry_no_note.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get entry_no_note;

  /// No description provided for @entry_no_photo.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get entry_no_photo;

  /// No description provided for @form_title_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get form_title_label;

  /// No description provided for @form_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get form_title_hint;

  /// No description provided for @form_note_label.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get form_note_label;

  /// No description provided for @form_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get form_note_hint;

  /// No description provided for @form_photo_label.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get form_photo_label;

  /// No description provided for @dialog_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save'**
  String get dialog_empty_title;

  /// No description provided for @dialog_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Add a title or a note first.'**
  String get dialog_empty_body;

  /// No description provided for @dialog_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get dialog_delete_title;

  /// No description provided for @dialog_delete_body.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from the list.'**
  String dialog_delete_body(String title);

  /// No description provided for @dialog_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get dialog_permission_title;

  /// No description provided for @dialog_permission_body.
  ///
  /// In en, this message translates to:
  /// **'Allow camera and photos in Settings to attach an image.'**
  String get dialog_permission_body;

  /// No description provided for @dialog_photo_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera or the gallery.'**
  String get dialog_photo_failed;

  /// No description provided for @entry_created_on.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String entry_created_on(String date);

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_language_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_language_system;

  /// No description provided for @settings_storage.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get settings_storage;

  /// No description provided for @settings_storage_used.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String settings_storage_used(String size);

  /// No description provided for @settings_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear all entries'**
  String get settings_clear;

  /// No description provided for @settings_clear_title.
  ///
  /// In en, this message translates to:
  /// **'Clear everything?'**
  String get settings_clear_title;

  /// No description provided for @settings_clear_body.
  ///
  /// In en, this message translates to:
  /// **'This removes {count} entries and all photos.'**
  String settings_clear_body(int count);

  /// No description provided for @settings_clear_again_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get settings_clear_again_title;

  /// No description provided for @settings_clear_again_body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get settings_clear_again_body;

  /// No description provided for @settings_background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get settings_background;

  /// No description provided for @settings_background_none.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get settings_background_none;

  /// No description provided for @settings_background_change.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get settings_background_change;

  /// No description provided for @settings_background_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove background'**
  String get settings_background_remove;

  /// No description provided for @settings_background_opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get settings_background_opacity;

  /// No description provided for @settings_background_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the gallery.'**
  String get settings_background_failed;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String settings_version(String version, String build);

  /// No description provided for @settings_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get settings_cleared;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
