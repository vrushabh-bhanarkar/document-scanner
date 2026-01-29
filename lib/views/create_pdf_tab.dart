import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/themes.dart';
import 'create_pdf_screen.dart';
import 'image_to_pdf_screen.dart';

class CreatePdfTab extends StatefulWidget {
  const CreatePdfTab({Key? key}) : super(key: key);

  @override
  State<CreatePdfTab> createState() => _CreatePdfTabState();
}

class _CreatePdfTabState extends State<CreatePdfTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Modern App Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create PDF',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // Compact Hero Section
                            _buildCompactHeroSection(),
                            SizedBox(height: 30.h),

                            // Main Options Section
                            Expanded(
                              child: _buildMainOptionsSection(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlueLight,
            const Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 40.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Create Professional PDFs',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose your preferred method',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Choose an Option',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        SizedBox(height: 20.h),

        // Grid of 4 options (2x2)
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 16.w,
            childAspectRatio: 1.1,
            children: [
              // Create PDF Option
              _buildGridOptionCard(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Create PDF',
                subtitle: 'New document',
                gradient: AppColors.primaryGradient,
                onTap: _createPdf,
              ),

              // Image to PDF Option
              _buildGridOptionCard(
                icon: Icons.image_rounded,
                title: 'Image to PDF',
                subtitle: 'Convert images',
                gradient: AppColors.emeraldGradient,
                onTap: _imageToPdf,
              ),

              // Scan Document Option
              _buildGridOptionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Scan Document',
                subtitle: 'Use camera',
                gradient: AppColors.purpleGradient,
                onTap: _scanDocument,
              ),

              // Edit PDF Option
              _buildGridOptionCard(
                icon: Icons.edit_document,
                title: 'Edit PDF',
                subtitle: 'Modify existing',
                gradient: AppColors.amberGradient,
                onTap: _editPdf,
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h), // Bottom padding
      ],
    );
  }

  // Action Methods
  void _createPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePDFScreen(),
      ),
    );
  }

  void _imageToPdf() {
    // Navigate directly to ImageToPdfScreen instead of picking images first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageToPdfScreen(),
      ),
    );
  }

  void _scanDocument() {
    // Navigate to the scan document functionality
    // Since we're in a tabbed structure, we can use a callback to change tabs
    _showTabNavigationDialog('Scan Document', 2);
  }

  void _editPdf() {
    // Navigate to the edit PDF functionality
    _showTabNavigationDialog('Edit PDF', 1);
  }

  void _showTabNavigationDialog(String feature, int tabIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          feature,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This feature is available in the ${feature == 'Scan Document' ? 'Scan' : 'Edit PDF'} tab. Would you like to go there?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // You can implement tab switching logic here
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Please switch to the ${feature == 'Scan Document' ? 'Scan' : 'Edit PDF'} tab'),
                  backgroundColor: AppColors.primaryBlue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.gray200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray600,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
