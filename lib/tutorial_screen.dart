import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
//  TutorialScreen — tabs: Documents | Videos
// ─────────────────────────────────────────────────────────────────────────────
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search & filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLevel;
  String? _selectedSemester;

  static const List<String> _levels = ['100', '200', '300', '400'];
  static const List<String> _semesters = ['First Semester', 'Second Semester'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getFileType(String url) {
    final path = Uri.parse(url).path.toLowerCase();
    if (path.contains('.pdf'))  return 'pdf';
    if (path.contains('.doc'))  return 'doc';
    if (path.contains('.xls') || path.contains('.xlsx')) return 'excel';
    if (path.contains('.ppt') || path.contains('.pptx')) return 'ppt';
    if (path.contains('.txt'))  return 'txt';
    if (path.contains('.jpg')  || path.contains('.jpeg') ||
        path.contains('.png')  || path.contains('.gif')  ||
        path.contains('.webp') || path.contains('.bmp'))  return 'image';
    if (url.contains('/raw/upload/')) return 'pdf';
    if (url.contains('/video/upload/')) return 'video';
    if (url.contains('/image/upload/')) return 'image';
    return 'doc';
  }

  void _openDocument(String url, String title) {
    final fileType = _getFileType(url);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(url: url, title: title, fileType: fileType),
      ),
    );
  }

  void _openVideo(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url, title: title)),
    );
  }

  IconData _fileIcon(String url) {
    final t = _getFileType(url);
    switch (t) {
      case 'doc':   return Icons.description_outlined;
      case 'excel': return Icons.table_chart_outlined;
      case 'ppt':   return Icons.slideshow_outlined;
      case 'image': return Icons.image_outlined;
      case 'txt':   return Icons.text_snippet_outlined;
      default:      return Icons.picture_as_pdf_outlined;
    }
  }

  // ── Filter logic ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final title    = (item['title']       ?? '').toString().toLowerCase();
      final course   = (item['courseName']  ?? '').toString().toLowerCase();
      final desc     = (item['description'] ?? '').toString().toLowerCase();
      final level    = (item['level']       ?? '').toString();
      final semester = (item['semester']    ?? '').toString().toLowerCase();

      if (_searchQuery.isNotEmpty) {
        if (!title.contains(_searchQuery) &&
            !course.contains(_searchQuery) &&
            !desc.contains(_searchQuery)) return false;
      }

      if (_selectedLevel != null) {
        if (!level.contains(_selectedLevel!)) return false;
      }

      if (_selectedSemester != null) {
        final key = _selectedSemester!.toLowerCase().contains('first') ? 'first' : 'second';
        if (!semester.contains(key)) return false;
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedLevel != null || _selectedSemester != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedLevel = null;
      _selectedSemester = null;
    });
  }

  // ── Search + filter bar ──────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, course, description...',
                hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF999999), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 20),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                // Level chips
                ..._levels.map((lvl) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: 'Lvl $lvl',
                    selected: _selectedLevel == lvl,
                    onTap: () => setState(() =>
                        _selectedLevel = _selectedLevel == lvl ? null : lvl),
                  ),
                )),
                Container(width: 1, height: 22, color: const Color(0xFFE0E0E0),
                    margin: const EdgeInsets.only(right: 8)),
                // Semester chips
                ..._semesters.map((sem) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: sem,
                    selected: _selectedSemester == sem,
                    onTap: () => setState(() =>
                        _selectedSemester = _selectedSemester == sem ? null : sem),
                  ),
                )),
                // Clear all
                if (_hasActiveFilters)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE75480).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE75480).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, size: 13, color: Color(0xFFE75480)),
                          SizedBox(width: 4),
                          Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFFE75480), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / no-results states ────────────────────────────────────────────

  Widget _noResults() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 14),
          const Text('No results match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _clearFilters,
            child: const Text('Clear filters',
                style: TextStyle(color: Color(0xFFE75480), fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    ),
  );

  // ── Item cards ───────────────────────────────────────────────────────────

  Widget _buildDocItem(Map<String, dynamic> doc) {
    final title    = doc['title']       ?? 'Untitled Document';
    final course   = doc['courseName']  ?? '';
    final level    = doc['level']       ?? '';
    final semester = doc['semester']    ?? '';
    final desc     = doc['description'] ?? '';
    final date     = doc['createdAt'] != null
        ? DateFormat('MMM d, yyyy').format((doc['createdAt'] as dynamic).toDate())
        : '';
    final url = doc['fileUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDocument(url, title),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE75480).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_fileIcon(url), color: const Color(0xFFE75480), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins', color: Color(0xFF333333)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (course.isNotEmpty || level.isNotEmpty)
                      Text(
                        [if (course.isNotEmpty) course, if (level.isNotEmpty) '$level Level', if (semester.isNotEmpty) semester].join(' · '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final title    = video['title']       ?? 'Untitled Video';
    final course   = video['courseName']  ?? '';
    final level    = video['level']       ?? '';
    final semester = video['semester']    ?? '';
    final desc     = video['description'] ?? '';
    final date     = video['createdAt'] != null
        ? DateFormat('MMM d, yyyy').format((video['createdAt'] as dynamic).toDate())
        : '';
    final url = video['fileUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openVideo(url, title),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE75480).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFE75480), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins', color: Color(0xFF333333)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (course.isNotEmpty || level.isNotEmpty)
                      Text(
                        [if (course.isNotEmpty) course, if (level.isNotEmpty) '$level Level', if (semester.isNotEmpty) semester].join(' · '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab body builders ────────────────────────────────────────────────────

  Widget _buildDocTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('Courses').orderBy('createdAt', descending: true).snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE75480)));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No documents available yet.', textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
                  ),
                );
              }
              final docs = snap.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();
              final filtered = _applyFilters(docs);
              if (filtered.isEmpty) return _noResults();
              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildDocItem(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('Videos').orderBy('createdAt', descending: true).snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE75480)));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No videos available yet.', textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF999999), fontSize: 15)),
                  ),
                );
              }
              final videos = snap.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();
              final filtered = _applyFilters(videos);
              if (filtered.isEmpty) return _noResults();
              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildVideoItem(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Scaffold ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tutorials',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, fontFamily: 'Poppins', color: Color(0xFF333333))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE75480),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE75480),
          unselectedLabelColor: const Color(0xFF999999),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14),
          tabs: const [Tab(text: 'Documents'), Tab(text: 'Videos')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocTab(),
          _buildVideoTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable filter chip
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE75480).withValues(alpha: 0.12)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFE75480) : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color: selected ? const Color(0xFFE75480) : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
//  DocumentViewerScreen — PDF / Office / Image / Text
// ─────────────────────────────────────────────────────────────────────────────
class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String fileType;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.fileType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {

