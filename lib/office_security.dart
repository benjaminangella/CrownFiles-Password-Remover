import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Local Office package inspection and editing-restriction handling.
///
/// A worksheet/workbook/document editing restriction is not the same as a
/// password-to-open. Strong opening encryption requires the actual password.
/// This service never modifies VBA binaries or source document bytes.
class OfficeInspection {
  const OfficeInspection({
    required this.kind,
    required this.summary,
    required this.protectedForOpening,
    required this.editingRestrictionCount,
    required this.hasVbaProject,
    required this.canClearEditingRestrictions,
  });

  final String kind;
  final String summary;
  final bool protectedForOpening;
  final int editingRestrictionCount;
  final bool hasVbaProject;
  final bool canClearEditingRestrictions;
}

class OfficeSecurityException implements Exception {
  const OfficeSecurityException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OfficeSecurity {
  static const _oleHeader = <int>[0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1];
  static const _modernExcel = {'xlsx', 'xlsm', 'xlsb', 'xltx', 'xltm', 'xlam'};
  static const _modernWord = {'docx', 'docm', 'dotx', 'dotm'};
  static const _modernPpt = {'pptx', 'pptm', 'ppsx', 'ppsm', 'potx', 'potm'};
  static const _legacy = {'xls', 'xlt', 'xla', 'doc', 'dot', 'ppt', 'pps', 'pot'};

  static bool isOfficeFile(String name) {
    final extension = name.toLowerCase().split('.').last;
    return _modernExcel.contains(extension) ||
        _modernWord.contains(extension) ||
        _modernPpt.contains(extension) ||
        _legacy.contains(extension);
  }

  static String _kind(String extension) {
    if (_modernExcel.contains(extension) || {'xls', 'xlt', 'xla'}.contains(extension)) return 'Excel';
    if (_modernWord.contains(extension) || {'doc', 'dot'}.contains(extension)) return 'Word';
    if (_modernPpt.contains(extension) || {'ppt', 'pps', 'pot'}.contains(extension)) return 'PowerPoint';
    return 'Office';
  }

  static bool _hasHeader(Uint8List bytes, List<int> header) {
    if (bytes.length < header.length) return false;
    for (var i = 0; i < header.length; i++) {
      if (bytes[i] != header[i]) return false;
    }
    return true;
  }

  static final RegExp _excelRestriction = RegExp(
    r'<(?:[A-Za-z_][\w.-]*:)?(?:sheetProtection|workbookProtection|fileSharing)\b[^<>]*/\s*>',
    caseSensitive: false,
  );
  static final RegExp _wordRestriction = RegExp(
    r'<(?:[A-Za-z_][\w.-]*:)?documentProtection\b[^<>]*/\s*>',
    caseSensitive: false,
  );

  static String? _restrictionKind(String path, String kind) {
    if (kind == 'Excel' && (
        path == 'xl/workbook.xml' ||
        RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(path))) return 'Excel';
    if (kind == 'Word' && path == 'word/settings.xml') return 'Word';
    return null;
  }

  static Iterable<RegExpMatch> _restrictionMatches(String content, String kind) =>
      (kind == 'Excel' ? _excelRestriction : _wordRestriction).allMatches(content);

  static Archive _readPackage(Uint8List bytes) {
    if (bytes.length > 100 * 1024 * 1024) {
      throw const OfficeSecurityException('File exceeds the 100 MB local processing limit.');
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      var totalSize = 0;
      for (final file in archive.files) {
        totalSize += file.size;
        if (totalSize > 300 * 1024 * 1024) {
          throw const OfficeSecurityException('Unpacked Office file is too large.');
        }
      }
      return archive;
    } on OfficeSecurityException {
      rethrow;
    } catch (_) {
      throw const OfficeSecurityException('Office package is damaged or cannot be read.');
    }
  }

  static OfficeInspection inspect(String filename, Uint8List bytes) {
    final extension = filename.toLowerCase().split('.').last;
    if (!isOfficeFile(filename)) {
      throw const OfficeSecurityException('Select a supported Word, Excel or PowerPoint document.');
    }
    final kind = _kind(extension);
    if (_hasHeader(bytes, _oleHeader)) {
      final legacy = _legacy.contains(extension);
      return OfficeInspection(
        kind: kind,
        protectedForOpening: !legacy,
        editingRestrictionCount: 0,
        hasVbaProject: false,
        canClearEditingRestrictions: false,
        summary: legacy
            ? 'Legacy Office format detected. Detailed protection inspection is not available yet.'
            : 'Office file uses an OLE container, commonly used for password-to-open encryption. Opening it requires the correct password.',
      );
    }
    if (!_hasHeader(bytes, [0x50, 0x4b])) {
      throw const OfficeSecurityException('Unrecognized Office file. It may be encrypted or damaged.');
    }
    final archive = _readPackage(bytes);
    final files = archive.files.map((file) => file.name).toSet();
    if (!files.contains('[Content_Types].xml')) {
      throw const OfficeSecurityException('Not a valid Office Open XML package.');
    }
    final required = kind == 'Excel'
        ? 'xl/workbook.xml'
        : kind == 'Word'
            ? 'word/document.xml'
            : 'ppt/presentation.xml';
    if (!files.contains(required)) {
      throw const OfficeSecurityException('Office package contents do not match the file extension.');
    }
    var restrictions = 0;
    var macros = false;
    for (final file in archive.files) {
      if (file.name.endsWith('vbaProject.bin')) macros = true;
      if (_restrictionKind(file.name, kind) == null) continue;
      final raw = file.readBytes();
      if (raw == null) continue;
      final content = utf8.decode(raw, allowMalformed: true);
      restrictions += _restrictionMatches(content, kind).length;
    }
    final supported = (kind == 'Excel' || kind == 'Word') && restrictions > 0;
    final summary = restrictions > 0
        ? '$restrictions editing restriction(s) found in $kind. This is not opening-password encryption.'
        : macros
            ? 'Macro project detected. No supported sheet/document editing restrictions found. VBA project passwords are not processed.'
            : 'No supported $kind editing restrictions detected.';
    return OfficeInspection(
      kind: kind,
      summary: summary,
      protectedForOpening: false,
      editingRestrictionCount: restrictions,
      hasVbaProject: macros,
      canClearEditingRestrictions: supported,
    );
  }

  /// Clear non-encryption editing controls in a new package, preserving
  /// the original source and every VBA binary entry without alteration.
  static Uint8List clearEditingRestrictions(String filename, Uint8List bytes) {
    final inspection = inspect(filename, bytes);
    if (!inspection.canClearEditingRestrictions) {
      throw const OfficeSecurityException('No supported editing restrictions found.');
    }
    final source = _readPackage(bytes);
    final output = Archive();
    var removed = 0;
    for (final entry in source.files) {
      if (!entry.isFile) {
        output.add(ArchiveFile.directory(entry.name));
        continue;
      }
      final original = entry.readBytes();
      if (original == null) {
        throw const OfficeSecurityException('Unable to read an Office package entry.');
      }
      var contents = original;
      if (_restrictionKind(entry.name, inspection.kind) != null) {
        final xml = utf8.decode(original, allowMalformed: false);
        final cleaned = xml.replaceAll(
          inspection.kind == 'Excel' ? _excelRestriction : _wordRestriction,
          '',
        );
        if (xml != cleaned) {
          removed += _restrictionMatches(xml, inspection.kind).length;
          contents = Uint8List.fromList(utf8.encode(cleaned));
        }
      }
      final next = ArchiveFile.bytes(entry.name, contents);
      next.lastModTime = entry.lastModTime;
      output.add(next);
    }
    if (removed == 0) {
      throw const OfficeSecurityException('No editing restrictions were removed.');
    }
    final encoded = ZipEncoder().encode(output);
    final result = Uint8List.fromList(encoded);
    final validation = inspect(filename, result);
    if (validation.editingRestrictionCount != 0) {
      throw const OfficeSecurityException('Output failed restriction validation.');
    }
    if (validation.hasVbaProject != inspection.hasVbaProject) {
      throw const OfficeSecurityException('Output failed macro-preservation validation.');
    }
    return result;
  }
}
