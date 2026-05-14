import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'api_service.dart';

void main() {
  runApp(const DataBridgeApp());
}

class T {
  static const bg = Color(0xFFF5F7FA);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFEAEEF2);
  static const accent = Color(0xFF3B6FE8);
  static const accentLight = Color(0xFFEDF2FF);
  static const accentMid = Color(0xFFD0DCFF);
  static const success = Color(0xFF12A05C);
  static const successLight = Color(0xFFEAFAF1);
  static const warning = Color(0xFFE07B10);
  static const warningLight = Color(0xFFFFF4E5);
  static const danger = Color(0xFFD93025);
  static const dangerLight = Color(0xFFFFF0EF);
  static const t1 = Color(0xFF111827);
  static const t2 = Color(0xFF4B5563);
  static const t3 = Color(0xFF9CA3AF);
  static const t4 = Color(0xFFD1D5DB);

  static const fontSm = 11.0;
  static const fontBase = 13.0;
  static const fontMd = 14.0;
  static const fontLg = 16.0;
  static const fontXl = 20.0;
  static const font2xl = 26.0;
  static const r1 = 8.0;
  static const r2 = 12.0;
  static const r3 = 16.0;
  static const r4 = 24.0;

  static ThemeData theme() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(primary: accent, surface: white),
        appBarTheme: const AppBarTheme(
            backgroundColor: white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark),
        textTheme: const TextTheme(
            bodyMedium: TextStyle(color: t1, fontSize: fontBase)),
      );
}

class Responsive extends StatelessWidget {
  final Widget child;
  const Responsive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 500) {
      return Container(
        color: const Color(0xFFDDE3ED),
        child: Center(
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: T.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 60,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRect(child: child),
          ),
        ),
      );
    }
    return child;
  }
}

class DbState extends ChangeNotifier {
  bool isConnected = false;
  String dbUrl = '';
  String dbName = '';

  void connect(String url) {
    dbUrl = url;
    dbName = _parse(url);
    isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    isConnected = false;
    dbUrl = '';
    dbName = '';
    notifyListeners();
  }

  String _parse(String url) {
    try {
      final uri = Uri.parse(url.replaceFirst('mysql://', 'http://'));
      final p = uri.path.replaceAll('/', '');
      return p.isEmpty ? 'database' : p;
    } catch (_) {
      return 'database';
    }
  }
}

class DataBridgeApp extends StatelessWidget {
  const DataBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
        },
      ),
      title: 'DataBridge',
      debugShowCheckedModeBanner: false,
      theme: T.theme(),
      builder: (context, child) => Responsive(child: child!),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;
  int _dbRefreshKey = 0;
  int _analyticsRefreshKey = 0;
  final DbState _db = DbState();

  void _onTabTap(int i) {
    setState(() {
      if (i == 1) _dbRefreshKey++;
      if (i == 3) _analyticsRefreshKey++;
      _idx = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      UploadScreen(db: _db),
      DatabaseScreen(db: _db, key: ValueKey(_dbRefreshKey)),
      QueryScreen(db: _db),
      AnalyticsScreen(key: ValueKey(_analyticsRefreshKey)),
      SettingsScreen(db: _db),
    ];

    return Scaffold(
      backgroundColor: T.bg,
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(58), child: _AppBar(db: _db)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(_idx), child: screens[_idx]),
      ),
      bottomNavigationBar:
          _BottomBar(idx: _idx, onTap: _onTabTap),
    );
  }
}

class _AppBar extends StatelessWidget {
  final DbState db;
  const _AppBar({required this.db});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: db,
      builder: (ctx, _) => Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(ctx).padding.top, left: 18, right: 14),
        decoration: const BoxDecoration(
            color: T.white,
            border: Border(bottom: BorderSide(color: T.border))),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B6FE8), Color(0xFF6B47DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(T.r1)),
            child:
                const Icon(Icons.hub_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          const Text('DataBridge',
              style: TextStyle(
                  color: T.t1,
                  fontSize: T.fontLg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => showDialog(
                context: ctx, builder: (_) => _ConnectDialog(db: db)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: db.isConnected ? T.successLight : T.accentLight,
                borderRadius: BorderRadius.circular(T.r4),
                border: Border.all(
                    color: db.isConnected
                        ? T.success.withValues(alpha: 0.35)
                        : T.accent.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: db.isConnected ? T.success : T.accent),
                ),
                const SizedBox(width: 7),
                Text(db.isConnected ? db.dbName : 'Connect DB',
                    style: TextStyle(
                        fontSize: T.fontSm,
                        fontWeight: FontWeight.w700,
                        color: db.isConnected ? T.success : T.accent,
                        letterSpacing: 0.2)),
                if (db.isConnected) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.expand_more_rounded,
                      size: 14,
                      color: db.isConnected ? T.success : T.accent),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ConnectDialog extends StatefulWidget {
  final DbState db;
  const _ConnectDialog({required this.db});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _ctrl = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.db.isConnected) _ctrl.text = widget.db.dbUrl;
  }

  @override
  Widget build(BuildContext ctx) {
    return Dialog(
      backgroundColor: T.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(T.r3),
          side: const BorderSide(color: T.border)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: T.accentLight,
                        borderRadius: BorderRadius.circular(T.r1)),
                    child: const Icon(Icons.storage_rounded,
                        color: T.accent, size: 17)),
                const SizedBox(width: 11),
                const Text('Connect Database',
                    style: TextStyle(
                        color: T.t1,
                        fontSize: T.fontLg,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded,
                        color: T.t3, size: 19)),
              ]),
              const SizedBox(height: 20),
              const Text('CONNECTION URL',
                  style: TextStyle(
                      color: T.t3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3)),
              const SizedBox(height: 7),
              Container(
                decoration: BoxDecoration(
                    color: T.bg,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: TextField(
                  controller: _ctrl,
                  obscureText: _hide,
                  style: const TextStyle(
                      color: T.t1,
                      fontSize: T.fontBase,
                      fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'mysql://user:pass@host:3306/db',
                    hintStyle:
                        const TextStyle(color: T.t4, fontSize: T.fontBase),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: T.t3,
                          size: 16),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('mysql://username:password@hostname:3306/dbname',
                  style: TextStyle(color: T.t3, fontSize: 10)),
              const SizedBox(height: 18),
              if (widget.db.isConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: T.successLight,
                      borderRadius: BorderRadius.circular(T.r1),
                      border: Border.all(
                          color: T.success.withValues(alpha: 0.25))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: T.success, size: 15),
                    const SizedBox(width: 7),
                    Text('Connected to ${widget.db.dbName}',
                        style: const TextStyle(
                            color: T.success,
                            fontSize: T.fontSm,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              Row(children: [
                if (widget.db.isConnected) ...[
                  Expanded(
                      child: _Btn(
                          label: 'Disconnect',
                          onTap: () {
                            widget.db.disconnect();
                            Navigator.pop(ctx);
                          },
                          outline: true,
                          danger: true)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                    flex: 2,
                    child: _Btn(
                        label: _loading ? 'Connecting…' : 'Connect',
                        onTap: _loading ? null : _connect)),
              ]),
            ]),
      ),
    );
  }

  void _connect() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    widget.db.connect(url);
    if (mounted) Navigator.pop(context);
  }
}

