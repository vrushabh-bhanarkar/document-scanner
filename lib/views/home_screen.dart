import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../core/themes.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/interstitial_ad_helper.dart';
import '../widgets/ad_config.dart';
import '../services/pdf_service.dart';
import '../providers/subscription_provider.dart';
import 'create_pdf_screen.dart';
import '../services/scan_quota_service.dart';
import '../services/subscription_service.dart';
import 'image_to_pdf_screen.dart';
import 'edit_pdf_tab.dart';
import 'full_edit_pdf_screen.dart';
import 'convert_pdf_screen.dart';
import 'file_conversion_screen.dart';
import '../main.dart' as main;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeroSection(context),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(height: 12.h),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverToBoxAdapter(
                    child: _buildQuickActionsSection(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(height: 16.h),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverToBoxAdapter(
                    child: _buildRemoveAdsBanner(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: 100.h),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(height: 20.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  // Widget _buildHeroSection(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Document Scanner',
  //                   style: AppTextStyles.headlineLarge.copyWith(
  //                     fontWeight: FontWeight.w800,
  //                     color: AppColors.gray900,
  //                     letterSpacing: -0.5,
  //                   ),
  //                 ),
  //                 SizedBox(height: 6.h),
  //                 Text(
  //                   'Convert, scan, and manage your documents with ease',
  //                   style: AppTextStyles.bodyMedium.copyWith(
  //                     color: AppColors.gray600,
  //                     height: 1.4,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }


   Widget _buildHeroSection(BuildContext context) {
  return Container(
    width: double.infinity,
    margin: EdgeInsets.symmetric(horizontal: 1.w), // Slight breathing room
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
    decoration: BoxDecoration(
      gradient: AppColors. HeroSectionGradient,
      borderRadius: BorderRadius.circular(20.r), // More rounded for modern feel
      // boxShadow: [
      //   BoxShadow(
      //     color: AppColors.primaryBlueAccent.withOpacity(0.15),
      //     blurRadius: 8,
      //     offset: const Offset(0, 4),
      //   ),
      // ],
    ),
    child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glassmorphic Icon Container
            SizedBox(
              height: 64.r,
              width: 64.r,
    
                    child: Image.asset(
                      'assets/icons/sleekscan.png',
                      height: 60.r,
                      width: 60.r,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                  ),

            SizedBox(width: 18.w),

            // Text content with better typography
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SleekScan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Professional PDF Tools to create, edit and convert PDFs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
               SizedBox(width: 15.w),
            // Premium Floating-style Button
            _buildCreateButton(context),
          ],
        ),
  );
}
   

  Widget _buildCreateButton(BuildContext context) {
  return GestureDetector(
    onTap: () => _handleNavigation(context),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, color: AppColors.gray900, size: 16.sp),
          SizedBox(width: 6.w),
          Text(
            'New',
            style: TextStyle(
              color: AppColors.gray900,
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    ),
  );
}

  void _handleNavigation(BuildContext context) {
    // Default action: navigate to Create PDF screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePDFScreen(),
      ),
    );
  }

  Widget _premiumCtaButton() {
    // Subscription feature temporarily disabled
    return const SizedBox.shrink();
    /*
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFB800)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Colors.black, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Buy Premium',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    */
  }

  Widget _buildRemoveAdsBanner() {
    // Subscription feature temporarily disabled - always hide this banner
    return const SizedBox.shrink();

    // Subscription feature temporarily disabled - always hide this banner
    return const SizedBox.shrink();

    /*
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B).withOpacity(0.95),
                Color(0xFFEE5A52).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF6B6B).withOpacity(0.2),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {}, // Navigator.pushNamed(context, '/subscription'), // Temporarily disabled
              borderRadius: BorderRadius.circular(18.r),
              child: Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.ads_click_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ad-Free Experience',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Upgrade to Premium and enjoy uninterrupted productivity',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'No Ads',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Premium Tools',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    */
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 26.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    final quickActions = [
      {
        'icon': Icons.picture_as_pdf_rounded,
        'title': 'Create PDF',
        'subtitle': 'Create PDF document',
        'color': AppColors.primaryBlue,
        'gradient': AppColors.primaryGradientVibrant,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePDFScreen(),
              ),
            ),
      },
      {
        'icon': Icons.image_rounded,
        'title': 'Image to PDF',
        'subtitle': 'Convert images to PDF',
        'color': AppColors.emerald,
        'gradient': AppColors.emeraldGradientVibrant,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ImageToPdfScreen(),
              ),
            ),
      },
      {
        'icon': Icons.swap_horiz_rounded,
        'title': 'Convert Files',
        'subtitle': 'PDF ↔ Word',
        'color': AppColors.secondaryTeal,
        'gradient': AppColors.secondaryTealGradient,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FileConversionScreen(),
              ),
            ),
      },
      {
        'icon': Icons.edit_document,
        'title': 'Edit PDF',
        'subtitle': 'Edit existing PDFs',
        'color': AppColors.purple,
        'gradient': AppColors.purpleGradientVibrant,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditPdfTab(),
              ),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.bolt_rounded,
          title: 'Quick Actions',
          subtitle: 'Get started with these essential tools',
          color: AppColors.primaryBlue,
        ),
        SizedBox(height: 20.h),
        StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          children: List.generate(quickActions.length, (index) {
            final action = quickActions[index];
            return _buildActionCard(
              icon: action['icon'] as IconData,
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              color: action['color'] as Color,
              gradient: action['gradient'] as LinearGradient,
              onTap: action['onTap'] as VoidCallback?,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required LinearGradient gradient,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        splashColor: color.withOpacity(0.05),
        highlightColor: color.withOpacity(0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: const Color.fromARGB(255, 39, 37, 37).withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: title,
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18.r),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: color.withOpacity(0.25),
                    //     blurRadius: 8.r,
                    //     offset: Offset(0, 3.h),
                    //   ),
                    // ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                  fontSize: 17.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  height: 1.4,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.38),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConvertOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Conversion Direction',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 24.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryTealGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 24.sp),
              ),
              title: Text('PDF to Other Formats',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Convert PDF to Word, Images, Text, HTML'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConvertPdfScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryTealGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child:
                    Icon(Icons.description, color: Colors.white, size: 24.sp),
              ),
              title: Text('Word to PDF',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Convert DOCX files to PDF'),
              onTap: () {
                Navigator.pop(context);
                _convertWordToPdf(context);
              },
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  void _convertWordToPdf(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result != null && result.files.single.path != null) {
      final wordFile = File(result.files.single.path!);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text('Converting Word to PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final pdfService = PDFService();
        final pdfFile = await pdfService.convertWordToPdf(wordFile: wordFile);

        Navigator.pop(context); // Close loading dialog

        if (pdfFile != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(child: Text('Conversion Complete!')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Word document successfully converted to PDF.'),
                  SizedBox(height: 12.h),
                  Text('Saved to:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6.h),
                  Text(pdfFile.path, style: TextStyle(fontSize: 12.sp)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to convert Word to PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
