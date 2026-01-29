import 'package:flutter/material.dart';
import 'dart:io';
import '../core/themes.dart';
import '../widgets/app_buttons.dart';

enum FilterType {
  none,
  magicColor,
  blackAndWhite,
  grayscale,
  highContrast,
}

class ReviewFilterScreen extends StatefulWidget {
  final String imagePath;

  const ReviewFilterScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<ReviewFilterScreen> createState() => _ReviewFilterScreenState();
}

class _ReviewFilterScreenState extends State<ReviewFilterScreen> {
  late FilterType _selectedFilter;
  bool _showCropMode = false;
  Offset _topLeftCrop = const Offset(0, 0);
  Offset _bottomRightCrop = const Offset(1, 1);

  @override
  void initState() {
    super.initState();
    _selectedFilter = FilterType.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review & Filter'),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Container(
              color: AppColors.gray50,
              child: Center(
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Filter Presets - Horizontal Scroll
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter Presets',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterPreset(
                        label: 'Original',
                        icon: Icons.image,
                        filterType: FilterType.none,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPreset(
                        label: 'Magic Color',
                        icon: Icons.auto_fix_high,
                        filterType: FilterType.magicColor,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPreset(
                        label: 'B&W',
                        icon: Icons.contrast,
                        filterType: FilterType.blackAndWhite,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPreset(
                        label: 'Grayscale',
                        icon: Icons.wb_cloudy,
                        filterType: FilterType.grayscale,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterPreset(
                        label: 'High Contrast',
                        icon: Icons.brightness_high,
                        filterType: FilterType.highContrast,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crop Mode Toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCropMode = !_showCropMode;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _showCropMode
                          ? AppColors.primaryBlueExtraLight
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showCropMode
                            ? AppColors.primaryBlue
                            : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.crop,
                          color: _showCropMode
                              ? AppColors.primaryBlue
                              : AppColors.gray600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Manual Crop',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _showCropMode
                                ? AppColors.primaryBlue
                                : AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Retake',
                        icon: Icons.refresh,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Continue',
                        icon: Icons.check_circle,
                        onPressed: () {
                          Navigator.of(context).pushNamed('/document-manage');
                        },
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

  Widget _buildFilterPreset({
    required String label,
    required IconData icon,
    required FilterType filterType,
  }) {
    final isSelected = _selectedFilter == filterType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterType;
        });
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primaryBlue,
                      width: 2,
                    )
                  : Border.all(
                      color: AppColors.gray200,
                      width: 1,
                    ),
              boxShadow: isSelected ? AppShadows.cardShadow : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.gray700,
              size: 32,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primaryBlue : AppColors.gray600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