class _BottomBar extends StatelessWidget {
  final int idx;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.idx, required this.onTap});

  static const _items = [
    (icon: Icons.upload_file_rounded, label: 'Upload'),
    (icon: Icons.table_rows_rounded, label: 'Database'),
    (icon: Icons.manage_search_rounded, label: 'Query'),
    (icon: Icons.analytics_outlined, label: 'Analytics'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: T.white,
          border: Border(top: BorderSide(color: T.border))),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4, top: 6),
      child: Row(
        children: List.generate(_items.length, (i) {
          final sel = i == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                      color: sel ? T.accentLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(T.r4)),
                  child: Icon(_items[i].icon,
                      size: 21, color: sel ? T.accent : T.t3),
                ),
                const SizedBox(height: 3),
                Text(_items[i].label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? T.accent : T.t3,
                        letterSpacing: 0.2)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UPLOAD SCREEN
// ─────────────────────────────────────────────
class UploadScreen extends StatefulWidget {
  final DbState db;
  const UploadScreen({super.key, required this.db});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker = ImagePicker();
  bool _loading = false;
  String _status = '';
  Uint8List? _imageBytes;
  String _extractedText = '';
  Map<String, dynamic>? _schema;
  Map<String, dynamic>? _schema2;
  Map<String, dynamic>? _fusionResult;
  bool _saved = false;
  bool _fusionMode = false;
  int _editingIndex = -1;
  final Map<int, TextEditingController> _editControllers = {};

  void _startEdit(int index, String currentValue) {
    setState(() {
      _editingIndex = index;
      _editControllers[index] = TextEditingController(text: currentValue);
    });
  }

  void _saveEdit(int index) {
    if (_schema == null) return;
    final newValue = _editControllers[index]?.text ?? '';
    final fields = List<Map<String, dynamic>>.from(_schema!['fields']);
    fields[index] = {
      ...fields[index],
      'value': newValue,
      'confidence': 100,
      'valid': true,
      'reason': '',
    };
    setState(() {
      _schema = {..._schema!, 'fields': fields};
      _editingIndex = -1;
      _editControllers.remove(index);
    });
  }

  Future<void> _startFusion() async {
    setState(() {
      _fusionMode = true;
      _status = 'Pick another source to fuse with…';
    });
  }

  int _fusionCount = 1;

  Future<void> _processFusion(String text) async {
    if (_schema == null) return;
    setState(() {
      _loading = true;
      _status = 'Generating schema for source ${_fusionCount + 1}…';
    });
    final schemaResult = await ApiService.generateSchema(text);
    if (schemaResult['success'] != true) {
      setState(() {
        _loading = false;
        _status = 'Schema error: ${schemaResult['error']}';
        _fusionMode = false;
      });
      return;
    }
    setState(() => _status = 'Fusing data from all sources…');
    // Always fuse with current schema (which may already be a fusion)
    final fusionResult = await ApiService.fuseSchemas(
        _schema!, schemaResult['schema']);
    setState(() {
      _loading = false;
      _fusionMode = false;
      if (fusionResult['success'] == true) {
        _fusionCount++;
        _schema2 = schemaResult['schema'];
        _fusionResult = fusionResult;
        _schema = fusionResult['schema'];
        _status = 'Fusion complete! $_fusionCount sources merged · ${fusionResult['agreed']} agreed · ${fusionResult['conflicts']} conflicts';
      } else {
        _status = 'Fusion failed: ${fusionResult['error']}';
      }
    });
  }

  Future<void> _processText(String text) async {
    setState(() {
      _extractedText = text;
      _status = 'Generating schema…';
    });
    final schemaResult = await ApiService.generateSchema(text);
    setState(() {
      _loading = false;
      if (schemaResult['success'] == true) {
        _schema = schemaResult['schema'];
        _status = 'Schema ready';
      } else {
        _status = 'Schema error: ${schemaResult['error']}';
      }
    });
  }

  Future<void> _pickImage() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (!_fusionMode) _imageBytes = bytes;
      _loading = true;
      _status = _fusionMode ? 'Extracting text from source ${_fusionCount + 1}…' : 'Extracting text…';
      if (!_fusionMode) {
        _extractedText = '';
        _schema = null;
        _saved = false;
        _fusionResult = null;
        _schema2 = null;
        _fusionCount = 1;
      }
    });
    final ocrResult = await ApiService.extractFromImageBytes(bytes, picked.name);
    if (ocrResult['success'] != true) {
      setState(() {
        _loading = false;
        _status = 'OCR failed: ${ocrResult['error']}';
        _fusionMode = false;
      });
      return;
    }
    if (_fusionMode) {
      await _processFusion(ocrResult['extracted_text'] ?? '');
    } else {
      await _processText(ocrResult['extracted_text'] ?? '');
    }
  }

  Future<void> _recordVoice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final audioBytes = result.files.first.bytes;
    final filename = result.files.first.name;
    if (audioBytes == null) return;
    setState(() {
      _imageBytes = null;
      _loading = true;
      _status = 'Transcribing audio…';
      _extractedText = '';
      _schema = null;
      _saved = false;
    });
    final transcribeResult =
        await ApiService.extractFromAudioBytes(audioBytes, filename);
    if (transcribeResult['success'] != true) {
      setState(() {
        _loading = false;
        _status = 'Transcription failed: ${transcribeResult['error']}';
      });
      return;
    }
    await _processText(transcribeResult['extracted_text'] ?? '');
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    final filename = result.files.first.name;
    if (bytes == null) return;
    setState(() {
      _imageBytes = null;
      _loading = true;
      _status = 'Extracting text from document…';
      _extractedText = '';
      _schema = null;
      _saved = false;
    });
    final extractResult =
        await ApiService.extractFromDocumentBytes(bytes, filename);
    if (extractResult['success'] != true) {
      setState(() {
        _loading = false;
        _status = 'Extraction failed: ${extractResult['error']}';
      });
      return;
    }
    await _processText(extractResult['extracted_text'] ?? '');
  }

  Future<void> _pickSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    final filename = result.files.first.name;
    if (bytes == null) return;
    setState(() {
      _imageBytes = null;
      _loading = true;
      _status = 'Reading spreadsheet…';
      _extractedText = '';
      _schema = null;
      _saved = false;
    });
    final extractResult =
        await ApiService.extractFromSpreadsheetBytes(bytes, filename);
    if (extractResult['success'] != true) {
      setState(() {
        _loading = false;
        _status = 'Extraction failed: ${extractResult['error']}';
      });
      return;
    }
    // Spreadsheet saves all rows directly — no schema step needed
    final rowsSaved = extractResult['rows_saved']?.toString() ?? '0';
    final tableName = extractResult['table_name']?.toString() ?? 'table';
    setState(() {
      _loading = false;
      _extractedText = extractResult['extracted_text'] ?? '';
      _saved = true;
      _status = 'Saved $rowsSaved rows to $tableName!';
    });
  }

  Future<void> _saveToDatabase() async {
    print("SAVE TRIGGERED");
    if (_schema == null) {
      print("SCHEMA IS NULL");
      return;
    }
    print("SCHEMA: ${_schema!['table_name']}");
    print("FIELDS COUNT: ${(_schema!['fields'] as List).length}");
    setState(() {
      _loading = true;
      _status = 'Saving to database…';
    });

    // Clean schema — remove fusion fields before saving
    final cleanFields = (_schema!['fields'] as List).map((f) {
      return {
        'name': f['name'],
        'type': f['type'],
        'value': f['value'] ?? '',
        'confidence': f['confidence'] ?? 100,
        'valid': f['valid'] ?? true,
        'reason': f['reason'] ?? '',
      };
    }).toList();

    final cleanSchema = {
      'table_name': _schema!['table_name'],
      'fields': cleanFields,
    };

    final result = await ApiService.saveData(cleanSchema);
    print("SAVE RESULT: $result");

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _saved = true;
        _status = 'Saved to ${result['table']}!';
      } else {
        _status = 'Save failed: ${result['error']}';
      }
    });

  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: T.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(T.r3))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: T.border,
                  borderRadius: BorderRadius.circular(T.r4))),
          const SizedBox(height: 18),
          const Text('Select Image Source',
              style: TextStyle(
                  color: T.t1,
                  fontSize: T.fontLg,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
          const SizedBox(height: 8),
          _SourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: T.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(T.r3),
            side: const BorderSide(color: T.border)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F7),
                          borderRadius: BorderRadius.circular(T.r1)),
                      child: const Icon(Icons.edit_note_rounded,
                          color: Color(0xFFDB2777), size: 17)),
                  const SizedBox(width: 10),
                  const Text('Manual Entry',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontLg,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close_rounded,
                          color: T.t3, size: 18)),
                ]),
                const SizedBox(height: 16),
                const Text('DATA',
                    style: TextStyle(
                        color: T.t3,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3)),
                const SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                      color: T.bg,
                      borderRadius: BorderRadius.circular(T.r2),
                      border: Border.all(color: T.border)),
                  child: TextField(
                    controller: ctrl,
                    maxLines: 5,
                    style: const TextStyle(color: T.t1, fontSize: T.fontBase),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Name: John, Age: 25, City: Pune...',
                      hintStyle: TextStyle(color: T.t4, fontSize: T.fontBase),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Btn(
                    label: 'Process Data',
                    onTap: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      Navigator.pop(ctx);
                      setState(() {
                        _imageBytes = null;
                        _loading = true;
                        _status = 'Processing…';
                        _extractedText = '';
                        _schema = null;
                        _saved = false;
                      });
                      await _processText(text);
                    }),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import Data',
                style: TextStyle(
                    color: T.t1,
                    fontSize: T.font2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6)),
            const SizedBox(height: 3),
            Text('Choose a source to extract & store',
                style: TextStyle(
                    color: T.t2.withValues(alpha: 0.8),
                    fontSize: T.fontBase)),
            const SizedBox(height: 20),
            const _SectionLabel('Input Methods'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _InputTile(
                      icon: Icons.image_outlined,
                      label: 'Image / Photo',
                      sub: 'JPG, PNG, handwritten',
                      color: const Color(0xFF3B6FE8),
                      onTap: _pickImage)),
              const SizedBox(width: 10),
              Expanded(
                  child: _InputTile(
                      icon: Icons.mic_none_rounded,
                      label: 'Voice',
                      sub: 'Upload audio file',
                      color: const Color(0xFF7C3AED),
                      onTap: _recordVoice)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _InputTile(
                      icon: Icons.description_outlined,
                      label: 'Document',
                      sub: 'PDF, Word, TXT',
                      color: const Color(0xFFE07B10),
                      onTap: _pickDocument)),
              const SizedBox(width: 10),
              Expanded(
                  child: _InputTile(
                      icon: Icons.grid_on_rounded,
                      label: 'Spreadsheet',
                      sub: 'CSV, Excel files',
                      color: const Color(0xFF12A05C),
                      onTap: _pickSpreadsheet)),
            ]),
            const SizedBox(height: 10),
            _InputTileFull(
                icon: Icons.edit_note_rounded,
                label: 'Manual Entry',
                sub: 'Type or paste data directly',
                color: const Color(0xFFDB2777),
                onTap: () => _showManualEntryDialog(ctx)),
            const SizedBox(height: 24),

            // Fusion mode banner
            if (_fusionMode && !_loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3B6FE8), Color(0xFF6B47DC)]),
                    borderRadius: BorderRadius.circular(T.r2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.merge_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Fusion Mode Active',
                        style: TextStyle(color: Colors.white, fontSize: T.fontMd, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Now pick a second source below. Data from both sources will be merged.',
                      style: TextStyle(color: Colors.white70, fontSize: T.fontSm, height: 1.5)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() { _fusionMode = false; _status = ''; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(T.r1)),
                      child: const Text('Cancel Fusion', style: TextStyle(color: Colors.white, fontSize: T.fontSm, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),

            // Loading
            if (_loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: T.accentLight,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.accentMid)),
                child: Row(children: [
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: T.accent)),
                  const SizedBox(width: 14),
                  Text(_status,
                      style: const TextStyle(
                          color: T.accent,
                          fontSize: T.fontBase,
                          fontWeight: FontWeight.w600)),
                ]),
              ),

            // Image preview
            if (_imageBytes != null && !_loading) ...[
              const SizedBox(height: 18),
              _SectionLabel(_fusionResult != null ? 'Source 1 — Image' : 'Selected Image'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(T.r2),
                child: Image.memory(_imageBytes!,
                    width: double.infinity, height: 170, fit: BoxFit.cover),
              ),
            ],

            // Extracted text
            if (_extractedText.isNotEmpty && !_loading) ...[
              const SizedBox(height: 18),
              const _SectionLabel('Extracted Text'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: T.white,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: Text(_extractedText,
                    style: const TextStyle(
                        color: T.t1, fontSize: T.fontBase, height: 1.6)),
              ),
            ],

            // Saved success banner (for spreadsheet)
            if (_saved && _schema == null && !_loading) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: T.successLight,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(
                        color: T.success.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: T.success, size: 20),
                  const SizedBox(width: 10),
                  Text(_status,
                      style: const TextStyle(
                          color: T.success,
                          fontSize: T.fontMd,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ],

            // Schema preview (for image/voice/document)
            if (_schema != null && !_loading) ...[
              const SizedBox(height: 18),
              Row(children: [
                const _SectionLabel('Generated Schema'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3B6FE8), Color(0xFF6B47DC)]),
                      borderRadius: BorderRadius.circular(T.r4)),
                  child: Text(_schema!['table_name'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: T.fontSm,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: T.white,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: T.bg,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(T.r2),
                            topRight: Radius.circular(T.r2))),
                    child: Row(children: const [
                      Expanded(
                          child: Text('FIELD',
                              style: TextStyle(
                                  color: T.t3,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1))),
                      Expanded(
                          child: Text('TYPE',
                              style: TextStyle(
                                  color: T.t3,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1))),
                      Expanded(
                          flex: 2,
                          child: Text('VALUE',
                              style: TextStyle(
                                  color: T.t3,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1))),
                    ]),
                  ),
                  ...List.generate((_schema!['fields'] as List).length, (index) {
                    final field = (_schema!['fields'] as List)[index];
                    final isValid = field['valid'] ?? true;
                    final confidence = field['confidence'] ?? 100;
                    final reason = field['reason'] ?? '';
                    final isLowConfidence = confidence < 70;
                    final isEditing = _editingIndex == index;
                    final fusionStatus = field['fusion'] ?? '';
                    final hasConflict = fusionStatus == 'conflict';
                    final value2 = field['value2']?.toString() ?? '';
                    Color rowColor = Colors.transparent;
                    if (hasConflict) rowColor = T.warningLight;
                    else if (!isValid) rowColor = T.dangerLight;
                    else if (isLowConfidence) rowColor = T.warningLight;
                    else if (fusionStatus == 'agreed') rowColor = T.successLight;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                          color: rowColor,
                          border: const Border(top: BorderSide(color: T.border))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(field['name'] ?? '',
                                    style: const TextStyle(
                                        color: T.t1,
                                        fontSize: T.fontBase,
                                        fontWeight: FontWeight.w600))),
                            Expanded(
                                child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: T.accentLight,
                                  borderRadius: BorderRadius.circular(T.r1)),
                              child: Text(field['type'] ?? '',
                                  style: const TextStyle(
                                      color: T.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            )),
                            Expanded(
                                flex: 2,
                                child: Row(children: [
                                  Expanded(
                                    child: isEditing
                                      ? TextField(
                                          controller: _editControllers[index],
                                          autofocus: true,
                                          style: const TextStyle(
                                              color: T.t1,
                                              fontSize: T.fontBase),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(T.r1),
                                              borderSide: BorderSide(color: T.accent),
                                            ),
                                          ),
                                          onSubmitted: (_) => _saveEdit(index),
                                        )
                                      : Text(
                                          field['value']?.toString() ?? '',
                                          style: TextStyle(
                                              color: !isValid ? T.danger : T.t2,
                                              fontSize: T.fontBase)),
                                  ),
                                  const SizedBox(width: 6),
                                  if (isEditing)
                                    GestureDetector(
                                      onTap: () => _saveEdit(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: T.successLight,
                                            borderRadius: BorderRadius.circular(T.r1)),
                                        child: const Icon(Icons.check_rounded,
                                            color: T.success, size: 14),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () => _startEdit(index, field['value']?.toString() ?? ''),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: !isValid ? T.dangerLight : T.bg,
                                            borderRadius: BorderRadius.circular(T.r1),
                                            border: Border.all(color: T.border)),
                                        child: Icon(Icons.edit_rounded,
                                            color: !isValid ? T.danger : T.t3,
                                            size: 12),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: !isValid ? T.dangerLight : isLowConfidence ? T.warningLight : T.successLight,
                                        borderRadius: BorderRadius.circular(T.r1)),
                                    child: Text('$confidence%',
                                        style: TextStyle(
                                            color: !isValid ? T.danger : isLowConfidence ? T.warning : T.success,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ])),
                          ]),
                          if (!isValid && reason.isNotEmpty && !isEditing)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: T.danger, size: 12),
                                const SizedBox(width: 4),
                                Expanded(child: Text(reason,
                                    style: const TextStyle(
                                        color: T.danger,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic))),
                              ]),
                            ),
                          if (isLowConfidence && isValid && !isEditing && !hasConflict)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: T.warning, size: 12),
                                const SizedBox(width: 4),
                                const Text('Low confidence — please verify',
                                    style: TextStyle(
                                        color: T.warning,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic)),
                              ]),
                            ),
                          if (hasConflict && value2.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('⚡ CONFLICT — Choose a value:',
                                    style: TextStyle(color: T.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final fields = List<Map<String, dynamic>>.from(_schema!['fields']);
                                        fields[index] = {...fields[index], 'fusion': 'resolved', 'valid': true, 'confidence': 100};
                                        setState(() => _schema = {..._schema!, 'fields': fields});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: T.accentLight,
                                            borderRadius: BorderRadius.circular(T.r1),
                                            border: Border.all(color: T.accent.withValues(alpha: 0.4))),
                                        child: Text('Source 1: ${field['value']}',
                                            style: const TextStyle(color: T.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final fields = List<Map<String, dynamic>>.from(_schema!['fields']);
                                        fields[index] = {...fields[index], 'value': value2, 'fusion': 'resolved', 'valid': true, 'confidence': 100};
                                        setState(() => _schema = {..._schema!, 'fields': fields});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF5F3FF),
                                            borderRadius: BorderRadius.circular(T.r1),
                                            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4))),
                                        child: Text('Source 2: $value2',
                                            style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ]),
                              ]),
                            ),
                          if (fusionStatus == 'agreed')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(children: [
                                const Icon(Icons.check_circle_rounded, color: T.success, size: 12),
                                const SizedBox(width: 4),
                                const Text('Both sources agree — confidence boosted',
                                    style: TextStyle(color: T.success, fontSize: 10, fontStyle: FontStyle.italic)),
                              ]),
                            ),
                        ],
                      ),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 14),
              _saved
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: T.successLight,
                          borderRadius: BorderRadius.circular(T.r2),
                          border: Border.all(
                              color: T.success.withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: T.success, size: 20),
                        const SizedBox(width: 10),
                        Text(_status,
                            style: const TextStyle(
                                color: T.success,
                                fontSize: T.fontMd,
                                fontWeight: FontWeight.w600)),
                      ]),
                    )
                  : Column(children: [
                      _Btn(label: 'Save to Database →', onTap: _saveToDatabase),
                      const SizedBox(height: 8),
                      _Btn(
                        label: _fusionResult == null 
                          ? '🔀 Fuse with Another Source'
                          : '🔀 Add Source ${_fusionCount + 1}',
                        onTap: _startFusion,
                        outline: true,
                      ),
                    ]),

              // Fusion score banner
              if (_fusionResult != null && !_saved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3B6FE8), Color(0xFF6B47DC)]),
                      borderRadius: BorderRadius.circular(T.r2)),
                  child: Row(children: [
                    const Icon(Icons.merge_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Multimodal Fusion Complete',
                          style: TextStyle(color: Colors.white, fontSize: T.fontMd, fontWeight: FontWeight.w700)),
                      Text('$_fusionCount sources · Fusion Score: ${_fusionResult!['fusion_score']}% · ${_fusionResult!['agreed']} agreed · ${_fusionResult!['conflicts']} conflicts',
                          style: const TextStyle(color: Colors.white70, fontSize: T.fontSm)),
                    ])),
                  ]),
                ),
              ],
            ],

            // Empty state
            if (!_loading &&
                _extractedText.isEmpty &&
                _imageBytes == null &&
                !_saved) ...[
              const SizedBox(height: 8),
              const _SectionLabel('Recent Activity'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                    color: T.white,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: T.accentLight, shape: BoxShape.circle),
                    child: const Icon(Icons.upload_rounded,
                        color: T.accent, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text('No imports yet',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontLg,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Choose an input method above to get started',
                      style: TextStyle(color: T.t3, fontSize: T.fontBase)),
                ]),
              ),
            ],
          ]),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.bg,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border)),
            child: Row(children: [
              Icon(icon, color: T.accent, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      color: T.t1,
                      fontSize: T.fontMd,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: T.t3, size: 18),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
// DATABASE SCREEN
// ─────────────────────────────────────────────
class DatabaseScreen extends StatefulWidget {
  final DbState db;
  const DatabaseScreen({super.key, required this.db});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<Map<String, dynamic>> _tables = [];
  bool _loading = false;
  String? _selectedTable;
  List<String> _columns = [];
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _loading = true);
    final result = await ApiService.getTables();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _tables = List<Map<String, dynamic>>.from(result['tables'] ?? []);
      }
    });
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _selectedTable = tableName;
      _loading = true;
    });
    final result = await ApiService.getTableRows(tableName);
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _columns = List<String>.from(result['columns'] ?? []);
        _rows = List<Map<String, dynamic>>.from(result['rows'] ?? []);
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Database',
                    style: TextStyle(
                        color: T.t1,
                        fontSize: T.font2xl,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6)),
                const SizedBox(height: 3),
                Text('${_tables.length} tables',
                    style: TextStyle(
                        color: T.t2.withValues(alpha: 0.8),
                        fontSize: T.fontBase)),
              ]),
              const Spacer(),
              if (_tables.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: T.successLight,
                      borderRadius: BorderRadius.circular(T.r4),
                      border: Border.all(
                          color: T.success.withValues(alpha: 0.3))),
                  child: Row(children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: T.success)),
                    const SizedBox(width: 6),
                    const Text('Live',
                        style: TextStyle(
                            color: T.success,
                            fontSize: T.fontSm,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: _StatBox(
                      label: 'Tables',
                      value: '${_tables.length}',
                      icon: Icons.table_rows_outlined,
                      color: T.accent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'Records',
                      value:
                          '${_tables.fold(0, (sum, t) => sum + (t['row_count'] as int? ?? 0))}',
                      icon: Icons.data_array_rounded,
                      color: const Color(0xFF7C3AED))),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      label: 'Status',
                      value: 'Live',
                      icon: Icons.storage_outlined,
                      color: T.success)),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              const _SectionLabel('Tables'),
              const Spacer(),
              _SmallBtn(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  onTap: _loadTables),
            ]),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: T.accent)))
            else if (_tables.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                    color: T.white,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: T.accentLight, shape: BoxShape.circle),
                    child: const Icon(Icons.table_view_outlined,
                        color: T.accent, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text('No tables yet',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontLg,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Upload data to auto-generate schemas',
                      style: TextStyle(color: T.t3, fontSize: T.fontBase)),
                ]),
              )
            else
              ..._tables.map((table) => _TableCard(
                    table: table,
                    isSelected: _selectedTable == table['name'],
                    onTap: () => _loadTableData(table['name']),
                  )),
            if (_selectedTable != null && !_loading && _rows.isNotEmpty) ...[
              const SizedBox(height: 22),
              Row(children: [
                _SectionLabel('$_selectedTable'),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedTable = null;
                    _rows = [];
                    _columns = [];
                  }),
                  child: const Icon(Icons.close_rounded, color: T.t3, size: 18),
                ),
              ]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                      color: T.white,
                      borderRadius: BorderRadius.circular(T.r2),
                      border: Border.all(color: T.border)),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(T.bg),
                    border: TableBorder.all(color: T.border, width: 1),
                    columns: _columns
                        .map((c) => DataColumn(
                            label: Text(c,
                                style: const TextStyle(
                                    color: T.t1,
                                    fontWeight: FontWeight.w700,
                                    fontSize: T.fontSm))))
                        .toList(),
                    rows: _rows
                        .map((row) => DataRow(
                            cells: _columns
                                .map((c) => DataCell(Text(
                                    row[c]?.toString() ?? '',
                                    style: const TextStyle(
                                        color: T.t2, fontSize: T.fontSm))))
                                .toList()))
                        .toList(),
                  ),
                ),
              ),
            ],
          ]),
    );
  }
}

