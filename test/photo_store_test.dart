import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo_pages/Pages/Add/AddPage.dart';
import 'package:demo_pages/Pages/HomePage/HomePageController.dart';
import 'package:demo_pages/Utils/app_scope.dart';
import 'package:demo_pages/Utils/app_settings.dart';
import 'package:demo_pages/Utils/journal_store.dart';
import 'package:demo_pages/Utils/photo_store.dart';
import 'package:demo_pages/l10n/app_localizations.dart';

/// Returns one fixed file, so the Add page can be driven without a device.
class _FixedPicker extends ImagePicker {
  _FixedPicker(this.source);

  final XFile source;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => this.source;
}

/// Says yes to everything, so the Add page goes straight to the picker.
class _GrantingPermissions extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      PermissionStatus.granted;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async => <Permission, PermissionStatus>{
    for (final Permission permission in permissions)
      permission: PermissionStatus.granted,
  };

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async =>
      ServiceStatus.enabled;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> shouldShowRequestPermissionRationale(
    Permission permission,
  ) async => false;
}

/// File copies and deletes complete on the real event loop. Running the tap
/// itself inside [WidgetTester.runAsync] keeps the handler's awaits on that real
/// loop, so the work is finished by the time the closure returns.
Future<void> _tapAndFlush(WidgetTester tester, String key) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(Key(key)));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

/// A PhotoStore rooted in a throw-away temp directory.
Future<PhotoStore> _tempPhotoStore(Directory dir) async {
  final PhotoStore store = PhotoStore(documentsDirectory: () async => dir);
  await store.ensureReady();
  return store;
}

Future<File> _writeSource(Directory dir, String name) async {
  final File file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(<int>[1, 2, 3, 4]);
  return file;
}

List<String> _names(Directory photos) {
  if (!photos.existsSync()) {
    return <String>[];
  }
  return photos
      .listSync()
      .whereType<File>()
      .map((File f) => f.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PermissionHandlerPlatform.instance = _GrantingPermissions();
  });

  test('AC-S3-13 deleteUnreferenced removes photos no entry points at', () async {
    final Directory root = await Directory.systemTemp.createTemp('photo-gc');
    addTearDown(() async { try { await root.delete(recursive: true); } catch (_) {} });

    final PhotoStore photos = await _tempPhotoStore(root);
    final Directory folder = Directory(
      '${root.path}${Platform.pathSeparator}${PhotoStore.folderName}',
    );

    final File source = await _writeSource(root, 'src.jpg');
    final String keep = (await photos.import(source.path))!;
    final String drop = (await photos.import(source.path))!;

    expect(_names(folder), hasLength(2));
    expect(await photos.usedBytes(), 8);

    final int removed = await photos.deleteUnreferenced(<String>{keep});

    expect(removed, 1);
    expect(_names(folder), <String>[keep]);
    expect(await photos.usedBytes(), 4);
    expect(drop, isNot(keep));
  });

  test('AC-S3-14 purgeOrphanPhotos removes the copy of an abandoned pick', () async {
    final Directory root = await Directory.systemTemp.createTemp('photo-abandon');
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    });

    final PhotoStore photos = await _tempPhotoStore(root);
    final Directory folder = Directory(
      '${root.path}${Platform.pathSeparator}${PhotoStore.folderName}',
    );
    final File source = await _writeSource(root, 'pick.jpg');

    // Simulates "picked an image, then left the form": the copy is on disk but
    // no entry points at it.
    final String abandoned = (await photos.import(source.path))!;
    expect(_names(folder), <String>[abandoned]);

    final HomePageController controller = HomePageController(
      store: JournalStore.inMemory(),
      photos: photos,
      loadDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    final int removed = await controller.purgeOrphanPhotos();

    expect(removed, 1);
    expect(_names(folder), isEmpty);
  });

  testWidgets('AC-S3-15 removing the photo deletes its file immediately', (
    WidgetTester tester,
  ) async {
    final Directory root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('photo-remove'),
    ) as Directory;
    addTearDown(() async { try { await root.delete(recursive: true); } catch (_) {} });

    final PhotoStore photos = (await tester.runAsync(
      () => _tempPhotoStore(root),
    ))!;
    final File source = (await tester.runAsync(
      () => _writeSource(root, 'pick.jpg'),
    ))!;
    final Directory folder = Directory(
      '${root.path}${Platform.pathSeparator}${PhotoStore.folderName}',
    );

    await tester.pumpWidget(
      AppScope(
        settings: AppSettings(),
        photos: photos,
        journal: JournalStore.inMemory(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddPage(imagePicker: _FixedPicker(XFile(source.path))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapAndFlush(tester, 'pickFromGallery');
    expect(_names(folder), hasLength(1));

    await _tapAndFlush(tester, 'removePhoto');

    expect(find.byKey(const Key('addPhotoPlaceholder')), findsOneWidget);
    expect(_names(folder), isEmpty);
  });
}


