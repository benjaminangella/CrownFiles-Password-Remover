import 'package:file_picker/file_picker.dart';
import 'office_security.dart';
import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

void main() => runApp(const CrownApp());

const navy = Color(0xFF142F68);
const royal = Color(0xFF2864D9);
const gold = Color(0xFFE1AD30);
const background = Color(0xFFF5F8FD);
const ink = Color(0xFF17273E);

enum FileAction { unlock, protect, change, inspect }

extension ActionName on FileAction {
  String get label => switch (this) {
    FileAction.unlock => 'Unlock File',
    FileAction.protect => 'Protect File',
    FileAction.change => 'Change Password',
    FileAction.inspect => 'Check Security',
  };
  IconData get icon => switch (this) {
    FileAction.unlock => Icons.lock_open_rounded,
    FileAction.protect => Icons.lock_outline_rounded,
    FileAction.change => Icons.key_rounded,
    FileAction.inspect => Icons.verified_user_outlined,
  };
}

class CrownApp extends StatelessWidget {
  const CrownApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Crown Password Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: background,
          colorScheme: ColorScheme.fromSeed(seedColor: navy),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  Future<void> open(FileAction action) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FileScreen(action: action)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.sizeOf(context).width > 800;
    return Scaffold(
      bottomNavigationBar: large
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Tools'),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: large ? 44 : 22, vertical: 20),
              children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.shield_outlined, color: gold, size: 27),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Crown Password Studio', style: TextStyle(fontSize: 19, color: navy, fontWeight: FontWeight.w800)),
                      Text('Office & PDF tools', style: TextStyle(color: Color(0xFF718096), fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 36),
                if (tab == 0 || large) ...[
                  const Text('File protection made simple.', style: TextStyle(color: ink, fontSize: 27, height: 1.16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  const Text('Choose what you need.', style: TextStyle(color: Color(0xFF728098), fontSize: 15)),
                  const SizedBox(height: 26),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      childAspectRatio: 1.10,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ActionTile(action: FileAction.unlock, onTap: () => open(FileAction.unlock)),
                        _ActionTile(action: FileAction.protect, onTap: () => open(FileAction.protect)),
                        _ActionTile(action: FileAction.change, onTap: () => open(FileAction.change)),
                        _ActionTile(action: FileAction.inspect, onTap: () => open(FileAction.inspect)),
                      ],
                    );
                  }),
                ],
                if (tab == 1 || large) ...[
                  const SizedBox(height: 34),
                  const Text('File tools', style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _FormatTile(title: 'PDF Security', detail: 'Protect, unlock, change', symbol: 'PDF', color: const Color(0xFFD6424E), onTap: () => open(FileAction.protect)),
                  _FormatTile(title: 'Excel Tools', detail: 'Inspect & edit workbook locks', symbol: 'X', color: const Color(0xFF168B59), onTap: () => open(FileAction.inspect)),
                  _FormatTile(title: 'Word Tools', detail: 'Inspect & edit document locks', symbol: 'W', color: const Color(0xFF3466CD), onTap: () => open(FileAction.inspect)),
                  _FormatTile(title: 'PowerPoint Tools', detail: 'Inspect presentation security', symbol: 'P', color: const Color(0xFFE37739), onTap: () => open(FileAction.inspect)),
                ],
                const SizedBox(height: 32),
                const Center(child: Text('Local processing • Original files preserved', style: TextStyle(color: Color(0xFF8895A5), fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});
  final FileAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE1E9F5)),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(action.icon, color: royal, size: 34),
              const SizedBox(height: 16),
              Text(action.label, textAlign: TextAlign.center,
                  style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ),
      );
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({required this.title, required this.detail, required this.symbol, required this.color, required this.onTap});
  final String title, detail, symbol;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE1E9F5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            leading: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(symbol, style: TextStyle(color: Colors.white, fontSize: symbol.length > 1 ? 13 : 22, fontWeight: FontWeight.w900)),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text(detail, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A96A9)),
          ),
        ),
      );
}