class _TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  final bool isSelected;
  final VoidCallback onTap;
  const _TableCard(
      {required this.table,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: isSelected ? T.accentLight : T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border:
                    Border.all(color: isSelected ? T.accent : T.border)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: isSelected ? T.accentMid : T.accentLight,
                    borderRadius: BorderRadius.circular(T.r1)),
                child: Icon(Icons.table_rows_rounded,
                    color: T.accent, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(table['name'] ?? '',
                        style: const TextStyle(
                            color: T.t1,
                            fontSize: T.fontMd,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        '${(table['columns'] as List?)?.length ?? 0} columns · ${table['row_count']} rows',
                        style: const TextStyle(
                            color: T.t3, fontSize: T.fontSm)),
                  ])),
              Icon(
                  isSelected
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected ? T.accent : T.t3,
                  size: 20),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
// QUERY SCREEN
// ─────────────────────────────────────────────
class QueryScreen extends StatefulWidget {
  final DbState db;
  const QueryScreen({super.key, required this.db});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _showSql = false;
  String _sql = '';
  List<String> _columns = [];
  List<Map<String, dynamic>> _rows = [];
  String _error = '';

  final _suggestions = const [
    'Show all records from student_details',
    'Find entries with marks above 90',
    'Count total records by category',
    'Get the latest 10 entries',
  ];

