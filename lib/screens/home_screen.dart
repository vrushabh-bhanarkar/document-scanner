import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../providers/document_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/advanced_scanner_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'id_card_scan_screen.dart';
import 'paywall_screen.dart';
import 'scan_screen.dart';
import 'signature_screen.dart';

/// Production SleekScan Dashboard Screen
/// - Dark Slate & Indigo Palette
/// - Header with active tier status badge (FREE vs PRO)
/// - Client-side search bar filtering document titles and OCR text
/// - Action Hub for "Smart Scan", "ID Card Mode", "Batch Scan", and "Gallery Import"
/// - Document cards with thumbnail preview, date, size, page count, direct share action
/// - 3-dot bottom sheet (Rename, Sign, Encrypt, Cloud Sync, Delete)
/// - Zero-state illustration when no scans exist
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PdfExportService _pdfExportService = PdfExportService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final AdvancedScannerService _advancedScanner = AdvancedScannerService();
  final ImagePicker _imagePicker = ImagePicker();

  String _searchQuery = '';
  bool _isActionProcessing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentModel> _filterDocuments(List<DocumentModel> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((doc) {
      final titleMatch = doc.name.toLowerCase().contains(_searchQuery);
      final textMatch = (doc.extractedText ?? '').toLowerCase().contains(_searchQuery);
      return titleMatch || textMatch;
    }).toList();
  }

  Future<void> _handleSmartScan() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  Future<void> _handleIdCardMode() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IdCardScanScreen()),
    );
  }

  Future<void> _handleBatchScan() async {
    setState(() => _isActionProcessing = true);
    try {
      final List<File> files = await _advancedScanner.scanDocuments(
        pageLimit: 50,
        isGalleryImport: false,
      );

      if (files.isEmpty) {
        setState(() => _isActionProcessing = false);
        return;
      }

      final isPro = context.read<SubscriptionProvider>().isPro;
      final ocrText = await _pdfExportService.extractTextFromPages(files);
      final pdf = await _pdfExportService.generatePdf(
        imageFiles: files,
        fileName: 'Batch_Scan_${DateTime.now().millisecondsSinceEpoch}',
        isProUser: isPro,
      );

      final docProvider = context.read<DocumentProvider>();
      await docProvider.createDocument(
        name: 'Batch_Scan_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: files.first.path,
        pdfPath: pdf.path,
        extractedText: ocrText,
        pageImagePaths: files.map((f) => f.path).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully scanned ${files.length} pages!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BatchScan] Error: $e');
    } finally {
      if (mounted) setState(() => _isActionProcessing = false);
    }
  }

  Future<void> _handleGalleryImport() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 90,
      );
      if (pickedFiles.isEmpty) return;

      setState(() => _isActionProcessing = true);

      final files = pickedFiles.map((x) => File(x.path)).toList();
      final isPro = context.read<SubscriptionProvider>().isPro;
      final ocrText = await _pdfExportService.extractTextFromPages(files);
      final pdf = await _pdfExportService.generatePdf(
        imageFiles: files,
        fileName: 'Gallery_Import_${DateTime.now().millisecondsSinceEpoch}',
        isProUser: isPro,
      );

      final docProvider = context.read<DocumentProvider>();
      await docProvider.createDocument(
        name: 'Import_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: files.first.path,
        pdfPath: pdf.path,
        extractedText: ocrText,
        pageImagePaths: files.map((f) => f.path).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${files.length} images to PDF!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionProcessing = false);
    }
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDocumentBottomSheet(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.borderDark, height: 24),

                // 1. Rename
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                  title: const Text('Rename Document', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(doc);
                  },
                ),

                // 2. Sign
                ListTile(
                  leading: const Icon(Icons.draw_outlined, color: AppTheme.indigoLight),
                  title: const Text('Sign Document', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openSignDocument(doc);
                  },
                ),

                // 3. Encrypt
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppTheme.warningAmber),
                  title: const Text('Password Encrypt (AES-128)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEncryptDialog(doc);
                  },
                ),

                // 4. Cloud Sync
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppTheme.emerald),
                  title: const Text('Sync to Cloud (Supabase)', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _syncDocumentToCloud(doc);
                  },
                ),

                // 5. Delete
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                  title: const Text('Delete Document', style: TextStyle(color: AppTheme.errorRed)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(doc);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog(DocumentModel doc) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rename Document', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Enter new document name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  final updated = doc.copyWith(name: newName);
                  await context.read<DocumentProvider>().updateDocument(updated);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSignDocument(DocumentModel doc) async {
    final file = File(doc.imagePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document image file not found on disk.')),
        );
      }
      return;
    }

    final result = await Navigator.of(context).push<SignatureResult>(
      MaterialPageRoute(
        builder: (_) => SignatureScreen(documentImage: file),
      ),
    );

    if (result != null && result.stampedDocumentFile != null && mounted) {
      final updated = doc.copyWith(
        imagePath: result.stampedDocumentFile!.path,
      );
      await context.read<DocumentProvider>().updateDocument(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature stamped successfully!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  void _showEncryptDialog(DocumentModel doc) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('AES-128 Password Lock', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set a password to secure this PDF using AES-128 encryption.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Enter password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = controller.text.trim();
                if (password.isEmpty) return;
                Navigator.pop(ctx);

                try {
                  final isPro = context.read<SubscriptionProvider>().isPro;
                  final pageFiles = (doc.pageImagePaths != null && doc.pageImagePaths!.isNotEmpty)
                      ? doc.pageImagePaths!.map((p) => File(p)).toList()
                      : [File(doc.imagePath)];

                  final secured = await _pdfExportService.generatePdf(
                    imageFiles: pageFiles,
                    fileName: '${doc.name}_encrypted',
                    isProUser: isPro,
                    password: password,
                  );

                  final updated = doc.copyWith(pdfPath: secured.path);
                  await context.read<DocumentProvider>().updateDocument(updated);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF encrypted with AES-128 successfully!'),
                        backgroundColor: AppTheme.emerald,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Encryption error: $e'), backgroundColor: AppTheme.errorRed),
                    );
                  }
                }
              },
              child: const Text('Lock PDF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncDocumentToCloud(DocumentModel doc) async {
    final pdfPath = doc.pdfPath ?? doc.imagePath;
    final file = File(pdfPath);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found for cloud sync.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing document to cloud...')),
    );

    try {
      final pageCount = doc.pageImagePaths?.length ?? 1;
      await _cloudSyncService.syncDocumentToCloud(
        pdfFile: file,
        title: doc.name,
        extractedText: doc.extractedText ?? '',
        pageCount: pageCount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document successfully synced to cloud!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorRed,
            action: SnackBarAction(
              label: 'Upgrade',
              textColor: Colors.white,
              onPressed: _openPaywall,
            ),
          ),
        );
      }
    }
  }

  void _confirmDelete(DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Document', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to permanently delete "${doc.name}"?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                await context.read<DocumentProvider>().deleteDocument(doc.id);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final docProvider = context.watch<DocumentProvider>();
    final filteredDocs = _filterDocuments(docProvider.documents);

    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.indigo,
          backgroundColor: AppTheme.cardSurface,
          onRefresh: () async {
            await docProvider.loadDocuments();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header & Tier Status Badge
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SleekScan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Offline Document Engine',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      AppTheme.tierBadge(
                        isPro: subProvider.isPro,
                        onTap: subProvider.isPro ? null : _openPaywall,
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: AppTheme.cardDecoration(
                      surfaceColor: AppTheme.cardSurface,
                      borderColor: AppTheme.borderDark,
                      borderRadius: 12,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search scans & OCR text...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // Action Hub
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: _buildActionHub(),
                ),
              ),

              // Documents Section Title
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Scans (${filteredDocs.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isActionProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.indigo,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Document Cards List or Zero-State
              if (filteredDocs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildZeroState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = filteredDocs[index];
                        return _buildDocumentCard(doc);
                      },
                      childCount: filteredDocs.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action Hub: "Smart Scan", "ID Card Mode", "Batch Scan", "Gallery Import"
  Widget _buildActionHub() {
    return Row(
      children: [
        Expanded(
          child: _buildActionHubItem(
            icon: Icons.document_scanner,
            label: 'Smart Scan',
            color: AppTheme.indigo,
            onTap: _handleSmartScan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionHubItem(
            icon: Icons.badge_outlined,
            label: 'ID Card Mode',
            color: AppTheme.emerald,
            onTap: _handleIdCardMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionHubItem(
            icon: Icons.burst_mode,
            label: 'Batch Scan',
            color: const Color(0xFF8B5CF6), // Purple
            onTap: _handleBatchScan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionHubItem(
            icon: Icons.photo_library_outlined,
            label: 'Gallery Import',
            color: const Color(0xFF0EA5E9), // Sky Blue
            onTap: _handleGalleryImport,
          ),
        ),
      ],
    );
  }

  Widget _buildActionHubItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: AppTheme.cardDecoration(
          surfaceColor: AppTheme.cardSurface,
          borderColor: AppTheme.borderDark,
          borderRadius: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Document Card with Thumbnail, Metadata Badge, Direct Share & 3-dot Menu
  Widget _buildDocumentCard(DocumentModel doc) {
    final dateStr = DateFormat('MMM d, yyyy').format(doc.createdAt);
    final pageCount = doc.pageImagePaths?.length ?? 1;

    // Check file size asynchronously or inspect path
    int fileSizeBytes = 0;
    try {
      final f = File(doc.pdfPath ?? doc.imagePath);
      if (f.existsSync()) {
        fileSizeBytes = f.lengthSync();
      }
    } catch (_) {}

    final sizeStr = _formatFileSize(fileSizeBytes);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(
        surfaceColor: AppTheme.cardSurface,
        borderColor: AppTheme.borderDark,
        borderRadius: 14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDocumentBottomSheet(doc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 58,
                  height: 68,
                  color: AppTheme.darkSlate,
                  child: _buildThumbnail(doc),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metadata Badge: PDF • 1.4 MB • 2 Pages
                    AppTheme.metadataBadge(
                      format: doc.pdfPath != null ? 'PDF' : 'IMG',
                      sizeString: sizeStr,
                      pageCount: pageCount,
                    ),
                  ],
                ),
              ),

              // Direct Share Action
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary, size: 20),
                onPressed: () {
                  final file = File(doc.pdfPath ?? doc.imagePath);
                  _pdfExportService.sharePdf(
                    pdfFile: file,
                    subject: doc.name,
                  );
                },
              ),

              // 3-dot Bottom Sheet Trigger
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
                onPressed: () => _showDocumentBottomSheet(doc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(DocumentModel doc) {
    try {
      final imgPath = doc.imagePath;
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}

    return const Icon(
      Icons.picture_as_pdf,
      color: AppTheme.indigoLight,
      size: 28,
    );
  }

  /// Zero-state illustration when no scans exist
  Widget _buildZeroState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 56,
                color: AppTheme.indigoLight,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Scans Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Smart Scan" or "ID Card Mode" above to scan your first document 100% offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleSmartScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