class FileScreen extends StatefulWidget {
  const FileScreen({required this.action, super.key});
  final FileAction action;
  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  PlatformFile? selected;
  OfficeInspection? officeInspection;
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  String message = '';

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: [
        'pdf', 'doc', 'docx', 'docm', 'dot', 'dotx', 'dotm',
        'xls', 'xlsx', 'xlsm', 'xlsb', 'xlt', 'xltx', 'xltm', 'xla', 'xlam',
        'ppt', 'pptx', 'pptm', 'pps', 'ppsx', 'ppsm', 'pot', 'potx', 'potm',
      ]);
      if (!mounted || file == null) return;
      OfficeInspection? inspection;
      var report = '';
      if (OfficeSecurity.isOfficeFile(file.name)) {
        try {
          inspection = OfficeSecurity.inspect(file.name, await file.readAsBytes());
          report = inspection.summary;
        } on OfficeSecurityException catch (error) {
          report = error.message;
        } catch (error) {
          report = 'Unable to inspect this file: $error';
        }
      }
      if (!mounted) return;
      setState(() {
        selected = file;
        officeInspection = inspection;
        message = report;
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Could not open the file picker: $e');
    }
  }

  Future<void> clearOfficeRestrictions() async {
    final source = selected;
    final inspection = officeInspection;
    if (source == null || inspection == null || !inspection.canClearEditingRestrictions || busy) return;
    setState(() { busy = true; message = ''; });
    try {
      final bytes = await source.readAsBytes();
      final output = OfficeSecurity.clearEditingRestrictions(source.name, bytes);
      final dot = source.name.lastIndexOf('.');
      final outputName = dot < 0
          ? '${source.name}-editable'
          : '${source.name.substring(0, dot)}-editable${source.name.substring(dot)}';
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save editable Office copy',
        fileName: outputName,
        bytes: output,
      );
      if (!mounted) return;
      setState(() {
        message = saved == null
            ? 'Save cancelled. Original file unchanged.'
            : 'Editable copy saved. The original file remains unchanged.';
      });
    } on OfficeSecurityException catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (error) {
      if (mounted) setState(() => message = 'Could not save editable copy: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> runAction() async {
    final source = selected;
    if (source == null || !source.name.toLowerCase().endsWith('.pdf')) return;
    if (widget.action != FileAction.unlock && (next.text.length < 8 || next.text != confirm.text)) {
      setState(() => message = 'Use matching passwords with at least 8 characters.');
      return;
    }
    if (widget.action == FileAction.unlock && current.text.isEmpty) {
      setState(() => message = 'Enter the current password to unlock this encrypted PDF.');
      return;
    }
    setState(() { busy = true; message = ''; });
    final pdf = Pdf();
    try {
      final sourceBytes = await source.readAsBytes();
      final input = PdfInput(MemorySource(sourceBytes), password: current.text);
      if (widget.action == FileAction.inspect) {
        final info = await pdf.info(input);
        if (!mounted) return;
        setState(() => message = 'File inspected: $info');
        return;
      }
      final output = MemorySink();
      final encryption = widget.action == FileAction.unlock
          ? PdfEncryption.remove()
          : PdfEncryption.password(
              ownerPassword: next.text,
              userPassword: next.text,
              algorithm: PdfEncryptionAlgorithm.aesKey256,
            );
      await pdf.resave(input, output, save: PdfSave.full(encryption: encryption));
      final resultBytes = output.takeBytes();
      final baseName = source.name.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
      final suffix = switch (widget.action) {
        FileAction.unlock => 'unlocked',
        FileAction.protect => 'protected',
        FileAction.change => 'updated',
        FileAction.inspect => 'checked',
      };
      final target = await FilePicker.saveFile(
        dialogTitle: 'Save processed PDF',
        fileName: '$baseName-$suffix.pdf',
        bytes: resultBytes,
      );
      if (!mounted) return;
      setState(() => message = target == null ? 'Save cancelled. Your original is unchanged.' : 'Saved successfully. Your original is unchanged.');
    } on PdfPasswordRequired {
      if (mounted) setState(() => message = 'This PDF requires its current password.');
    } on PdfWrongPassword {
      if (mounted) setState(() => message = 'The password was not accepted by this PDF.');
    } on PdfError catch (e) {
      if (mounted) setState(() => message = 'PDF error: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => message = 'Could not process this document: $e');
    } finally {
      await pdf.dispose();
      current.clear();
      next.clear();
      confirm.clear();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = selected?.name.toLowerCase().endsWith('.pdf') ?? false;
    final requiresCurrent = widget.action != FileAction.protect;
    final requiresNew = widget.action == FileAction.protect || widget.action == FileAction.change;
    return Scaffold(
      appBar: AppBar(title: Text(widget.action.label)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 630),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 14),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(27),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  Icon(widget.action.icon, color: royal, size: 50),
                  const SizedBox(height: 16),
                  Text(widget.action.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 8),
                  const Text('Office & PDF security tools', style: TextStyle(color: Color(0xFF76849B))),
                ]),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: busy ? null : pick,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(selected?.name ?? 'Choose a file', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
              ),
              if (officeInspection != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${officeInspection!.kind} security check',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(officeInspection!.summary,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF63738B))),
                        if (officeInspection!.hasVbaProject) ...[
                          const SizedBox(height: 6),
                          const Text('VBA macro project present. Macro binary is preserved.',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (officeInspection!.canClearEditingRestrictions) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : clearOfficeRestrictions,
                    icon: const Icon(Icons.edit_document),
                    label: Text(busy ? 'Processing…' : 'Save Editable Copy'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54), backgroundColor: navy),
                  ),
                  const SizedBox(height: 10),
                  const Text('Removes sheet/document editing restrictions only. Encrypted opening passwords still require the correct password.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF63738B))),
                ],
              ],
              if (isPdf) ...[
                const SizedBox(height: 20),
                if (requiresCurrent)
                  TextField(
                    controller: current,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder()),
                  ),
                if (requiresNew) ...[
                  const SizedBox(height: 16),
                  TextField(controller: next, obscureText: true, enableSuggestions: false, autocorrect: false,
                      decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: confirm, obscureText: true, enableSuggestions: false, autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Confirm new password', border: OutlineInputBorder())),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : runAction,
                  icon: Icon(widget.action.icon),
                  label: Text(busy ? 'Processing…' : widget.action.label),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: navy),
                ),
              ],
              if (message.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(message, style: const TextStyle(color: ink, height: 1.4)),
              ],
              const SizedBox(height: 25),
              const Text('Documents stay on this device. Opening an encrypted file requires a valid password.',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7A8799), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