  Future<void> _runQuery() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _sql = '';
      _columns = [];
      _rows = [];
      _error = '';
    });
    final result = await ApiService.nlToSql(q);
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _sql = result['sql'] ?? '';
        _columns = List<String>.from(result['columns'] ?? []);
        _rows = List<Map<String, dynamic>>.from(result['rows'] ?? []);
      } else {
        _error = result['error'] ?? 'Unknown error';
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Query',
                style: TextStyle(
                    color: T.t1,
                    fontSize: T.font2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6)),
            const SizedBox(height: 3),
            Text('Ask in plain English',
                style: TextStyle(
                    color: T.t2.withValues(alpha: 0.8),
                    fontSize: T.fontBase)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]),
              child: Column(children: [
                TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(color: T.t1, fontSize: T.fontMd),
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. "Show all students with marks above 80"',
                    hintStyle: TextStyle(color: T.t4, fontSize: T.fontBase),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: T.border))),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showSql = !_showSql),
                      child: Row(children: [
                        Icon(
                            _showSql
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            color: _showSql ? T.accent : T.t3,
                            size: 22),
                        const SizedBox(width: 6),
                        Text('Show SQL',
                            style: TextStyle(
                                fontSize: T.fontSm,
                                fontWeight: FontWeight.w500,
                                color: _showSql ? T.accent : T.t2)),
                      ]),
                    ),
                    const Spacer(),
                    _Btn(
                        label: _loading ? 'Running…' : 'Run Query',
                        onTap: _loading ? null : _runQuery,
                        small: true),
                  ]),
                ),
              ]),
            ),
            if (_showSql && _sql.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SqlBlock(sql: _sql),
            ],
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: T.dangerLight,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(
                        color: T.danger.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: T.danger, size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error,
                          style: const TextStyle(
                              color: T.danger, fontSize: T.fontBase))),
                ]),
              ),
            ],
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(color: T.accent))),
            if (_rows.isNotEmpty && !_loading) ...[
              const SizedBox(height: 22),
              Row(children: [
                const _SectionLabel('Results'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: T.successLight,
                      borderRadius: BorderRadius.circular(T.r4),
                      border: Border.all(
                          color: T.success.withValues(alpha: 0.3))),
                  child: Text('${_rows.length} rows',
                      style: const TextStyle(
                          color: T.success,
                          fontSize: T.fontSm,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                      color: T.white,
                      borderRadius: BorderRadius.circular(T.r2),
                      border: Border.all(color: T.border)),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(T.bg),
                    border: TableBorder.all(color: T.border, width: 1),
                    columns: _columns
                        .map((c) => DataColumn(
                            label: Text(c,
                                style: const TextStyle(
                                    color: T.t1,
                                    fontWeight: FontWeight.w700,
                                    fontSize: T.fontSm))))
                        .toList(),
                    rows: _rows
                        .map((row) => DataRow(
                            cells: _columns
                                .map((c) => DataCell(Text(
                                    row[c]?.toString() ?? '',
                                    style: const TextStyle(
                                        color: T.t2, fontSize: T.fontSm))))
                                .toList()))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            const _SectionLabel('Try asking'),
            const SizedBox(height: 10),
            ..._suggestions.map((s) => _SuggestionRow(
                text: s,
                onTap: () => setState(() => _ctrl.text = s))),
            if (_rows.isEmpty && !_loading && _error.isEmpty) ...[
              const SizedBox(height: 22),
              const _SectionLabel('Results'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                    color: T.white,
                    borderRadius: BorderRadius.circular(T.r2),
                    border: Border.all(color: T.border)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: T.accentLight, shape: BoxShape.circle),
                    child: const Icon(Icons.search_rounded,
                        color: T.accent, size: 26),
                  ),
                  const SizedBox(height: 14),
                  const Text('No results yet',
                      style: TextStyle(
                          color: T.t1,
                          fontSize: T.fontLg,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Run a query to see data here',
                      style: TextStyle(color: T.t3, fontSize: T.fontBase)),
                ]),
              ),
            ],
          ]),
    );
  }
}


