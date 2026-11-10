import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 这三条守的是「i18n 的技术债」：
///   1. 三份 ARB 的键集必须完全一致，否则某个语言会静默回落到模板值；
///   2. 占位符必须一致，中文 "{date} 建立" 与英文 "Created on {date}" 的占位符集合相同；
///   3. 模板里的每个键都要在 lib/ 里被真正用掉，禁止留死字符串。
///
/// 加语言、改文案、删控件时，这三条会自动拦住漏改的那一侧。
void main() {
  final Directory arbDir = Directory('lib/l10n');
  final File template = File('${arbDir.path}/app_en.arb');

  Map<String, dynamic> readArb(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) => arb.keys
      .where((String key) => !key.startsWith('@'))
      .toSet();

  Set<String> placeholdersOf(String message) =>
      RegExp(r'\{(\w+)\}').allMatches(message).map((RegExpMatch m) => m.group(1)!).toSet();

  test('every locale declares the same keys as the template', () {
    final Map<String, dynamic> en = readArb(template);
    final Set<String> expected = messageKeys(en);

    final List<File> others = arbDir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.arb') && f.path != template.path)
        .toList();

    expect(others, isNotEmpty, reason: '只找到模板 ARB，检查 lib/l10n 路径');

    for (final File file in others) {
      final Set<String> actual = messageKeys(readArb(file));
      expect(
        actual.difference(expected),
        isEmpty,
        reason: '${file.path} 多出模板里没有的键',
      );
      expect(
        expected.difference(actual),
        isEmpty,
        reason: '${file.path} 缺少这些键（会静默回落成英文）',
      );
    }
  });

  test('placeholders match between template and translations', () {
    final Map<String, dynamic> en = readArb(template);

    for (final File entry in arbDir.listSync().whereType<File>()) {
      if (!entry.path.endsWith('.arb') || entry.path == template.path) {
        continue;
      }
      final Map<String, dynamic> other = readArb(entry);
      for (final String key in messageKeys(en)) {
        final String source = en[key] as String;
        final String target = other[key] as String;
        expect(
          placeholdersOf(target),
          placeholdersOf(source),
          reason: '${entry.path} 的 $key 占位符与模板不一致',
        );
      }
    }
  });

  test('no unused string keys are left in the library', () {
    final Set<String> keys = messageKeys(readArb(template));
    final StringBuffer source = StringBuffer();
    for (final FileSystemEntity entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      // 生成的 l10n 文件里当然包含所有键，跳过它们才是有效检查。
      if (entity.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}')) {
        continue;
      }
      source.write(entity.readAsStringSync());
    }

    final String code = source.toString();
    final List<String> unused = keys
        .where((String key) => !code.contains(key))
        .toList()
      ..sort();

    expect(unused, isEmpty, reason: '这些键没有任何界面在用，删掉或补上界面');
  });
}
