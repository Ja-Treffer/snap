// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => 'EduSnap';

  @override
  String get homepage_title => '列表';

  @override
  String get detail_title => '详情';

  @override
  String get add_title => '添加';

  @override
  String get edit_title => '编辑';

  @override
  String get settings_title => '设置';

  @override
  String get btn_back => '返回';

  @override
  String get btn_save => '保存';

  @override
  String get btn_update => '更新';

  @override
  String get btn_edit => '编辑';

  @override
  String get btn_cancel => '取消';

  @override
  String get btn_delete => '删除';

  @override
  String get btn_ok => '好';

  @override
  String get btn_settings => '设置';

  @override
  String get btn_add_entry => '新增记录';

  @override
  String get btn_photo_camera => '拍照';

  @override
  String get btn_photo_gallery => '从相册选择';

  @override
  String get btn_photo_remove => '移除照片';

  @override
  String get btn_open_settings => '打开设置';

  @override
  String get homepage_empty => '还没有记录';

  @override
  String get entry_untitled => '无标题';

  @override
  String get entry_no_note => '无备注';

  @override
  String get entry_no_photo => '无照片';

  @override
  String get form_title_label => '标题';

  @override
  String get form_title_hint => '必填';

  @override
  String get form_note_label => '备注';

  @override
  String get form_note_hint => '选填';

  @override
  String get form_photo_label => '照片';

  @override
  String get dialog_empty_title => '没有可保存的内容';

  @override
  String get dialog_empty_body => '先写个标题或备注吧。';

  @override
  String get dialog_delete_title => '删除这条记录？';

  @override
  String dialog_delete_body(String title) {
    return '「$title」将从列表移除。';
  }

  @override
  String get dialog_permission_title => '需要权限';

  @override
  String get dialog_permission_body => '请在系统设置中允许相机与相册权限，才能添加照片。';

  @override
  String get dialog_photo_failed => '打不开相机或相册。';

  @override
  String entry_created_on(String date) {
    return '$date 建立';
  }

  @override
  String get settings_language => '语言';

  @override
  String get settings_language_system => '跟随系统';

  @override
  String get settings_storage => '本地存储';

  @override
  String settings_storage_used(String size) {
    return '已使用 $size';
  }

  @override
  String get settings_clear => '清空所有记录';

  @override
  String get settings_clear_title => '清空全部？';

  @override
  String settings_clear_body(int count) {
    return '将删除 $count 条记录及全部照片。';
  }

  @override
  String get settings_clear_again_title => '确定要清空吗？';

  @override
  String get settings_clear_again_body => '此操作无法撤销。';

  @override
  String get settings_cleared => '已清空';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get app_title => 'EduSnap';

  @override
  String get homepage_title => '清單';

  @override
  String get detail_title => '詳情';

  @override
  String get add_title => '新增';

  @override
  String get edit_title => '編輯';

  @override
  String get settings_title => '設定';

  @override
  String get btn_back => '返回';

  @override
  String get btn_save => '儲存';

  @override
  String get btn_update => '更新';

  @override
  String get btn_edit => '編輯';

  @override
  String get btn_cancel => '取消';

  @override
  String get btn_delete => '刪除';

  @override
  String get btn_ok => '好';

  @override
  String get btn_settings => '設定';

  @override
  String get btn_add_entry => '新增紀錄';

  @override
  String get btn_photo_camera => '拍照';

  @override
  String get btn_photo_gallery => '從相簿選擇';

  @override
  String get btn_photo_remove => '移除照片';

  @override
  String get btn_open_settings => '開啟設定';

  @override
  String get homepage_empty => '還沒有紀錄';

  @override
  String get entry_untitled => '無標題';

  @override
  String get entry_no_note => '無備註';

  @override
  String get entry_no_photo => '無照片';

  @override
  String get form_title_label => '標題';

  @override
  String get form_title_hint => '必填';

  @override
  String get form_note_label => '備註';

  @override
  String get form_note_hint => '選填';

  @override
  String get form_photo_label => '照片';

  @override
  String get dialog_empty_title => '沒有可儲存的內容';

  @override
  String get dialog_empty_body => '先寫個標題或備註吧。';

  @override
  String get dialog_delete_title => '刪除這筆紀錄？';

  @override
  String dialog_delete_body(String title) {
    return '「$title」將從清單移除。';
  }

  @override
  String get dialog_permission_title => '需要權限';

  @override
  String get dialog_permission_body => '請在系統設定中允許相機與相簿權限，才能加入照片。';

  @override
  String get dialog_photo_failed => '打不開相機或相簿。';

  @override
  String entry_created_on(String date) {
    return '$date 建立';
  }

  @override
  String get settings_language => '語言';

  @override
  String get settings_language_system => '跟隨系統';

  @override
  String get settings_storage => '本機儲存';

  @override
  String settings_storage_used(String size) {
    return '已使用 $size';
  }

  @override
  String get settings_clear => '清空所有紀錄';

  @override
  String get settings_clear_title => '清空全部？';

  @override
  String settings_clear_body(int count) {
    return '將刪除 $count 筆紀錄及全部照片。';
  }

  @override
  String get settings_clear_again_title => '確定要清空嗎？';

  @override
  String get settings_clear_again_body => '此操作無法復原。';

  @override
  String get settings_cleared => '已清空';
}
