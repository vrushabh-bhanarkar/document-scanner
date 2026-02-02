import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'merge_pdfs_screen.dart';
import 'split_pdf_screen.dart';
import 'pdf_annotation_screen.dart';
import 'rotate_pages_screen.dart';
import 'delete_pages_screen.dart';
import 'add_pages_screen.dart';
import 'password_protect_screen.dart';
import 'remove_password_screen.dart';
import 'compress_pdf_screen.dart';
import 'extract_text_screen.dart';
import 'extract_images_screen.dart';
import 'watermark_screen.dart';
import 'page_reorder_screen.dart';
import 'pdf_metadata_screen.dart';
import 'convert_pdf_screen.dart';
import 'add_signature_screen.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import 'package:provider/provider.dart';
import '../widgets/native_ad_widget.dart';

class EditPdfTab extends StatefulWidget {
  const EditPdfTab({Key? key}) : super(key: key);

  @override
  State<EditPdfTab> createState() => _EditPdfTabState();
}

class _EditPdfTabState extends State<EditPdfTab> with TickerProviderStateMixin {
  List<File> recentPdfs = [];
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _loadRecentPdfs();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Create staggered slide animations for tool cards
    _slideAnimations = List.generate(15, (index) {
      // Calculate start and end values ensuring they don't exceed 1.0
      final start = (index * 0.05).clamp(0.0, 0.8);
      final end = (0.4 + (index * 0.03)).clamp(start + 0.1, 1.0);

      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start,
            end,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _loadRecentPdfs() async {
    setState(() => isLoading = true);
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    await provider.loadDocuments();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_circle_rounded,
              color: const Color(0xFF667EEA),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'PDF Tools',
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: const Color(0xFF667EEA), size: 24.sp),
            onPressed: _loadRecentPdfs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF Tools Grid
              _buildPdfToolsSection(),
              SizedBox(height: 32.h),

              // Native Ad
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: NativeAdWidget(),
              ),
              SizedBox(height: 32.h),

              // Recent PDFs Section
              // _buildRecentPdfsSection(),
              // SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfToolsSection() {
    final tools = [
      {
        'title': 'Merge PDFs',
        'subtitle': 'Combine multiple files',
        'icon': Icons.merge_type_rounded,
        'color': const Color(0xFF10B981),
        'action': 'merge'
      },
      {
        'title': 'Split PDF',
        'subtitle': 'Divide into parts',
        'icon': Icons.content_cut_rounded,
        'color': const Color(0xFFEF4444),
        'action': 'split'
      },
      {
        'title': 'Rotate Pages',
        'subtitle': 'Change orientation',
        'icon': Icons.rotate_right_rounded,
        'color': const Color(0xFF8B5CF6),
        'action': 'rotate'
      },
      {
        'title': 'Delete Pages',
        'subtitle': 'Remove unwanted pages',
        'icon': Icons.delete_outline_rounded,
        'color': const Color(0xFFEC4899),
        'action': 'delete'
      },
      {
        'title': 'Add Pages',
        'subtitle': 'Insert new content',
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF06B6D4),
        'action': 'add'
      },
      // {
      //   'title': 'Annotate',
      //   'subtitle': 'Add notes & drawings',
      //   'icon': Icons.edit_rounded,
      //   'color': const Color(0xFF6366F1),
      //   'action': 'annotate'
      // },
      {
        'title': 'Add Password',
        'subtitle': 'Secure with password',
        'icon': Icons.lock_rounded,
        'color': const Color(0xFFF59E0B),
        'action': 'add_password'
      },
      {
        'title': 'Remove Password',
        'subtitle': 'Unlock protected PDF',
        'icon': Icons.lock_open_rounded,
        'color': const Color(0xFF10B981),
        'action': 'remove_password'
      },
      {
        'title': 'Compress',
        'subtitle': 'Reduce file size',
        'icon': Icons.compress_rounded,
        'color': const Color(0xFF8B5A3C),
        'action': 'compress'
      },
      {
        'title': 'Extract Text',
        'subtitle': 'Get text content',
        'icon': Icons.text_fields_rounded,
        'color': const Color(0xFF3B82F6),
        'action': 'extract_text'
      },
      {
        'title': 'Extract Images',
        'subtitle': 'Save embedded images',
        'icon': Icons.image_rounded,
        'color': const Color(0xFF059669),
        'action': 'extract_images'
      },
      {
        'title': 'Add Signature',
        'subtitle': 'Sign document',
        'icon': Icons.draw_rounded,
        'color': const Color(0xFF6366F1),
        'action': 'signature'
      },
      {
        'title': 'Watermark',
        'subtitle': 'Brand protection',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF0EA5E9),
        'action': 'watermark'
      },
      {
        'title': 'Reorder',
        'subtitle': 'Rearrange pages',
        'icon': Icons.reorder_rounded,
        'color': const Color(0xFFF59E0B),
        'action': 'reorder'
      },
      {
        'title': 'Metadata',
        'subtitle': 'Edit properties',
        'icon': Icons.info_outline_rounded,
        'color': const Color(0xFF64748B),
        'action': 'metadata'
      },
      // {
      //   'title': 'Convert',
      //   'subtitle': 'Change format',
      //   'icon': Icons.transform_rounded,
      //   'color': const Color(0xFFDC2626),
      //   'action': 'convert'
      // },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.1,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];

            // Ensure we don't exceed the animation list bounds
            Widget child = _buildEnhancedToolCard(
              title: tool['title'] as String,
              subtitle: tool['subtitle'] as String,
              icon: tool['icon'] as IconData,
              color: tool['color'] as Color,
              onTap: () => _handleToolAction(tool['action'] as String),
            );

