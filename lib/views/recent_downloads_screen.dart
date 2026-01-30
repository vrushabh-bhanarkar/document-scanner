import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/file_management_service.dart';
import '../core/themes.dart';

class RecentDownloadsScreen extends StatefulWidget {
  const RecentDownloadsScreen({Key? key}) : super(key: key);

  @override
  State<RecentDownloadsScreen> createState() => _RecentDownloadsScreenState();
}

class _RecentDownloadsScreenState extends State<RecentDownloadsScreen> {
  final FileManagementService _fileService = FileManagementService();
  List<Map<String, dynamic>> _recents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await _fileService.getRecentDownloads();
    setState(() {
      _recents = recents;
      _loading = false;
    });
  }

  Future<void> _deleteFile(String filePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.delete_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Delete File',
                style: AppTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this file? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gray600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _fileService.deleteRecentDownload(filePath);
      _loadRecents();
    }
  }

  Future<void> _viewFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        _showErrorSnackBar('Could not open file: ${result.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening file: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return Icons.image;
    } else if (['.pdf'].contains(extension)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      return Icons.description;
    } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.aac', '.ogg'].contains(extension)) {
      return Icons.audio_file;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return Colors.blue;
    } else if (['.pdf'].contains(extension)) {
      return Colors.red;
    } else if (['.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      return Colors.indigo;
    } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
      return Colors.purple;
    } else if (['.mp3', '.wav', '.aac', '.ogg'].contains(extension)) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Recent Downloads',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.gray700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_recents.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppColors.primaryBlue),
              onPressed: _loadRecents,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : _recents.isEmpty
              ? _buildEmptyState()
              : _buildFileList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gray100,
                    AppColors.gray50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.gray200,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.download_done_rounded,
                size: 80,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Recent Downloads',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Files you download will appear here',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      itemCount: _recents.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final fileData = _recents[index];
        final filePath = fileData['path'] as String;
        final modified = fileData['modified'] as DateTime;
        final fileName = filePath.split(Platform.pathSeparator).last;
        final fileIcon = _getFileIcon(filePath);
        final fileColor = _getFileColor(filePath);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fileColor.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: AppShadows.cardShadow,
          ),
          child: InkWell(
            onTap: () => _viewFile(filePath),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fileColor.withOpacity(0.15),
                          fileColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: fileColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      fileIcon,
                      color: fileColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: fileName,
                          child: Text(
                            fileName.length > 35 ? '${fileName.substring(0, 32)}...' : fileName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 13, color: AppColors.gray500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Modified: ${modified.toString().split('.')[0]}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gray600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.folder_rounded, size: 13, color: AppColors.gray500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                filePath,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gray500,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert_rounded, color: AppColors.gray600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'open') {
                        _viewFile(filePath);
                      } else if (value == 'delete') {
                        _deleteFile(filePath);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 20, color: AppColors.primaryBlue),
                            const SizedBox(width: 12),
                            Text('Open', style: AppTextStyles.labelLarge),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                size: 20, color: AppColors.error),
                            const SizedBox(width: 12),
                            Text('Delete',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
