// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'pdf_annotation_screen.dart';
// import 'rotate_pages_screen.dart';
// import 'delete_pages_screen.dart';
// import 'add_pages_screen.dart';
// import 'password_protect_screen.dart';
// import 'compress_pdf_screen.dart';
// import 'extract_text_screen.dart';
// import 'extract_images_screen.dart';
// import 'watermark_screen.dart';
// import 'page_reorder_screen.dart';
// import 'pdf_metadata_screen.dart';
// import 'convert_pdf_screen.dart';
// import 'split_pdf_screen.dart';
// import '../widgets/banner_ad_widget.dart';

// class FullEditPdfScreen extends StatefulWidget {
//   const FullEditPdfScreen({Key? key}) : super(key: key);

//   @override
//   State<FullEditPdfScreen> createState() => _FullEditPdfScreenState();
// }

// class _FullEditPdfScreenState extends State<FullEditPdfScreen>
//     with TickerProviderStateMixin {
//   File? _selectedPdf;
//   bool _isLoading = false;
//   int _totalPages = 0;
//   int _currentPage = 0;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   PDFViewController? _pdfViewController;

//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//   }

//   void _setupAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
//     );

//     _fadeController.forward();
//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   Future<void> _importPdf() async {
//     try {
//       setState(() => _isLoading = true);

//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//         allowMultiple: false,
//       );

//       if (result != null && result.files.single.path != null) {
//         final pdfFile = File(result.files.single.path!);