// ─────────────────────────────────────────────
// ANALYTICS SCREEN
// ─────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> _summary = {};
  List<dynamic> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    final summary = await ApiService.getAnalyticsSummary();
    final logs = await ApiService.getAnalyticsLogs();
    setState(() {
      _loading = false;
      if (summary['success'] == true) _summary = summary;
      if (logs['success'] == true) _logs = logs['logs'] ?? [];
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Analytics',
              style: TextStyle(
                  color: T.t1,
                  fontSize: T.font2xl,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6)),
          const Spacer(),
          _SmallBtn(icon: Icons.refresh_rounded, label: 'Refresh', onTap: _loadAnalytics),
        ]),
        const SizedBox(height: 3),
        Text('Extraction metrics & system logs',
            style: TextStyle(color: T.t2.withValues(alpha: 0.8), fontSize: T.fontBase)),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: T.accent)))
        else ...[
          // ── Summary Cards ──
          const _SectionLabel('Overview'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _AnalyticCard(
              label: 'Total Extractions',
              value: '${_summary['total_extractions'] ?? 0}',
              icon: Icons.upload_rounded,
              color: T.accent)),
            const SizedBox(width: 10),
            Expanded(child: _AnalyticCard(
              label: 'Anomalies Caught',
              value: '${_summary['anomalies_caught'] ?? 0}',
              icon: Icons.warning_amber_rounded,
              color: T.danger)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _AnalyticCard(
              label: 'Avg Confidence',
              value: '${_summary['avg_confidence'] ?? 0}%',
              icon: Icons.verified_rounded,
              color: T.success)),
            const SizedBox(width: 10),
            Expanded(child: _AnalyticCard(
              label: 'Avg Process Time',
              value: '${_summary['avg_processing_time'] ?? 0}s',
              icon: Icons.timer_outlined,
              color: T.warning)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _AnalyticCard(
              label: 'Avg Accuracy',
              value: '${_summary['avg_accuracy'] ?? 0}%',
              icon: Icons.analytics_rounded,
              color: const Color(0xFF7C3AED))),
            const SizedBox(width: 10),
            Expanded(child: _AnalyticCard(
              label: 'Schema Generations',
              value: '${(_logs.where((l) => l['event_type'] == 'schema_generation').length)}',
              icon: Icons.schema_outlined,
              color: const Color(0xFF0891B2))),
          ]),

          // ── By Source ──
          if ((_summary['by_source'] as Map?)?.isNotEmpty == true) ...[
            const SizedBox(height: 22),
            const _SectionLabel('Extractions by Source'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: Column(
                children: (_summary['by_source'] as Map).entries.map((e) {
                  final total = (_summary['total_extractions'] as int?) ?? 1;
                  final count = e.value as int;
                  final pct = total > 0 ? count / total : 0.0;
                  final colors = {
                    'image': T.accent,
                    'voice': const Color(0xFF7C3AED),
                    'document': T.warning,
                    'spreadsheet': T.success,
                  };
                  final color = colors[e.key] ?? T.t3;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(e.key.toString().toUpperCase(),
                            style: TextStyle(color: color, fontSize: T.fontSm, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('$count extractions',
                            style: const TextStyle(color: T.t2, fontSize: T.fontSm)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(T.r4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          backgroundColor: T.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Anomaly Log ──
          const SizedBox(height: 22),
          const _SectionLabel('Anomaly Log'),
          const SizedBox(height: 10),
          ...(_logs.where((l) => l['event_type'] == 'anomaly').take(10).map((log) {
            final details = log['details'] as Map;
            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: T.dangerLight,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.danger.withValues(alpha: 0.25))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: T.danger, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${details['field']} = ${details['value']}',
                      style: const TextStyle(color: T.danger, fontSize: T.fontBase, fontWeight: FontWeight.w600)),
                  Text(details['reason']?.toString() ?? '',
                      style: const TextStyle(color: T.t2, fontSize: T.fontSm)),
                ])),
                Text(log['timestamp']?.toString().substring(0, 16) ?? '',
                    style: const TextStyle(color: T.t3, fontSize: 10)),
              ]),
            );
          })).toList(),

          if (_logs.where((l) => l['event_type'] == 'anomaly').isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: const Column(children: [
                Icon(Icons.check_circle_outline_rounded, color: T.success, size: 28),
                SizedBox(height: 8),
                Text('No anomalies detected', style: TextStyle(color: T.t1, fontWeight: FontWeight.w600, fontSize: T.fontMd)),
                Text('All extracted data passed validation', style: TextStyle(color: T.t3, fontSize: T.fontBase)),
              ]),
            ),

          // ── Recent Activity ──
          const SizedBox(height: 22),
          const _SectionLabel('Recent Activity'),
          const SizedBox(height: 10),
          ..._logs.take(8).map((log) {
            final type = log['event_type'] as String;
            final details = log['details'] as Map;
            final icons = {
              'extraction': Icons.upload_rounded,
              'schema_generation': Icons.schema_outlined,
              'anomaly': Icons.warning_amber_rounded,
              'save': Icons.save_rounded,
            };
            final colors = {
              'extraction': T.accent,
              'schema_generation': const Color(0xFF7C3AED),
              'anomaly': T.danger,
              'save': T.success,
            };
            final labels = {
              'extraction': 'Extracted from ${details['source'] ?? 'unknown'}',
              'schema_generation': 'Schema generated (${details['fields_count'] ?? 0} fields)',
              'anomaly': 'Anomaly: ${details['field']} = ${details['value']}',
              'save': 'Saved to ${details['table'] ?? 'table'} (${details['accuracy']}% accuracy)',
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: (colors[type] ?? T.t3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(T.r1)),
                  child: Icon(icons[type] ?? Icons.info_outline_rounded,
                      color: colors[type] ?? T.t3, size: 14)),
                const SizedBox(width: 10),
                Expanded(child: Text(labels[type] ?? type,
                    style: const TextStyle(color: T.t1, fontSize: T.fontBase))),
                Text(log['timestamp']?.toString().substring(0, 16) ?? '',
                    style: const TextStyle(color: T.t3, fontSize: 10)),
              ]),
            );
          }).toList(),
        ],
      ]),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        border: Border.all(color: T.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(T.r1)),
        child: Icon(icon, color: color, size: 15)),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(color: T.t1, fontSize: T.fontXl, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: T.t3, fontSize: T.fontSm)),
    ]),
  );
}

