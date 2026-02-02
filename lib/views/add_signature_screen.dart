import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../services/pdf_service.dart';
import '../core/themes.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/pdf_preview_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/pdf_preview_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AddSignatureScreen extends StatefulWidget {
  final File pdfFile;
  final int initialPage;

  const AddSignatureScreen({
    Key? key,
    required this.pdfFile,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<AddSignatureScreen> createState() => _AddSignatureScreenState();
}

class _AddSignatureScreenState extends State<AddSignatureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SignatureController _signatureController;
  Color _currentPenColor = Colors.black;

  File? _uploadedSignatureFile;
  Uint8List? _currentSignatureBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSignatureController();
  }

  void _initSignatureController() {
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: _currentPenColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  void _changePenColor(Color color) {
    setState(() {
      _currentPenColor = color;
      // Dispose old controller and create new one with new color
      _signatureController.dispose();
      _initSignatureController();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickSignatureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _uploadedSignatureFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _captureSignatureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _uploadedSignatureFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _proceedWithDrawnSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first')),
      );
      return;
    }

    final signature = await _signatureController.toPngBytes();
    if (signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture signature')),
      );
      return;
    }

    setState(() {
      _currentSignatureBytes = signature;
    });

    _navigateToPlacementScreen(signature);
  }

  Future<void> _proceedWithUploadedSignature() async {
    if (_uploadedSignatureFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a signature image first')),
      );
      return;
    }

    final bytes = await _uploadedSignatureFile!.readAsBytes();
    setState(() {
      _currentSignatureBytes = bytes;
    });

    _navigateToPlacementScreen(bytes);
  }

  void _navigateToPlacementScreen(Uint8List signatureBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignaturePlacementScreen(
          pdfFile: widget.pdfFile,
          signatureBytes: signatureBytes,
          initialPage: widget.initialPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.draw_rounded,
              color: AppColors.primaryBlue,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Add Signature',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(icon: Icon(Icons.draw), text: 'Draw'),
            Tab(icon: Icon(Icons.image), text: 'Upload'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDrawTab(),
          _buildUploadTab(),
        ],
      ),
    );
  }

  Widget _buildDrawTab() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Draw your signature',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Color:',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildColorButton(Colors.black),
                          SizedBox(width: 8.w),
                          _buildColorButton(Colors.blue),
                          SizedBox(width: 8.w),
                          _buildColorButton(Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Signature(
                        controller: _signatureController,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _signatureController.clear();
                          },
                          icon: const Icon(Icons.clear),
                          label: Text(
                            'Clear',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _proceedWithDrawnSignature,
                          icon: const Icon(Icons.check),
                          label: Text(
                            'Add to PDF',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentPenColor == color;
    return GestureDetector(
      onTap: () => _changePenColor(color),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Upload your signature image or take a photo',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          if (_uploadedSignatureFile != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _uploadedSignatureFile = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.r),
                      child: Image.file(
                        _uploadedSignatureFile!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 24.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                _buildUploadOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select a signature image',
                  color: AppColors.primaryBlue,
                  onTap: _pickSignatureImage,
                ),
                SizedBox(height: 16.h),
                _buildUploadOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take Photo',
                  subtitle: 'Capture your signature',
                  color: AppColors.secondaryTeal,
                  onTap: _captureSignatureImage,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          if (_uploadedSignatureFile != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _proceedWithUploadedSignature,
                  icon: const Icon(Icons.check),
                  label: Text(
                    'Add to PDF',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignaturePlacementScreen extends StatefulWidget {
  final File pdfFile;
  final Uint8List signatureBytes;
  final int initialPage;

  const SignaturePlacementScreen({
    Key? key,
    required this.pdfFile,
    required this.signatureBytes,
    this.initialPage = 1,
  }) : super(key: key);

  @override
  State<SignaturePlacementScreen> createState() =>
      _SignaturePlacementScreenState();
}

class _SignaturePlacementScreenState extends State<SignaturePlacementScreen> {
  double _signatureX = 50;
  double _signatureY = 50;
  double _signatureWidth = 150;
  double _signatureHeight = 75;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  final PDFService _pdfService = PDFService();
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey _pdfViewKey = GlobalKey();
  bool _applyToAllPages = false;
  Set<int> _selectedPages = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    try {
      final pageCount = await _pdfService.getPdfPageCount(widget.pdfFile);
      setState(() {
        _totalPages = pageCount;
      });
    } catch (e) {
      print('Error loading PDF info: $e');
    }
  }

  Future<void> _saveSignatureToPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdfBytes = await widget.pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: pdfBytes);

      // Determine which pages to sign
      List<int> pagesToSign = [];
      if (_applyToAllPages) {
        pagesToSign = List.generate(document.pages.count, (i) => i);
      } else if (_selectedPages.isNotEmpty) {
        pagesToSign = _selectedPages.map((p) => p - 1).toList();
      } else {
        pagesToSign = [(_currentPage - 1).clamp(0, document.pages.count - 1)];
      }

      // Get screen dimensions from the PDF viewer
      RenderBox? renderBox =
          _pdfViewKey.currentContext?.findRenderObject() as RenderBox?;
      final screenWidth =
          renderBox?.size.width ?? MediaQuery.of(context).size.width - 32;
      final screenHeight = renderBox?.size.height ?? 500;

      // Convert signature bytes to PdfBitmap
      final bitmap = sf.PdfBitmap(widget.signatureBytes);

      // Apply signature to selected pages
      for (final pageIndex in pagesToSign) {
        final page = document.pages[pageIndex];
        final pageSize = page.size;

        // Calculate position mapping from screen to PDF coordinates
        // Screen: top-left origin, PDF: bottom-left origin
        final scaleX = pageSize.width / screenWidth;
        final scaleY = pageSize.height / screenHeight;

        final pdfX = _signatureX * scaleX;
        final pdfY = pageSize.height -
            (_signatureY * scaleY) -
            (_signatureHeight * scaleY);
        final pdfWidth = _signatureWidth * scaleX;
        final pdfHeight = _signatureHeight * scaleY;

        // Draw signature on PDF
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(pdfX, pdfY, pdfWidth, pdfHeight),
        );
      }

      // Save the document
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File('${directory.path}/$fileName');

      final bytes = await document.save();
      await outputFile.writeAsBytes(bytes);

      document.dispose();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to preview screen with the signed PDF
        final subtitle = _applyToAllPages
            ? 'Signature added to all $_totalPages pages'
            : _selectedPages.isNotEmpty
                ? 'Signature added to ${_selectedPages.length} page(s)'
                : 'Signature added to page $_currentPage';

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: outputFile,
              title: 'Signed PDF',
              subtitle: subtitle,
            ),
          ),
        );

        if (mounted) {
          // Return the signed PDF file back through the navigation stack
          Navigator.pop(context, outputFile); // Close placement screen
          Navigator.pop(context, outputFile); // Close signature screen
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Failed to add signature: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showPageSelector() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Select Pages',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          _selectedPages = Set.from(
                              List.generate(_totalPages, (i) => i + 1));
                        });
                      },
                      icon: Icon(Icons.select_all, size: 18.sp),
                      label: const Text('Select All'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          _selectedPages.clear();
                        });
                      },
                      icon: Icon(Icons.clear, size: 18.sp),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                Divider(height: 1.h),
                SizedBox(height: 8.h),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 1,
                    ),
                    itemCount: _totalPages,
                    itemBuilder: (context, index) {
                      final pageNum = index + 1;
                      final isSelected = _selectedPages.contains(pageNum);
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              _selectedPages.remove(pageNum);
                            } else {
                              _selectedPages.add(pageNum);
                            }
                            _applyToAllPages = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF667EEA)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 32.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPages.clear();
                  _applyToAllPages = false;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _applyToAllPages = false;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Apply (${_selectedPages.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Position Signature',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: AppColors.primaryBlue,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to use'),
                  content: const Text(
                    '• Drag the signature to position it\n'
                    '• Use the slider to resize\n'
                    '• Tap "Save" when ready',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    'Adding signature to PDF...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                        children: [
                          // PDF Preview with actual page rendering
                          SfPdfViewer.file(
                            widget.pdfFile,
                            key: _pdfViewKey,
                            controller: _pdfController,
                            initialPageNumber: _currentPage,
                            canShowScrollHead: false,
                            canShowScrollStatus: false,
                            canShowPaginationDialog: false,
                            pageLayoutMode: PdfPageLayoutMode.single,
                            onPageChanged: (details) {
                              setState(() {
                                _currentPage = details.newPageNumber;
                              });
                            },
                            onDocumentLoaded: (details) {
                              setState(() {
                                _totalPages = details.document.pages.count;
                              });
                            },
                          ),
                          // Draggable Signature
                          Positioned(
                            left: _signatureX,
                            top: _signatureY,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _signatureX += details.delta.dx;
                                  _signatureY += details.delta.dy;

                                  // Keep within bounds
                                    _signatureX = _signatureX.clamp(
                                      0.0,
                                      constraints.maxWidth - _signatureWidth);
                                    _signatureY = _signatureY.clamp(
                                      0.0,
                                      constraints.maxHeight - _signatureHeight);
                                });
                              },
                              child: Container(
                                width: _signatureWidth,
                                height: _signatureHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                    ],
                                  );
                                },
                                ),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      widget.signatureBytes,
                                      fit: BoxFit.contain,
                                      width: _signatureWidth,
                                      height: _signatureHeight,
                                    ),
                                    // Drag handle indicator
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                        ),
                                        child: Icon(
                                          Icons.drag_indicator,
                                          size: 16.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Controls - smaller flex
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Container(
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Page selector
                      if (_totalPages > 1)
                        Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF667EEA).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFF667EEA)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: const Color(0xFF667EEA),
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Page $_currentPage of $_totalPages',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF667EEA),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_left,
                                      color: _currentPage > 1
                                          ? const Color(0xFF667EEA)
                                          : Colors.grey[400],
                                    ),
                                    onPressed: _currentPage > 1
                                        ? () {
                                            _pdfController.previousPage();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: _currentPage < _totalPages
                                          ? const Color(0xFF667EEA)
                                          : Colors.grey[400],
                                    ),
                                    onPressed: _currentPage < _totalPages
                                        ? () {
                                            _pdfController.nextPage();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // Multi-page options
                      if (_totalPages > 1)
                        Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.layers,
                                    color: const Color(0xFF667EEA),
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Apply to Pages',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              // Radio options
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _applyToAllPages = false;
                                    _selectedPages.clear();
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: !_applyToAllPages &&
                                            _selectedPages.isEmpty
                                        ? const Color(0xFF667EEA)
                                            .withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        !_applyToAllPages &&
                                                _selectedPages.isEmpty
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: const Color(0xFF667EEA),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Current page only',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _applyToAllPages = true;
                                    _selectedPages.clear();
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: _applyToAllPages
                                        ? const Color(0xFF667EEA)
                                            .withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _applyToAllPages
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: const Color(0xFF667EEA),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'All pages ($_totalPages pages)',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              InkWell(
                                onTap: () => _showPageSelector(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: _selectedPages.isNotEmpty
                                        ? const Color(0xFF667EEA)
                                            .withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedPages.isNotEmpty
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: const Color(0xFF667EEA),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          _selectedPages.isEmpty
                                              ? 'Select specific pages'
                                              : '${_selectedPages.length} page(s) selected',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14.sp,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Size slider
                      Row(
                        children: [
                          Icon(
                            Icons.photo_size_select_small,
                            color: Colors.grey[600],
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Size',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Slider(
                                  value: _signatureWidth,
                                  min: 50,
                                  max: 400,
                                  divisions: 70,
                                  label: '${_signatureWidth.round()}',
                                                      ),
                                                    ),
                                                  ),
                                  activeColor: AppColors.primaryBlue,
                                  onChanged: (value) {
                                    setState(() {
                                      _signatureWidth = value;
                                      _signatureHeight = value * 0.5;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.photo_size_select_large,
                            color: AppColors.primaryBlue,
                            size: 24.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _saveSignatureToPdf,
                              icon: const Icon(Icons.check),
                              label: Text(
                                'Save Signature',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
