import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crown_password_studio/office_security.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List makePackage(Map<String, String> files, {Map<String, List<int>> binary = const {}}) {
  final archive = Archive();
  archive.add(ArchiveFile.string('[Content_Types].xml', '<Types/>'));
  for (final entry in files.entries) {
    archive.add(ArchiveFile.string(entry.key, entry.value));
  }
  for (final entry in binary.entries) {
    archive.add(ArchiveFile.bytes(entry.key, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  test('detects worksheet and workbook structure restrictions', () {
    final bytes = makePackage({
      'xl/workbook.xml': '<workbook><workbookProtection lockStructure="1" workbookPassword="AAAA"/></workbook>',
      'xl/worksheets/sheet1.xml': '<worksheet><sheetProtection sheet="1" password="AAAA"/></worksheet>',
    });
    final before = Uint8List.fromList(bytes);
    final state = OfficeSecurity.inspect('report.xlsx', bytes);
    expect(state.kind, 'Excel');
    expect(state.editingRestrictionCount, 2);
    expect(state.canClearEditingRestrictions, isTrue);
    final cleared = OfficeSecurity.clearEditingRestrictions('report.xlsx', bytes);
    expect(OfficeSecurity.inspect('report.xlsx', cleared).editingRestrictionCount, 0);
    expect(bytes, orderedEquals(before));
    final output = ZipDecoder().decodeBytes(cleared);
    expect(utf8.decode(output.findFile('xl/workbook.xml')!.content), contains('<workbook>'));
  });

  test('Word editing restriction removal preserves content and macros', () {
    final macro = List<int>.generate(24, (i) => i * 3);
    final original = makePackage({
      'word/document.xml': '<document>Preserve this text</document>',
      'word/settings.xml': '<settings><w:documentProtection w:enforcement="1" w:edit="readOnly"/></settings>',
    }, binary: {'word/vbaProject.bin': macro});
    final details = OfficeSecurity.inspect('letter.docm', original);
    expect(details.hasVbaProject, isTrue);
    expect(details.editingRestrictionCount, 1);
    final result = OfficeSecurity.clearEditingRestrictions('letter.docm', original);
    final archive = ZipDecoder().decodeBytes(result, verify: true);
    expect(archive.findFile('word/vbaProject.bin')!.content, orderedEquals(macro));
    expect(utf8.decode(archive.findFile('word/document.xml')!.content), contains('Preserve this text'));
    expect(OfficeSecurity.inspect('letter.docm', result).editingRestrictionCount, 0);
  });

  test('correctly reports encrypted modern Office as opening-password protection', () {
    final ole = Uint8List.fromList([
      0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1,
      1, 2, 3, 4, 5,
    ]);
    final info = OfficeSecurity.inspect('protected.pptx', ole);
    expect(info.protectedForOpening, isTrue);
    expect(info.canClearEditingRestrictions, isFalse);
    expect(() => OfficeSecurity.clearEditingRestrictions('protected.pptx', ole),
        throwsA(isA<OfficeSecurityException>()));
  });

  test('macro-enabled Excel is preserved after editing unlock', () {
    final macro = [11, 22, 33, 44];
    final original = makePackage({
      'xl/workbook.xml': '<workbook><workbookProtection lockStructure="1"/></workbook>',
      'xl/worksheets/sheet1.xml': '<worksheet><sheetProtection sheet="1"/></worksheet>',
    }, binary: {'xl/vbaProject.bin': macro});
    final result = OfficeSecurity.clearEditingRestrictions('budget.xlsm', original);
    final archive = ZipDecoder().decodeBytes(result);
    expect(archive.findFile('xl/vbaProject.bin')!.content, orderedEquals(macro));
    expect(OfficeSecurity.inspect('budget.xlsm', result).hasVbaProject, isTrue);
  });

  test('PowerPoint package inspected without pretending to remove encryption', () {
    final input = makePackage({
      'ppt/presentation.xml': '<presentation/>',
    });
    final info = OfficeSecurity.inspect('deck.pptx', input);
    expect(info.kind, 'PowerPoint');
    expect(info.canClearEditingRestrictions, isFalse);
  });

  test('rejects corrupt or mismatched documents', () {
    expect(() => OfficeSecurity.inspect('bad.xlsx', Uint8List.fromList([5, 6, 7])),
        throwsA(isA<OfficeSecurityException>()));
    final wordPackage = makePackage({'word/document.xml': '<document/>'});
    expect(() => OfficeSecurity.inspect('fake.xlsx', wordPackage),
        throwsA(isA<OfficeSecurityException>()));
  });
}