// ─────────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final DbState db;
  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool _validate = true;
  bool _confidence = true;
  bool _autoSchema = true;
  double _threshold = 0.7;

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(
                    color: T.t1,
                    fontSize: T.font2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6)),
            const SizedBox(height: 3),
            Text('APIs & preferences',
                style: TextStyle(
                    color: T.t2.withValues(alpha: 0.8),
                    fontSize: T.fontBase)),
            const SizedBox(height: 22),
            const _SectionLabel('API Keys'),
            const SizedBox(height: 10),
            _KeyTile(
                icon: Icons.auto_awesome_rounded,
                iconBg: T.accentLight,
                iconColor: T.accent,
                title: 'Groq API Key',
                sub: 'Schema generation, NL→SQL & Voice'),
            _KeyTile(
                icon: Icons.image_search_rounded,
                iconBg: T.warningLight,
                iconColor: T.warning,
                title: 'Google Vision API Key',
                sub: 'Enhanced image OCR (optional)'),
            const SizedBox(height: 22),
            const _SectionLabel('Extraction'),
            const SizedBox(height: 10),
            _ToggleRow(
                icon: Icons.schema_outlined,
                iconBg: T.successLight,
                iconColor: T.success,
                title: 'Auto Schema Generation',
                sub: 'Create tables from extracted data',
                value: _autoSchema,
                onChanged: (v) => setState(() => _autoSchema = v)),
            _ToggleRow(
                icon: Icons.verified_outlined,
                iconBg: T.accentLight,
                iconColor: T.accent,
                title: 'Intelligent Validation',
                sub: 'Flag anomalies and invalid values',
                value: _validate,
                onChanged: (v) => setState(() => _validate = v)),
            _ToggleRow(
                icon: Icons.percent_rounded,
                iconBg: T.warningLight,
                iconColor: T.warning,
                title: 'Confidence Scores',
                sub: 'Show reliability of each field',
                value: _confidence,
                onChanged: (v) => setState(() => _confidence = v)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Confidence Threshold',
                          style: TextStyle(
                              color: T.t1,
                              fontSize: T.fontMd,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: T.accentLight,
                            borderRadius: BorderRadius.circular(T.r4)),
                        child: Text('${(_threshold * 100).round()}%',
                            style: const TextStyle(
                                color: T.accent,
                                fontSize: T.fontSm,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    const Text('Verify fields below this confidence level',
                        style: TextStyle(color: T.t3, fontSize: T.fontSm)),
                    SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                          activeTrackColor: T.accent,
                          inactiveTrackColor: T.border,
                          thumbColor: T.accent,
                          overlayColor: T.accentLight,
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7)),
                      child: Slider(
                          value: _threshold,
                          min: 0.5,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (v) =>
                              setState(() => _threshold = v)),
                    ),
                  ]),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('About'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: T.white,
                  borderRadius: BorderRadius.circular(T.r2),
                  border: Border.all(color: T.border)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF3B6FE8),
                        Color(0xFF6B47DC)
                      ]),
                      borderRadius: BorderRadius.circular(T.r1)),
                  child: const Icon(Icons.hub_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DataBridge v1.0.0',
                          style: TextStyle(
                              color: T.t1,
                              fontSize: T.fontMd,
                              fontWeight: FontWeight.w700)),
                      Text('Multimodal Database Management',
                          style:
                              TextStyle(color: T.t3, fontSize: T.fontSm)),
                    ]),
              ]),
            ),
          ]),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext ctx) => Text(text.toUpperCase(),
      style: const TextStyle(
          color: T.t3,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5));
}

