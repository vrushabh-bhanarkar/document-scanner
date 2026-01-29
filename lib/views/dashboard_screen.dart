import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/themes.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import '../widgets/app_buttons.dart';
import '../widgets/native_ad_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentModel> _filteredDocuments = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      final provider = context.read<DocumentProvider>();
      _filteredDocuments = provider.documents
          .where((doc) => doc.title.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Documents',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.gray900,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.15),
                      AppColors.primaryBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'View All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, documentProvider, _) {
          final docs = _searchController.text.isEmpty
              ? documentProvider.documents
              : _filteredDocuments;

          return Column(
            children: [
              // Enhanced Search Bar
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                        spreadRadius: -4.r,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.gray400),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.gray400, size: 22.sp),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: Icon(Icons.clear_rounded,
                                  color: AppColors.gray400, size: 22.sp),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.gray50,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide:
                            const BorderSide(color: AppColors.gray200, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide:
                            const BorderSide(color: AppColors.gray200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                            color: AppColors.primaryBlue, width: 2.w),
                      ),
                    ),
                  ),
                ),
              ),
              // Native Ad
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: NativeAdWidget(),
              ),
              // Documents List
              Expanded(
                child: docs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _buildDocumentTile(docs[index], context);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to scanner screen
          Navigator.of(context).pushNamed('/scanner');
        },
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Scan Now'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 30.r,
                  offset: Offset(0, 12.h),
                  spreadRadius: -8.r,
                ),
              ],
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              size: 60.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            'No Documents Yet',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: 22.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Scan your first document to get started.\nYour documents will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray500,
                height: 1.6,
                fontSize: 15.sp,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          AppPrimaryButton(
            label: 'Start Scanning',
            icon: Icons.camera_alt_rounded,
            onPressed: () {
              Navigator.of(context).pushNamed('/scanner');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(DocumentModel document, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.gray200, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
            spreadRadius: -2.r,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to document viewer
            Navigator.of(context).pushNamed('/pdf-viewer', arguments: document);
          },
          onLongPress: () {
            _showDocumentMenu(context, document);
          },
          borderRadius: BorderRadius.circular(18.r),
          splashColor: AppColors.primaryBlue.withOpacity(0.1),
          highlightColor: AppColors.primaryBlue.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 70.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.15),
                        AppColors.primaryBlue.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.12),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primaryBlue,
                    size: 40.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 13.sp, color: AppColors.gray400),
                          SizedBox(width: 4.w),
                          Text(
                            _formatDate(document.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gray500,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(Icons.storage_rounded,
                              size: 13.sp, color: AppColors.gray400),
                          SizedBox(width: 4.w),
                          Text(
                            _formatFileSize(document.pdfPath?.length ??
                                document.imagePath.length),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gray500,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryBlue,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentMenu(BuildContext context, DocumentModel document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primaryBlue),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, document);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: AppColors.primaryBlue),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, document);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, DocumentModel document) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Implement rename logic
                Navigator.pop(context);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: Text(
              'Are you sure you want to delete "${document.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<DocumentProvider>().deleteDocument(document.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
