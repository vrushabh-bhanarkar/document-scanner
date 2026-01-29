import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;
import '../core/themes.dart';
import 'create_pdf_tab.dart';
import 'edit_pdf_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CreatePdfTab(),
    const EditPdfTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withOpacity(0.12),
              spreadRadius: 0,
              blurRadius: 24.r,
              offset: Offset(0, -6.h),
            ),
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 12.r,
              offset: Offset(0, -2.h),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.gray200,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 76.h,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              indicatorColor: AppColors.primaryBlue.withOpacity(0.12),
              destinations: [
                NavigationDestination(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.picture_as_pdf_outlined,
                        size: 26.sp, color: AppColors.gray600),
                  ),
                  selectedIcon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.15),
                          AppColors.primaryBlue.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 26.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  label: 'Create PDF',
                ),
                NavigationDestination(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.edit_outlined,
                        size: 26.sp, color: AppColors.gray600),
                  ),
                  selectedIcon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.15),
                          AppColors.primaryBlue.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 26.sp,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  label: 'Edit PDF',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