class _InputTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback? onTap;
  const _InputTile(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap ?? () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(T.r1)),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(height: 16),
                  Text(label,
                      style: const TextStyle(
                          color: T.t1,
                          fontSize: T.fontMd,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style:
                          const TextStyle(color: T.t3, fontSize: T.fontSm)),
                ]),
          ),
        ),
      );
}

class _InputTileFull extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback? onTap;
  const _InputTileFull(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap ?? () {},
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(T.r1)),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.fontMd,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style:
                        const TextStyle(color: T.t3, fontSize: T.fontSm)),
              ]),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: T.t3, size: 20),
            ]),
          ),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(T.r1)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: T.t1,
                  fontSize: T.fontXl,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: T.t3, fontSize: T.fontSm)),
        ]),
      );
}

class _SqlBlock extends StatelessWidget {
  final String sql;
  const _SqlBlock({required this.sql});

  @override
  Widget build(BuildContext ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(T.r2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: T.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(T.r1)),
              child: const Text('SQL',
                  style: TextStyle(
                      color: Color(0xFF7DD3FC),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(sql,
              style: const TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: T.fontBase,
                  fontFamily: 'monospace',
                  height: 1.6)),
        ]),
      );
}

class _SuggestionRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.white,
        borderRadius: BorderRadius.circular(T.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r2),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r2),
                border: Border.all(color: T.border)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: T.accentLight,
                    borderRadius: BorderRadius.circular(T.r1)),
                child: const Icon(Icons.north_west_rounded,
                    color: T.accent, size: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style:
                          const TextStyle(color: T.t2, fontSize: T.fontBase))),
            ]),
          ),
        ),
      );
}

