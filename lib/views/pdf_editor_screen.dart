import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../core/themes.dart';
import '../services/pdf_service.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signature/signature.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../services/ocr_service.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class PdfEditorScreen extends StatefulWidget {
  final DocumentModel? document;
  final File? pdfFile;
  final bool isFromCreatePdf;

  const PdfEditorScreen({
    super.key,
    this.document,
    this.pdfFile,
    this.isFromCreatePdf = false,
  });

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen>
    with TickerProviderStateMixin {
  final PDFService _pdfService = PDFService();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String? _currentFilePath;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _errorMessage;

  // UI State
  bool _showColorPicker = false;

  // --- Page Management State ---
  List<int> _selectedPages = [];
  bool _isReorderMode = false;
  List<int> _pageOrder = [];

  // Drawing/signature controllers
  final SignatureController _drawController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.red,
    exportBackgroundColor: Colors.transparent,
  );
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (widget.document != null) {
        _currentFilePath = widget.document!.filePath;
      } else if (widget.pdfFile != null) {
        _currentFilePath = widget.pdfFile!.path;
      }

      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (!await file.exists()) {
          setState(() {
            _errorMessage = 'PDF file not found';
            _isLoading = false;
          });
          return;
        }
        final fileSize = await file.length();
        if (fileSize == 0) {
          setState(() {
            _errorMessage = 'PDF file is empty';
            _isLoading = false;
          });
          return;
        }
        try {
          final doc = sf.PdfDocument(inputBytes: await file.readAsBytes());
          _totalPages = doc.pages.count;
          _pageOrder = List.generate(_totalPages, (i) => i);
          doc.dispose();
        } catch (e) {
          _totalPages = 1;
          _pageOrder = [0];
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading PDF: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _drawController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.edit_document,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Edit PDF',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.15),
                        AppColors.primaryBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: AppColors.primaryBlue,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Page $_currentPage/$_totalPages',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Loading PDF...',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray800,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64.sp,
                              color: AppColors.error,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // --- Horizontal Page Thumbnails with modern design ---
                          Container(
                            height: 120.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gray50,
                                  AppColors.background
                                ],
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.gray200,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: _buildThumbnailBar(),
                          ),
                          // --- PDF Preview ---
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.primaryBlue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: SfPdfViewer.file(
                                  File(_currentFilePath!),
                                  key: _pdfViewerKey,
                                  controller: _pdfController,
                                  onPageChanged: (details) {
                                    setState(() {
                                      _currentPage = details.newPageNumber;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            // --- Modern Floating Action Bar ---
            if (!_isLoading && _errorMessage == null)
              Positioned(
                bottom: 24.h,
                left: 16.w,
                right: 16.w,
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, AppColors.gray50],
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                                Icons.add_box_rounded, 'Add', _onAddPage,
                                color: AppColors.emerald),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.delete_rounded, 'Remove', _onRemovePage,
                                color: AppColors.error),
                            SizedBox(width: 10.w),
                            _buildActionButton(Icons.reorder_rounded, 'Reorder',
                                _onReorderPages,
                                color: AppColors.amber),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.rotate_90_degrees_ccw_rounded,
                                'Rotate',
                                _onRotatePages,
                                color: AppColors.purple),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.crop_rounded, 'Crop', _onCropPages,
                                color: AppColors.secondaryTeal),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.brush_rounded, 'Annotate', _onAnnotate,
                                color: AppColors.rose),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.text_fields_rounded, 'Text', _onAddText,
                                color: AppColors.primaryBlue),
                            SizedBox(width: 10.w),
                            _buildActionButton(Icons.border_color_rounded,
                                'Signature', _onAddSignature,
                                color: AppColors.gray700),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.lock_rounded, 'Protect', _onProtect,
                                color: AppColors.gray900),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.search_rounded, 'OCR', _onOcrPages,
                                color: AppColors.purple),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.image_rounded, 'Export', _onExportImages,
                                color: AppColors.emerald),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.merge_type_rounded, 'Merge', _onMergePDF,
                                color: AppColors.primaryBlue),
                            SizedBox(width: 10.w),
                            _buildActionButton(
                                Icons.call_split_rounded, 'Split', _onSplitPDF,
                                color: AppColors.secondaryTeal),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailBar() {
    return FutureBuilder<int>(
      future: _getPageCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? _totalPages;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: count,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, i) {
              final selected = _selectedPages.contains(i);
              final isCurrent = _currentPage == i + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedPages.remove(i);
                    } else {
                      _selectedPages.add(i);
                    }
                    _currentPage = i + 1;
                  });
                  _pdfController.jumpToPage(i + 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 75.w,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlueLight,
                            ],
                          )
                        : null,
                    color: selected ? null : Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryBlue
                          : isCurrent
                              ? AppColors.primaryBlueLight
                              : AppColors.gray300,
                      width: selected
                          ? 2.5
                          : isCurrent
                              ? 2
                              : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected)
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      if (selected) SizedBox(height: 6.h),
                      Text(
                        'Page',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.gray600,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.gray900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed,
      {Color? color}) {
    final buttonColor = color ?? AppColors.primaryBlue;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            buttonColor,
            buttonColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22.sp, color: Colors.white),
                SizedBox(height: 6.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Action Handlers ---
  void _onAddPage() async {
    // Show dialog to pick type and position
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        int insertAt = _currentPage - 1;
        String type = 'blank';
        int maxInsertAt = _totalPages;
        if (insertAt < 0 || insertAt > maxInsertAt) insertAt = 0;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Page',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Type:'),
                    SizedBox(width: 12),
                    DropdownButton<String>(
                      value: type,
                      items: [
                        DropdownMenuItem(value: 'blank', child: Text('Blank')),
                        DropdownMenuItem(
                            value: 'image', child: Text('From Image')),
                        DropdownMenuItem(value: 'pdf', child: Text('From PDF')),
                      ],
                      onChanged: (v) => setSheetState(() => type = v!),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Insert at:'),
                    SizedBox(width: 12),
                    DropdownButton<int>(
                      value: insertAt,
                      items: List.generate(
                          _totalPages + 1,
                          (i) => DropdownMenuItem(
                              value: i, child: Text('Position ${i + 1}'))),
                      onChanged: (v) => setSheetState(() => insertAt = v!),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                      context, {'type': type, 'insertAt': insertAt}),
                  child: Text('Add Page'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null) return;
    setState(() => _isLoading = true);
    try {
      if (result['type'] == 'blank') {
        await _onAddBlankPageCustom(result['insertAt']);
      } else if (result['type'] == 'image') {
        await _onAddPageFromImageCustom(result['insertAt']);
      } else if (result['type'] == 'pdf') {
        await _onInsertPageCustom(result['insertAt']);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onRemovePage() async {
    if (_selectedPages.isEmpty) {
      _showSnackBar('Select page(s) to remove', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Pages'),
        content: Text('Are you sure you want to remove the selected page(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final file = File(_currentFilePath!);
      final newFile = await _pdfService.removePagesFromPDF(
        pdfFile: file,
        pagesToRemove: _selectedPages,
        outputTitle: widget.document?.title ?? 'edited_pdf',
      );
      print('Remove pages: new file: \\${newFile?.path}');
      if (newFile != null && await newFile.exists()) {
        final testDoc = sf.PdfDocument(inputBytes: await newFile.readAsBytes());
        print('New page count: \\${testDoc.pages.count}');
        if (testDoc.pages.count < _totalPages) {
          setState(() {
            _currentFilePath = newFile.path;
            _selectedPages.clear();
          });
          _initializePdf();
          _showSnackBar('Pages removed!');
        } else {
          _showSnackBar('Failed to remove pages (page count did not decrease)',
              isError: true);
        }
        testDoc.dispose();
      } else {
        _showSnackBar('Failed to remove pages (file not created)',
            isError: true);
      }
      setState(() => _isLoading = false);
    }
  }

  void _onSplitPDF() async {
    if (_selectedPages.isEmpty) {
      _showSnackBar('Select page(s) to split', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Split PDF'),
        content: Text('Split the selected page(s) into a new PDF?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Split')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      await _onSplitPDFImpl();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSplitPDFImpl() async {
    final file = File(_currentFilePath!);
    final splitFiles = await _pdfService.splitPDF(
      pdfFile: file,
      baseTitle: widget.document?.title ?? 'split_pdf',
      pageNumbers: _selectedPages,
    );
    if (splitFiles.isNotEmpty) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PDF Split Successful'),
          content: Text(
              'Split into ${splitFiles.length} file(s). Open the first split PDF?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Open')),
          ],
        ),
      );
      if (open == true) {
        setState(() {
          _currentFilePath = splitFiles.first.path;
          _selectedPages.clear();
        });
        _initializePdf();
      }
      _showSnackBar('Split into ${splitFiles.length} file(s)!');
    } else {
      _showSnackBar('Failed to split PDF', isError: true);
    }
  }

  void _onMergePDF() async {
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false);
    if (picked != null && picked.files.isNotEmpty) {
      final position = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Merge PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select position to merge the new PDF:'),
              SizedBox(height: 16),
              DropdownButton<int>(
                value: _currentPage - 1,
                items: List.generate(
                    _totalPages + 1,
                    (i) => DropdownMenuItem(
                        value: i, child: Text('Position ${i + 1}'))),
                onChanged: (v) => Navigator.pop(context, v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancel')),
          ],
        ),
      );
      if (position != null) {
        setState(() => _isLoading = true);
        final mergeFile = File(picked.files.first.path!);
        final file = File(_currentFilePath!);
        final pdfService = PDFService();
        final newFile = await pdfService.insertPagesIntoPDF(
          pdfFile: file,
          pagesToInsert: [mergeFile],
          insertAt: position,
          outputTitle: widget.document?.title ?? 'merged_pdf',
        );
        if (newFile != null) {
          setState(() {
            _currentFilePath = newFile.path;
            _selectedPages.clear();
          });
          _initializePdf();
          _showSnackBar('PDFs merged!');
        } else {
          _showSnackBar('Failed to merge PDFs', isError: true);
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _onReorderPages() async {
    // Show a dialog with drag & drop reorder UI
    await showDialog(
      context: context,
      builder: (context) {
        List<int> tempOrder = List.from(_pageOrder);
        return AlertDialog(
          title: Text('Reorder Pages'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final item = tempOrder.removeAt(oldIndex);
                tempOrder.insert(newIndex, item);
              },
              children: [
                for (int i = 0; i < tempOrder.length; i++)
                  ListTile(
                    key: ValueKey(tempOrder[i]),
                    title: Text('Page ${tempOrder[i] + 1}'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                final file = File(_currentFilePath!);
                final newFile = await _pdfService.reorderPagesInPDF(
                  pdfFile: file,
                  newOrder: tempOrder,
                  outputTitle: widget.document?.title ?? 'edited_pdf',
                );
                if (newFile != null) {
                  setState(() {
                    _currentFilePath = newFile.path;
                    _pageOrder = List.from(tempOrder);
                  });
                  _initializePdf();
                  _showSnackBar('Pages reordered!');
                } else {
                  _showSnackBar('Failed to reorder pages', isError: true);
                }
                setState(() => _isLoading = false);
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // --- New: Rotate Pages ---
  void _onRotatePages() async {
    final rotation = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Rotate pages'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('90°')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 2),
              child: const Text('180°')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 3),
              child: const Text('270°')),
        ],
      ),
    );
    if (rotation == null) return;
    final pages =
        _selectedPages.isNotEmpty ? _selectedPages : [_currentPage - 1];
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final newFile = await _pdfService.rotatePagesInPDF(
      pdfFile: file,
      pages: pages,
      quarterTurns: rotation,
      outputTitle: widget.document?.title ?? 'edited_pdf',
    );
    if (newFile != null) {
      setState(() {
        _currentFilePath = newFile.path;
        _selectedPages.clear();
      });
      await _initializePdf();
      _showSnackBar('Pages rotated!');
    } else {
      _showSnackBar('Failed to rotate pages', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: Crop Pages by margins ---
  void _onCropPages() async {
    double l = 0.05, t = 0.05, r = 0.05, b = 0.05;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Crop margins (percentage of page)'),
                const SizedBox(height: 12),
                _sliderRow('Left', l, (v) => setS(() => l = v)),
                _sliderRow('Top', t, (v) => setS(() => t = v)),
                _sliderRow('Right', r, (v) => setS(() => r = v)),
                _sliderRow('Bottom', b, (v) => setS(() => b = v)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;
    final pages =
        _selectedPages.isNotEmpty ? _selectedPages : [_currentPage - 1];
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final newFile = await _pdfService.cropPagesInPDFByMargin(
      pdfFile: file,
      pages: pages,
      leftPct: l,
      topPct: t,
      rightPct: r,
      bottomPct: b,
      outputTitle: widget.document?.title ?? 'edited_pdf',
    );
    if (newFile != null) {
      setState(() {
        _currentFilePath = newFile.path;
        _selectedPages.clear();
      });
      await _initializePdf();
      _showSnackBar('Pages cropped!');
    } else {
      _showSnackBar('Failed to crop pages', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Widget _sliderRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 0.45,
            divisions: 45,
            label: '${(value * 100).round()}%',
          ),
        ),
      ],
    );
  }

  // --- New: Annotate (freehand drawing overlay) ---
  void _onAnnotate() async {
    _drawController.clear();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw on page'),
        content: SizedBox(
          width: 350,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Signature(
                    controller: _drawController,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _drawController.clear,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final png = await _drawController.toPngBytes();
    if (png == null) return;
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    // Overlay full-page
    final doc = sf.PdfDocument(inputBytes: await file.readAsBytes());
    final pageSize = doc.pages[_currentPage - 1].size;
    doc.dispose();
    final newFile = await _pdfService.addImageOverlayToPDF(
      pdfFile: file,
      pngBytes: png,
      pageIndex: _currentPage - 1,
      targetRect: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      outputTitle: widget.document?.title ?? 'edited_pdf',
    );
    if (newFile != null) {
      setState(() => _currentFilePath = newFile.path);
      await _initializePdf();
      _showSnackBar('Annotation added!');
    } else {
      _showSnackBar('Failed to add annotation', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: Add Text ---
  void _onAddText() async {
    final textCtl = TextEditingController();
    double size = 14;
    Color color = Colors.black;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtl,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Size'),
              Expanded(
                child: Slider(
                  min: 8,
                  max: 48,
                  divisions: 40,
                  value: size,
                  onChanged: (v) {
                    size = v;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              Text(size.toStringAsFixed(0))
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Color'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: BlockPicker(
                          pickerColor: color,
                          onColorChanged: (c) => Navigator.pop(context, c),
                        ),
                      ),
                    );
                    if (picked != null) {
                      color = picked;
                      (context as Element).markNeedsBuild();
                    }
                  },
                  child: Container(width: 20, height: 20, color: color),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || textCtl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final newFile = await _pdfService.addTextToPDF(
      pdfFile: file,
      text: textCtl.text.trim(),
      pageIndex: _currentPage - 1,
      position: const Offset(40, 60),
      outputTitle: widget.document?.title ?? 'edited_pdf',
      fontSize: size,
      textColor: color,
    );
    if (newFile != null) {
      setState(() => _currentFilePath = newFile.path);
      await _initializePdf();
      _showSnackBar('Text added!');
    } else {
      _showSnackBar('Failed to add text', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: Signature ---
  void _onAddSignature() async {
    _signatureController.clear();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add signature'),
        content: SizedBox(
          width: 350,
          height: 250,
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: _signatureController.clear,
              child: const Text('Clear')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply')),
        ],
      ),
    );
    if (saved != true) return;
    final png = await _signatureController.toPngBytes();
    if (png == null) return;
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final doc = sf.PdfDocument(inputBytes: await file.readAsBytes());
    final size = doc.pages[_currentPage - 1].size;
    doc.dispose();
    final double w = size.width * 0.35;
    final double h = w * 0.35; // approximate aspect
    final newFile = await _pdfService.addImageOverlayToPDF(
      pdfFile: file,
      pngBytes: png,
      pageIndex: _currentPage - 1,
      targetRect:
          Rect.fromLTWH(size.width - w - 24, size.height - h - 24, w, h),
      outputTitle: widget.document?.title ?? 'edited_pdf',
    );
    if (newFile != null) {
      setState(() => _currentFilePath = newFile.path);
      await _initializePdf();
      _showSnackBar('Signature added!');
    } else {
      _showSnackBar('Failed to add signature', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: Protect PDF ---
  void _onProtect() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password protect'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply')),
        ],
      ),
    );
    if (ok != true || ctl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final newFile = await _pdfService.passwordProtectPDF(
      pdfFile: file,
      userPassword: ctl.text,
      outputTitle: widget.document?.title ?? 'secured_pdf',
    );
    if (newFile != null) {
      setState(() => _currentFilePath = newFile.path);
      await _initializePdf();
      _showSnackBar('Password set!');
    } else {
      _showSnackBar('Failed to protect PDF', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: OCR selected pages ---
  void _onOcrPages() async {
    final pages =
        _selectedPages.isNotEmpty ? _selectedPages : [_currentPage - 1];
    setState(() => _isLoading = true);
    try {
      final file = File(_currentFilePath!);
      final images =
          await _pdfService.extractImagesFromPDF(pdfFile: file, scale: 2.0);
      if (images.isEmpty) {
        _showSnackBar('Could not render pages for OCR', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      final ocr = OCRService();
      final buffer = StringBuffer();
      for (final p in pages) {
        if (p < images.length) {
          final res = await ocr.extractTextFromImage(images[p]);
          if (res != null && res.text.isNotEmpty) {
            buffer.writeln('--- Page ${p + 1} ---');
            buffer.writeln(res.text);
            buffer.writeln();
          }
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        _showSnackBar('No text found', isError: true);
      } else {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('OCR Result'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(child: Text(text)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  _showSnackBar('Copied to clipboard');
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () async {
                  final dir = await getApplicationDocumentsDirectory();
                  final out = File(
                      '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt');
                  await out.writeAsString(text);
                  Navigator.pop(context);
                  _showSnackBar('Saved to ${out.path}');
                },
                child: const Text('Save .txt'),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('OCR error: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- New: Export as images ---
  void _onExportImages() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Export pages as'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'jpg'),
              child: const Text('JPG')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'png'),
              child: const Text('PNG')),
        ],
      ),
    );
    if (format == null) return;
    setState(() => _isLoading = true);
    try {
      final file = File(_currentFilePath!);
      final images =
          await _pdfService.exportPagesAsImages(pdfFile: file, format: format);
      if (images.isEmpty) {
        _showSnackBar('Export failed', isError: true);
      } else {
        int savedCount = 0;
        for (final imgFile in images) {
          final res = await SaverGallery.saveFile(
            filePath: imgFile.path,
            fileName: p.basename(imgFile.path),
            skipIfExists: false,
          );
          if (res.isSuccess) savedCount++;
        }
        _showSnackBar('Exported $savedCount image(s) to gallery');
      }
    } catch (e) {
      _showSnackBar('Export error: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // --- Custom Add Page Handlers ---
  Future<void> _onAddBlankPageCustom(int insertAt) async {
    setState(() => _isLoading = true);
    try {
      final file = File(_currentFilePath!);
      final bytes = await file.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final blankPage = document.pages.add();
      blankPage.graphics.drawString(
          '', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12),
          bounds: const Rect.fromLTWH(0, 0, 0, 0));
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${widget.document?.title ?? 'edited_pdf'}_blank_added_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final newFile = File('${directory.path}/$fileName');
      final newBytes = await document.save();
      await newFile.writeAsBytes(newBytes);
      document.dispose();
      print('Blank page added. New file: \\${newFile.path}');
      if (await newFile.exists()) {
        final testDoc = sf.PdfDocument(inputBytes: await newFile.readAsBytes());
        print('New page count: \\${testDoc.pages.count}');
        if (testDoc.pages.count > _totalPages) {
          setState(() {
            _currentFilePath = newFile.path;
            _selectedPages.clear();
          });
          _initializePdf();
          _showSnackBar('Blank page added!');
        } else {
          _showSnackBar(
              'Failed to add blank page (page count did not increase)',
              isError: true);
        }
        testDoc.dispose();
      } else {
        _showSnackBar('Failed to add blank page (file not created)',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to add blank page: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddPageFromImageCustom(int insertAt) async {
    setState(() => _isLoading = true);
    try {
      final picked = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);
      if (picked != null && picked.files.isNotEmpty) {
        final imageFile = File(picked.files.first.path!);
        final pdfService = PDFService();
        final tempPdf = await pdfService.createPDFFromImages(
            imageFiles: [imageFile], title: 'temp_image_page');
        if (tempPdf != null) {
          final file = File(_currentFilePath!);
          final newFile = await pdfService.insertPagesIntoPDF(
            pdfFile: file,
            pagesToInsert: [tempPdf],
            insertAt: insertAt,
            outputTitle: widget.document?.title ?? 'edited_pdf',
          );
          print('Image page add: new file: \\${newFile?.path}');
          if (newFile != null && await newFile.exists()) {
            final testDoc =
                sf.PdfDocument(inputBytes: await newFile.readAsBytes());
            print('New page count: \\${testDoc.pages.count}');
            if (testDoc.pages.count > _totalPages) {
              setState(() {
                _currentFilePath = newFile.path;
                _selectedPages.clear();
              });
              _initializePdf();
              _showSnackBar('Image page added!');
            } else {
              _showSnackBar(
                  'Failed to add image page (page count did not increase)',
                  isError: true);
            }
            testDoc.dispose();
          } else {
            _showSnackBar('Failed to add image page (file not created)',
                isError: true);
          }
        } else {
          _showSnackBar('Failed to convert image to PDF', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to add image page: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onInsertPageCustom(int insertAt) async {
    setState(() => _isLoading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false);
      if (picked != null && picked.files.isNotEmpty) {
        final insertFile = File(picked.files.first.path!);
        final file = File(_currentFilePath!);
        final pdfService = PDFService();
        final newFile = await pdfService.insertPagesIntoPDF(
          pdfFile: file,
          pagesToInsert: [insertFile],
          insertAt: insertAt,
          outputTitle: widget.document?.title ?? 'edited_pdf',
        );
        print('Insert PDF page: new file: \\${newFile?.path}');
        if (newFile != null && await newFile.exists()) {
          final testDoc =
              sf.PdfDocument(inputBytes: await newFile.readAsBytes());
          print('New page count: \\${testDoc.pages.count}');
          if (testDoc.pages.count > _totalPages) {
            setState(() {
              _currentFilePath = newFile.path;
              _selectedPages.clear();
            });
            _initializePdf();
            _showSnackBar('PDF page inserted!');
          } else {
            _showSnackBar(
                'Failed to insert PDF page (page count did not increase)',
                isError: true);
          }
          testDoc.dispose();
        } else {
          _showSnackBar('Failed to insert PDF page (file not created)',
              isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to insert PDF page: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Page Management Actions ---
  Future<void> _onDeletePages() async {
    if (_currentFilePath == null || _selectedPages.isEmpty) return;
    setState(() => _isLoading = true);
    final file = File(_currentFilePath!);
    final newFile = await _pdfService.removePagesFromPDF(
      pdfFile: file,
      pagesToRemove: _selectedPages,
      outputTitle: widget.document?.title ?? 'edited_pdf',
    );
    if (newFile != null) {
      setState(() {
        _currentFilePath = newFile.path;
        _selectedPages.clear();
        _isLoading = false;
      });
      _initializePdf();
      _showSnackBar('Pages deleted!');
    } else {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to delete pages', isError: true);
    }
  }

  Future<int> _getPageCount() async {
    return _totalPages;
  }
}