//         if (await pdfFile.exists()) {
//           setState(() {
//             _selectedPdf = pdfFile;
//             _isLoading = false;
//           });
//         } else {
//           _showErrorSnackBar('Selected file does not exist');
//           setState(() => _isLoading = false);
//         }
//       } else {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error selecting PDF file: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8.r),
//         ),
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFF10B981),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8.r),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleToolAction(String action) async {
//     if (_selectedPdf == null) {
//       _showErrorSnackBar('Please import a PDF first');
//       return;
//     }

//     dynamic result;
    
//     switch (action) {
//       case 'split':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => SplitPdfScreen(pdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'rotate':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   RotatePagesScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'delete':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   DeletePagesScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'add':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   AddPagesScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'annotate':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   PdfAnnotationScreen(pdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'add_password':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   PasswordProtectScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'compress':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   CompressPdfScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'extract_text':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   ExtractTextScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'extract_images':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   ExtractImagesScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'watermark':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   WatermarkScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'reorder':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   PageReorderScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'metadata':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   PdfMetadataScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       case 'convert':
//         result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   ConvertPdfScreen(initialPdfFile: _selectedPdf!)),
//         );
//         break;
//       default:
//         break;
//     }

//     // Handle result from tool screen
//     if (result != null) {
//       if (result is File) {
//         // Update PDF if a new file was returned
//         setState(() {
//           _selectedPdf = result;
//           _currentPage = 0;
//         });
//         _showSuccessSnackBar('✓ Changes applied! You can continue editing');
//       } else if (result == true) {
//         // Operation successful but no new file returned
//         _showSuccessSnackBar('✓ Operation completed! Continue editing');
//         // Refresh the PDF view
//         _refreshPdfView();
//       } else if (result is String) {
//         // Custom success message
//         _showSuccessSnackBar('✓ $result');
//       }
//     }
//   }

//   void _refreshPdfView() {
//     // Refresh the PDF view by resetting the page
//     if (_pdfViewController != null && _currentPage >= 0) {
//       _pdfViewController!.setPage(_currentPage);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.auto_fix_high_rounded,
//               color: const Color(0xFF667EEA),
//               size: 24.sp,
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               'Full Edit PDF',
//               style: TextStyle(
//                 fontSize: 20.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1E293B),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (_selectedPdf != null) ...[
//             IconButton(
//               icon: Icon(Icons.refresh_rounded,
//                   color: const Color(0xFF667EEA), size: 22.sp),
//               onPressed: () {
//                 _refreshPdfView();
//                 _showSuccessSnackBar('PDF view refreshed');
//               },
//               tooltip: 'Refresh View',
//             ),
//             IconButton(
//               icon: Icon(Icons.close_rounded,
//                   color: const Color(0xFFEF4444), size: 24.sp),
//               onPressed: () {
//                 setState(() {
//                   _selectedPdf = null;
//                   _totalPages = 0;
//                   _currentPage = 0;
//                 });
//               },
//               tooltip: 'Clear PDF',
//             ),
//           ],
//         ],
//       ),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: SlideTransition(
//           position: _slideAnimation,
//           child: _selectedPdf == null
//               ? _buildImportSection()
//               : _buildEditSection(),
//         ),
//       ),
//       bottomNavigationBar: const BannerAdWidget(),
//     );
//   }

//   Widget _buildImportSection() {
//     return Center(
//       child: SingleChildScrollView(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 160.w,
//               height: 160.h,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     const Color(0xFF667EEA).withOpacity(0.1),
//                     const Color(0xFF764BA2).withOpacity(0.1),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(80.r),
//               ),
//               child: Icon(
//                 Icons.cloud_upload_rounded,
//                 size: 80.sp,
//                 color: const Color(0xFF667EEA),
//               ),
//             ),
//             SizedBox(height: 32.h),
//             Text(
//               'Import PDF to Edit',
//               style: TextStyle(
//                 fontSize: 28.sp,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1E293B),
//                 letterSpacing: -0.5,
//               ),
//             ),
//             SizedBox(height: 12.h),
//             Text(
//               'Select a PDF file and access all editing\ntools in one convenient screen',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 color: const Color(0xFF64748B),
//                 height: 1.5,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 48.h),
//             _isLoading
//                 ? const CircularProgressIndicator(
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
//                   )
//                 : ElevatedButton.icon(
//                     onPressed: _importPdf,
//                     icon: Icon(Icons.folder_open_rounded, size: 24.sp),
//                     label: Padding(
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 16.w, vertical: 16.h),
//                       child: Text(
//                         'Select PDF File',
//                         style: TextStyle(
//                           fontSize: 18.sp,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF667EEA),
//                       foregroundColor: Colors.white,
//                       elevation: 8,
//                       shadowColor: const Color(0xFF667EEA).withOpacity(0.4),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.r),
//                       ),
//                     ),
//                   ),
//             SizedBox(height: 16.h),
//             Text(
//               'Supported format: PDF',
//               style: TextStyle(
//                 fontSize: 13.sp,
//                 color: const Color(0xFF94A3B8),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEditSection() {
//     return Column(
//       children: [
//         // PDF Preview Section
//         Container(
//           margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
//           height: 240.h,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 24,
//                 offset: const Offset(0, 4),
//                 spreadRadius: 0,
//               ),
//               BoxShadow(
//                 color: const Color(0xFF667EEA).withOpacity(0.08),
//                 blurRadius: 32,
//                 offset: const Offset(0, 8),
//                 spreadRadius: -4,
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20.r),
//             child: Column(
//               children: [
//                 // PDF Info Header
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         const Color(0xFF667EEA),
//                         const Color(0xFF764BA2),
//                       ],
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(8.w),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(10.r),
//                         ),
//                         child: Icon(
//                           Icons.picture_as_pdf_rounded,
//                           color: Colors.white,
//                           size: 20.sp,
//                         ),
//                       ),
//                       SizedBox(width: 12.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _selectedPdf!.path.split(Platform.pathSeparator).last,
//                               style: TextStyle(
//                                 fontSize: 13.sp,
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.white,
//                                 letterSpacing: 0.2,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             if (_totalPages > 0) ...[
//                               SizedBox(height: 2.h),
//                               Text(
//                                 'Page ${_currentPage + 1} of $_totalPages',
//                                 style: TextStyle(
//                                   fontSize: 11.sp,
//                                   color: Colors.white.withOpacity(0.85),
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12.r),
//                         ),
//                         child: Text(
//                           'Preview',
//                           style: TextStyle(
//                             fontSize: 10.sp,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // PDF Viewer
//                 Expanded(
//                   child: PDFView(
//                     filePath: _selectedPdf!.path,
//                     enableSwipe: true,
//                     swipeHorizontal: false,
//                     autoSpacing: false,
//                     pageFling: true,
//                     onRender: (pages) {
//                       setState(() {
//                         _totalPages = pages ?? 0;
//                       });
//                     },
//                     onViewCreated: (PDFViewController controller) {
//                       _pdfViewController = controller;
//                     },
//                     onPageChanged: (int? page, int? total) {
//                       setState(() {
//                         _currentPage = page ?? 0;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Info Banner
//         Container(
//           margin: EdgeInsets.symmetric(horizontal: 16.w),
//           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 const Color(0xFF667EEA).withOpacity(0.08),
//                 const Color(0xFF764BA2).withOpacity(0.08),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(12.r),
//             border: Border.all(
//               color: const Color(0xFF667EEA).withOpacity(0.2),
//               width: 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.info_outline_rounded,
//                 color: const Color(0xFF667EEA),
//                 size: 18.sp,
//               ),
//               SizedBox(width: 10.w),
//               Expanded(
//                 child: Text(
//                   'Make multiple changes without re-importing',
//                   style: TextStyle(
//                     fontSize: 11.sp,
//                     color: const Color(0xFF1E293B),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 12.h),