class _KeyTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String sub;
  const _KeyTile(
      {required this.icon,
      required this.iconBg,
      required this.iconColor,
      required this.title,
      required this.sub});

  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(T.r1)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.fontBase,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(color: T.t3, fontSize: T.fontSm)),
              ])),
          _SmallBtn(icon: Icons.edit_rounded, label: 'Set', onTap: () {}),
        ]),
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.icon,
      required this.iconBg,
      required this.iconColor,
      required this.title,
      required this.sub,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: T.white,
            borderRadius: BorderRadius.circular(T.r2),
            border: Border.all(color: T.border)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(T.r1)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: T.t1,
                        fontSize: T.fontBase,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(color: T.t3, fontSize: T.fontSm)),
              ])),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: T.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: T.border,
            ),
          ),
        ]),
      );
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final bool danger;
  final bool small;
  const _Btn(
      {required this.label,
      required this.onTap,
      this.outline = false,
      this.danger = false,
      this.small = false});

  @override
  Widget build(BuildContext ctx) {
    final bg = outline
        ? Colors.transparent
        : danger
            ? T.danger
            : T.accent;
    final fg = outline
        ? danger
            ? T.danger
            : T.accent
        : Colors.white;
    final side = outline
        ? BorderSide(
            color: danger
                ? T.danger.withValues(alpha: 0.4)
                : T.accent.withValues(alpha: 0.4))
        : BorderSide.none;

    return Material(
      color: onTap == null ? T.bg : bg,
      borderRadius: BorderRadius.circular(T.r1),
      child: InkWell(
        borderRadius: BorderRadius.circular(T.r1),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : 20, vertical: small ? 9 : 13),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.r1),
              border: Border.fromBorderSide(side)),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: onTap == null ? T.t3 : fg,
                    fontSize: small ? T.fontSm : T.fontBase,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Material(
        color: T.bg,
        borderRadius: BorderRadius.circular(T.r1),
        child: InkWell(
          borderRadius: BorderRadius.circular(T.r1),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.r1),
                border: Border.all(color: T.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: T.t2, size: 13),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: T.t2,
                      fontSize: T.fontSm,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}