  // ── PDF state ─────────────────────────────────────
  late final PdfViewerController _pdfCtrl;
  bool _pdfLoading = true;
  bool _pdfError   = false;
  String _pdfErrorMsg = '';
  int  _curPage    = 1;
  int  _totalPages = 0;
  double _zoom     = 1.0;

  // Controls auto-hide
  bool   _showControls = true;
  Timer? _hideTimer;

  // ── WebView state ─────────────────────────────────
  WebViewController? _webCtrl;
  int  _webProgress = 0;
  bool _webLoading  = true;
  bool _webError    = false;

  // ── Text viewer state ─────────────────────────────
  bool   _txtLoading = true;
  bool   _txtError   = false;
  String _txtContent = '';
  double _fontSize   = 15.0;

  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    switch (widget.fileType) {
      case 'txt':   _loadText();    break;
      case 'pdf':   /* loaded by SfPdfViewer */ break;
      case 'image': /* loaded by Image.network */ break;
      default:      _initWebView(); break;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  // ── PDF controls visibility ───────────────────────
  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _bringUpControls() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _scheduleHide();
  }

  void _toggleControls() {
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      _bringUpControls();
    }
  }

  // ── WebView init ──────────────────────────────────
  void _initWebView() {
    // Google Docs Viewer renders DOC, DOCX, XLS, XLSX, PPT, PPTX, PDF
    final viewerUrl =
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.url)}&embedded=true';

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress:    (p) => setState(() => _webProgress = p),
        onPageStarted: (_) => setState(() { _webLoading = true; _webError = false; }),
        onPageFinished:(_) => setState(() => _webLoading = false),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? false) setState(() => _webError = true);
        },
      ))
      ..loadRequest(Uri.parse(viewerUrl));
  }

  // ── Text fetch ────────────────────────────────────
  Future<void> _loadText() async {
    try {
      final resp = await http.get(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        setState(() { _txtContent = resp.body; _txtLoading = false; });
      } else {
        throw Exception('Server returned ${resp.statusCode}');
      }
    } catch (e) {
      setState(() { _txtLoading = false; _txtError = true; });
    }
  }

  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    switch (widget.fileType) {
      case 'pdf':   return _pdfError  ? _errorScaffold(_pdfErrorMsg) : _pdfScaffold();
      case 'image': return _imageScaffold();
      case 'txt':   return _txtError  ? _errorScaffold('Failed to load file.') : _txtScaffold();
      default:      return _webError  ? _errorScaffold('Document viewer could not load this file.') : _webScaffold();
    }
  }

  // ══════════════════════════════════════════════════
  // PDF Viewer
  // ══════════════════════════════════════════════════
  Widget _pdfScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFF12122A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_totalPages > 0)
              Text('Page $_curPage of $_totalPages',
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE75480).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE75480).withValues(alpha: 0.5)),
                  ),
                  child: Text('$_curPage / $_totalPages',
                    style: const TextStyle(color: Color(0xFFE75480), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // ── PDF content ──────────────────────────
            SfPdfViewer.network(
              widget.url,
              controller: _pdfCtrl,
              headers: const {'Accept': 'application/pdf, application/octet-stream, */*'},
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              enableDoubleTapZooming: true,
              enableTextSelection: false,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
              onDocumentLoaded: (d) {
                setState(() {
                  _totalPages = d.document.pages.count;
                  _pdfLoading = false;
                });
                _scheduleHide();
              },
              onPageChanged: (d) => setState(() => _curPage = d.newPageNumber),
              onZoomLevelChanged: (d) => setState(() => _zoom = d.newZoomLevel),
              onDocumentLoadFailed: (d) => setState(() {
                _pdfLoading = false;
                _pdfError   = true;
                _pdfErrorMsg = d.description;
              }),
            ),

            // ── Loading overlay ───────────────────────
            if (_pdfLoading) _pdfLoadingOverlay(),

            // ── Bottom controls ───────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 280),
                  child: _pdfControls(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfLoadingOverlay() => Container(
    color: const Color(0xFF12122A),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 62, height: 62,
            child: CircularProgressIndicator(
              color: const Color(0xFFE75480),
              strokeWidth: 3.5,
              backgroundColor: const Color(0xFFE75480).withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Loading document…',
            style: TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          const Text('Please wait', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    ),
  );

  Widget _pdfControls() {
    if (_totalPages == 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, -5))],
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 44, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // ── Page nav row ─────────────────────────────
          Row(
            children: [
              _navBtn(Icons.first_page_rounded,  () { _pdfCtrl.jumpToPage(1); _bringUpControls(); }, disabled: _curPage <= 1),
              const SizedBox(width: 3),
              _navBtn(Icons.chevron_left_rounded, () { _pdfCtrl.previousPage(); _bringUpControls(); }, disabled: _curPage <= 1, sz: 28),

              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
                        activeTrackColor: const Color(0xFFE75480),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xFFE75480),
                        overlayColor: const Color(0xFFE75480).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _curPage.clamp(1, _totalPages).toDouble(),
                        min: 1,
                        max: _totalPages.toDouble(),
                        divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                        onChanged: (v) {
                          final p = v.round();
                          setState(() => _curPage = p);
                          _pdfCtrl.jumpToPage(p);
                          _bringUpControls();
                        },
                      ),
                    ),
                    Text('$_curPage of $_totalPages pages',
                      style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              _navBtn(Icons.chevron_right_rounded, () { _pdfCtrl.nextPage(); _bringUpControls(); }, disabled: _curPage >= _totalPages, sz: 28),
              const SizedBox(width: 3),
              _navBtn(Icons.last_page_rounded,  () { _pdfCtrl.jumpToPage(_totalPages); _bringUpControls(); }, disabled: _curPage >= _totalPages),
            ],
          ),
          const SizedBox(height: 12),

          // ── Zoom + Go-to-page row ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zoom out
              _navBtn(Icons.remove_rounded, () {
                final z = (_zoom - 0.25).clamp(0.5, 3.0);
                _pdfCtrl.zoomLevel = z; setState(() => _zoom = z); _bringUpControls();
              }, small: true),
              const SizedBox(width: 7),
              // Zoom level pill (tap resets to 100%)
              GestureDetector(
                onTap: () { _pdfCtrl.zoomLevel = 1.0; setState(() => _zoom = 1.0); _bringUpControls(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: Text('${(_zoom * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 7),
              // Zoom in
              _navBtn(Icons.add_rounded, () {
                final z = (_zoom + 0.25).clamp(0.5, 3.0);
                _pdfCtrl.zoomLevel = z; setState(() => _zoom = z); _bringUpControls();
              }, small: true),

              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.20)),
              const SizedBox(width: 16),

              // Go to page
              GestureDetector(
                onTap: _showGoToPageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE75480).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFE75480).withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined, color: Color(0xFFE75480), size: 15),
                      SizedBox(width: 7),
                      Text('Go to page',
                        style: TextStyle(color: Color(0xFFE75480), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap, {bool disabled = false, double sz = 22, bool small = false}) {
    final dim = small ? 34.0 : 40.0;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: dim, height: dim,
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : Colors.white10,
          borderRadius: BorderRadius.circular(small ? 9 : 11),
          border: Border.all(color: disabled ? Colors.white10 : Colors.white24),
        ),
        child: Icon(icon, color: disabled ? Colors.white.withValues(alpha: 0.20) : Colors.white70, size: sz),
      ),
    );
  }

  void _showGoToPageDialog() {
    _hideTimer?.cancel();
    final ctrl = TextEditingController(text: '$_curPage');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Go to Page',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('Enter a number between 1 and $_totalPages',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  hintText: '—',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE75480), width: 2)),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () { Navigator.pop(ctx); _scheduleHide(); },
                      style: TextButton.styleFrom(foregroundColor: Colors.white54),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final p = int.tryParse(ctrl.text.trim());
                        if (p != null && p >= 1 && p <= _totalPages) {
                          _pdfCtrl.jumpToPage(p);
                          setState(() => _curPage = p);
                        }
                        Navigator.pop(ctx);
                        _scheduleHide();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE75480),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Go', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // WebView Viewer (DOC / DOCX / XLS / XLSX / PPT / PPTX)
  // ══════════════════════════════════════════════════
  Widget _webScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333), fontFamily: 'Poppins'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_fileTypeLabel(),
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF666666)),
            onPressed: () => _webCtrl?.reload(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _webLoading
              ? LinearProgressIndicator(
                  value: _webProgress > 0 ? _webProgress / 100 : null,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFE75480)),
                  minHeight: 3,
                )
              : const SizedBox(height: 3),
        ),
      ),
      body: _webCtrl == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE75480)))
          : WebViewWidget(controller: _webCtrl!),
    );
  }

  String _fileTypeLabel() {
    switch (widget.fileType) {
      case 'doc':   return 'Word Document';
      case 'excel': return 'Excel Spreadsheet';
      case 'ppt':   return 'PowerPoint Presentation';
      default:      return 'Document';
    }
  }

  // ══════════════════════════════════════════════════
  // Image Viewer
  // ══════════════════════════════════════════════════
  Widget _imageScaffold() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: Text('Pinch to zoom', style: TextStyle(color: Colors.white38, fontSize: 11))),
          ),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.4,
        maxScale: 6.0,
        child: Center(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFE75480),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('Could not load image', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // Text Viewer
  // ══════════════════════════════════════════════════
  Widget _txtScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333), fontFamily: 'Poppins'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF666666)),
                onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(10, 30)),
              ),
              Text('${_fontSize.round()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF666666)),
                onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(10, 30)),
              ),
            ],
          ),
        ],
      ),
      body: _txtLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE75480)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Text(_txtContent,
                style: TextStyle(fontSize: _fontSize, height: 1.75, color: const Color(0xFF333333), fontFamily: 'Inter')),
            ),
    );
  }

  // ══════════════════════════════════════════════════
  // Error Scaffold (shared)
  // ══════════════════════════════════════════════════
  Widget _errorScaffold(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333), fontFamily: 'Poppins'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFE74C3C)),
              ),
              const SizedBox(height: 22),
              const Text('Could Not Open Document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333), fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(message.isNotEmpty ? message : 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  switch (widget.fileType) {
                    case 'pdf':
                      setState(() { _pdfError = false; _pdfLoading = true; });
                      break;
                    case 'txt':
                      setState(() { _txtError = false; _txtLoading = true; });
                      _loadText();
                      break;
                    default:
                      setState(() { _webError = false; _webLoading = true; _webProgress = 0; });
                      _initWebView();
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE75480),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
//  VideoPlayerScreen
// ─────────────────────────────────────────────────────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoCtrl.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE75480),
          handleColor: const Color(0xFFE75480),
          backgroundColor: Colors.white24,
          bufferedColor: const Color(0xFFE75480).withValues(alpha: 0.3),
        ),
        errorBuilder: (ctx, msg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: Colors.white54),
              const SizedBox(height: 12),
              Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFFE75480))
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 60, color: Colors.white38),
                        const SizedBox(height: 16),
                        const Text('Could Not Play Video',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white70, fontFamily: 'Poppins')),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.white38, height: 1.5)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initPlayer,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE75480),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  )
                : _chewieCtrl != null
                    ? Chewie(controller: _chewieCtrl!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}