//         // Editing Tools Section
//         Expanded(
//           child: Container(
//             margin: EdgeInsets.symmetric(horizontal: 16.w),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(8.w),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               const Color(0xFF667EEA).withOpacity(0.15),
//                               const Color(0xFF764BA2).withOpacity(0.15),
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(10.r),
//                         ),
//                         child: Icon(
//                           Icons.build_circle_rounded,
//                           color: const Color(0xFF667EEA),
//                           size: 20.sp,
//                         ),
//                       ),
//                       SizedBox(width: 12.w),
//                       Text(
//                         'Editing Tools',
//                         style: TextStyle(
//                           fontSize: 20.sp,
//                           fontWeight: FontWeight.w800,
//                           color: const Color(0xFF1E293B),
//                           letterSpacing: -0.3,
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF667EEA).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12.r),
//                         ),
//                         child: Text(
//                           '13 tools',
//                           style: TextStyle(
//                             fontSize: 11.sp,
//                             fontWeight: FontWeight.w600,
//                             color: const Color(0xFF667EEA),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 12.h),
//                 Expanded(
//                   child: _buildToolsGrid(),
//                 ),
//                 SizedBox(height: 8.h),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildToolsGrid() {
//     final tools = [
//       {
//         'title': 'Split',
//         'subtitle': 'Divide pages',
//         'icon': Icons.content_cut_rounded,
//         'color': const Color(0xFFEF4444),
//         'action': 'split'
//       },
//       {
//         'title': 'Rotate',
//         'subtitle': 'Change orientation',
//         'icon': Icons.rotate_right_rounded,
//         'color': const Color(0xFF8B5CF6),
//         'action': 'rotate'
//       },
//       {
//         'title': 'Delete',
//         'subtitle': 'Remove pages',
//         'icon': Icons.delete_outline_rounded,
//         'color': const Color(0xFFEC4899),
//         'action': 'delete'
//       },
//       {
//         'title': 'Add',
//         'subtitle': 'Insert pages',
//         'icon': Icons.add_circle_outline_rounded,
//         'color': const Color(0xFF06B6D4),
//         'action': 'add'
//       },
//       {
//         'title': 'Annotate',
//         'subtitle': 'Add notes',
//         'icon': Icons.edit_rounded,
//         'color': const Color(0xFF6366F1),
//         'action': 'annotate'
//       },
//       {
//         'title': 'Password',
//         'subtitle': 'Add security',
//         'icon': Icons.lock_rounded,
//         'color': const Color(0xFFF59E0B),
//         'action': 'add_password'
//       },
//       {
//         'title': 'Compress',
//         'subtitle': 'Reduce size',
//         'icon': Icons.compress_rounded,
//         'color': const Color(0xFF8B5A3C),
//         'action': 'compress'
//       },
//       {
//         'title': 'Text',
//         'subtitle': 'Extract text',
//         'icon': Icons.text_fields_rounded,
//         'color': const Color(0xFF3B82F6),
//         'action': 'extract_text'
//       },
//       {
//         'title': 'Images',
//         'subtitle': 'Extract images',
//         'icon': Icons.image_rounded,
//         'color': const Color(0xFF059669),
//         'action': 'extract_images'
//       },
//       {
//         'title': 'Watermark',
//         'subtitle': 'Brand protection',
//         'icon': Icons.water_drop_rounded,
//         'color': const Color(0xFF0EA5E9),
//         'action': 'watermark'
//       },
//       {
//         'title': 'Reorder',
//         'subtitle': 'Rearrange',
//         'icon': Icons.reorder_rounded,
//         'color': const Color(0xFFF59E0B),
//         'action': 'reorder'
//       },
//       {
//         'title': 'Metadata',
//         'subtitle': 'Edit info',
//         'icon': Icons.info_outline_rounded,
//         'color': const Color(0xFF64748B),
//         'action': 'metadata'
//       },
//       {
//         'title': 'Convert',
//         'subtitle': 'Change format',
//         'icon': Icons.transform_rounded,
//         'color': const Color(0xFFDC2626),
//         'action': 'convert'
//       },
//     ];

//     return GridView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: EdgeInsets.only(bottom: 8.h),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 10.w,
//         mainAxisSpacing: 10.h,
//         childAspectRatio: 0.88,
//       ),
//       itemCount: tools.length,
//       itemBuilder: (context, index) {
//         final tool = tools[index];
//         return _buildCompactToolCard(
//           title: tool['title'] as String,
//           subtitle: tool['subtitle'] as String,
//           icon: tool['icon'] as IconData,
//           color: tool['color'] as Color,
//           onTap: () => _handleToolAction(tool['action'] as String),
//         );
//       },
//     );
//   }

//   Widget _buildCompactToolCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18.r),
//         splashColor: color.withOpacity(0.15),
//         highlightColor: color.withOpacity(0.08),
//         child: Ink(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//                 spreadRadius: 0,
//               ),
//               BoxShadow(
//                 color: color.withOpacity(0.12),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//                 spreadRadius: -6,
//               ),
//             ],
//             border: Border.all(
//               color: color.withOpacity(0.12),
//               width: 1.5,
//             ),
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(10.w),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         color.withOpacity(0.15),
//                         color.withOpacity(0.08),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: color,
//                     size: 22.sp,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.w700,
//                     color: const Color(0xFF1E293B),
//                     letterSpacing: 0.1,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 3.h),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 9.sp,
//                     color: const Color(0xFF64748B),
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
