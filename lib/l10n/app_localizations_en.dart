// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'EduSnap';

  @override
  String get homepage_title => 'List';

  @override
  String get detail_title => 'Detail';

  @override
  String get add_title => 'Add';

  @override
  String get edit_title => 'Edit';

  @override
  String get settings_title => 'Settings';

  @override
  String get btn_back => 'Back';

  @override
  String get btn_save => 'Save';

  @override
  String get btn_update => 'Update';

  @override
  String get btn_edit => 'Edit';

  @override
  String get btn_cancel => 'Cancel';

  @override
  String get btn_delete => 'Delete';

  @override
  String get btn_ok => 'OK';

  @override
  String get btn_settings => 'Settings';

  @override
  String get btn_add_entry => 'Add entry';

  @override
  String get btn_photo_camera => 'Take photo';

  @override
  String get btn_photo_gallery => 'From gallery';

  @override
  String get btn_photo_remove => 'Remove photo';

  @override
  String get btn_open_settings => 'Open settings';

  @override
  String get homepage_empty => 'No entries yet';

  @override
  String get entry_untitled => 'Untitled';

  @override
  String get entry_no_note => 'No note';

  @override
  String get entry_no_photo => 'No photo';

  @override
  String get form_title_label => 'Title';

  @override
  String get form_title_hint => 'Required';

  @override
  String get form_note_label => 'Note';

  @override
  String get form_note_hint => 'Optional';

  @override
  String get form_photo_label => 'Photo';

  @override
  String get dialog_empty_title => 'Nothing to save';

  @override
  String get dialog_empty_body => 'Add a title or a note first.';

  @override
  String get dialog_delete_title => 'Delete this entry?';

  @override
  String dialog_delete_body(String title) {
    return '\"$title\" will be removed from the list.';
  }

  @override
  String get dialog_permission_title => 'Permission needed';

  @override
  String get dialog_permission_body =>
      'Allow camera and photos in Settings to attach an image.';

  @override
  String get dialog_photo_failed => 'Could not open the camera or the gallery.';

  @override
  String entry_created_on(String date) {
    return 'Created on $date';
  }

  @override
  String get settings_language => 'Language';

  @override
  String get settings_language_system => 'System';

  @override
  String get settings_storage => 'Local storage';

  @override
  String settings_storage_used(String size) {
    return '$size used';
  }

  @override
  String get settings_clear => 'Clear all entries';

  @override
  String get settings_clear_title => 'Clear everything?';

  @override
  String settings_clear_body(int count) {
    return 'This removes $count entries and all photos.';
  }

  @override
  String get settings_clear_again_title => 'Are you sure?';

  @override
  String get settings_clear_again_body => 'This cannot be undone.';

  @override
  String get settings_background => 'Background';

  @override
  String get settings_background_none => 'Choose an image';

  @override
  String get settings_background_change => 'Change image';

  @override
  String get settings_background_remove => 'Remove background';

  @override
  String get settings_background_opacity => 'Opacity';

  @override
  String get settings_background_failed => 'Could not open the gallery.';

  @override
  String get settings_about => 'About';

  @override
  String settings_version(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get settings_cleared => 'Cleared';
}
