import 'package:flutter/material.dart';
import '../core/themes.dart';
import '../widgets/app_buttons.dart';
import '../widgets/native_ad_widget.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({Key? key}) : super(key: key);

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  late List<Map<String, dynamic>> pages;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    // Mock data - replace with actual page data
    pages = List.generate(
      5,
      (index) => {
        'id': index,
        'name': 'Page ${index + 1}',
        'thumbnail': 'path/to/thumbnail',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Pages'),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AppMiniButton(
              label: _isReorderMode ? 'Done' : 'Reorder',
              icon: _isReorderMode ? Icons.check : Icons.drag_indicator,
              onPressed: () {
                setState(() {
                  _isReorderMode = !_isReorderMode;
                });
              },
              backgroundColor: _isReorderMode
                  ? AppColors.emerald.withOpacity(0.1)
                  : AppColors.primaryBlueExtraLight,
              textColor:
                  _isReorderMode ? AppColors.emerald : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pages Grid
          Expanded(
            child:
                _isReorderMode ? _buildReorderableGrid() : _buildNormalGrid(),
          ),

          // Native Ad
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NativeAdWidget(),
          ),

          // Bottom Actions
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Add Page',
                          icon: Icons.add,
                          onPressed: () {
                            Navigator.of(context).pushNamed('/scanner');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Extract OCR',
                          icon: Icons.text_fields,
                          onPressed: () {
                            _showOCRDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: 'Continue to Export',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.of(context).pushNamed('/export-settings');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return _buildPageCard(index, pages[index]);
      },
    );
  }

  Widget _buildReorderableGrid() {
    return ReorderableGridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = pages.removeAt(oldIndex);
          pages.insert(newIndex, item);
        });
      },
      children: List.generate(
        pages.length,
        (index) => Container(
          key: ValueKey(pages[index]['id']),
          child: _buildPageCard(index, pages[index], isReorderable: true),
        ),
      ),
    );
  }

  Widget _buildPageCard(int index, Map<String, dynamic> page,
      {bool isReorderable = false}) {
    return GestureDetector(
      onLongPress: isReorderable ? null : () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200, width: 1),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Page Thumbnail
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      page['name'],
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            // Delete Button (top right)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    pages.removeAt(index);
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Page Number (bottom left)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Reorder Icon (center)
            if (isReorderable)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOCRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Extract Text (OCR)'),
          content: const Text(
            'This will extract all text from the pages using offline OCR. This may take a moment...',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text extracted successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Extract'),
            ),
          ],
        );
      },
    );
  }
}

// Simple ReorderableGridView implementation
class ReorderableGridView extends StatelessWidget {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final List<Widget> children;
  final Function(int oldIndex, int newIndex) onReorder;

  const ReorderableGridView.count({
    Key? key,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.childAspectRatio,
    required this.children,
    required this.onReorder,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 20,
          child: child,
        );
      },
      onReorder: onReorder,
      children: children,
    );
  }
}