            // Only apply animation if the index is within bounds
            if (index < _slideAnimations.length) {
              return SlideTransition(
                position: _slideAnimations[index],
                child: child,
              );
            }

            // Fallback without animation
            return child;
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w), // Reduced padding from 20.w to 16.w
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
          children: [
            Container(
              padding:
                  EdgeInsets.all(12.w), // Reduced padding from 14.w to 12.w
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26.sp, // Reduced size from 28.sp to 26.sp
              ),
            ),
            SizedBox(height: 12.h), // Reduced height from 16.h to 12.h
            Flexible(
              // Wrap Text in Flexible to prevent overflow
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp, // Reduced from 15.sp to 14.sp
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 3.h), // Reduced height from 4.h to 3.h
            Flexible(
              // Wrap Text in Flexible to prevent overflow
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.sp, // Reduced from 12.sp to 11.sp
                  color: const Color(0xFF64748B),
                  height: 1.2, // Reduced line height from 1.3 to 1.2
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildRecentPdfsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(
  //                 Icons.history_rounded,
  //                 color: const Color(0xFF667EEA),
  //                 size: 24.sp,
  //               ),
  //               SizedBox(width: 8.w),
  //               Text(
  //                 'Recent PDFs',
  //                 style: TextStyle(
  //                   fontSize: 22.sp,
  //                   fontWeight: FontWeight.bold,
  //                   color: const Color(0xFF1E293B),
  //                   letterSpacing: 0.3,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           TextButton.icon(
  //             onPressed: () {
  //               // Navigate to all PDFs
  //             },
  //             icon: Icon(Icons.arrow_forward_rounded, size: 16.sp),
  //             label: Text(
  //               'View All',
  //               style: TextStyle(
  //                 fontSize: 14.sp,
  //                 color: const Color(0xFF667EEA),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 20.h),
  //       Consumer<DocumentProvider>(
  //         builder: (context, provider, child) {
  //           if (isLoading) {
  //             return _buildLoadingState();
  //           }

  //           final pdfDocuments = provider.documents
  //               .where((doc) => doc.type == DocumentType.pdf)
  //               .take(4)
  //               .toList();

  //           if (pdfDocuments.isEmpty) {
  //             return _buildEmptyState();
  //           }

  //           return Column(
  //             children: pdfDocuments
  //                 .map((doc) => _buildEnhancedPdfItem(doc))
  //                 .toList(),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  Widget _buildEnhancedPdfItem(DocumentModel doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: const Color(0xFFEF4444),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Created: ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: const Color(0xFF667EEA),
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading PDFs...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              color: const Color(0xFF667EEA),
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'No recent PDFs found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Edit your PDFs with our powerful tools.',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleToolAction(String action) {
    switch (action) {
      case 'merge':
        _mergePdfs(context);
        break;
      case 'split':
        _selectPdfAndNavigate(context, (file) => SplitPdfScreen(pdfFile: file));
        break;
      case 'rotate':
        _selectPdfAndNavigate(
            context, (file) => RotatePagesScreen(initialPdfFile: file));
        break;
      case 'delete':
        _selectPdfAndNavigate(
            context, (file) => DeletePagesScreen(initialPdfFile: file));
        break;
      case 'add':
        _selectPdfAndNavigate(
            context, (file) => AddPagesScreen(initialPdfFile: file));
        break;
      case 'annotate':
        _selectPdfAndNavigate(
            context, (file) => PdfAnnotationScreen(pdfFile: file));
        break;
      case 'add_password':
        _selectPdfAndNavigate(
            context, (file) => PasswordProtectScreen(initialPdfFile: file));
        break;
      case 'remove_password':
        _selectPdfAndNavigate(
            context, (file) => RemovePasswordScreen(initialPdfFile: file));
        break;
      case 'compress':
        _selectPdfAndNavigate(
            context, (file) => CompressPdfScreen(initialPdfFile: file));
        break;
      case 'extract_text':
        _selectPdfAndNavigate(
            context, (file) => ExtractTextScreen(initialPdfFile: file));
        break;
      case 'extract_images':
        _selectPdfAndNavigate(
            context, (file) => ExtractImagesScreen(initialPdfFile: file));
        break;
      case 'signature':
        _selectPdfAndNavigate(
            context, (file) => AddSignatureScreen(pdfFile: file));
        break;
      case 'watermark':
        _selectPdfAndNavigate(
            context, (file) => WatermarkScreen(initialPdfFile: file));
        break;
      case 'reorder':
        _selectPdfAndNavigate(
            context, (file) => PageReorderScreen(initialPdfFile: file));
        break;
      case 'metadata':
        _selectPdfAndNavigate(
            context, (file) => PdfMetadataScreen(initialPdfFile: file));
        break;
      case 'convert':
        _selectPdfAndNavigate(
            context, (file) => ConvertPdfScreen(initialPdfFile: file));
        break;
      default:
        break;
    }
  }

  Future<void> _selectPdfAndNavigate(
      BuildContext context, Widget Function(File) screenBuilder) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pdfFile = File(result.files.single.path!);

        // Verify the file exists
        if (await pdfFile.exists()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screenBuilder(pdfFile)),
          );
        } else {
          _showErrorSnackBar(context, 'Selected file does not exist');
        }
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error selecting PDF file: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  void _mergePdfs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MergePdfsScreen()),
    );
  }
}
