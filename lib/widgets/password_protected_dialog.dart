import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordProtectedPdfDialog {
  static void show(BuildContext context, {String? toolName}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange, size: 24.sp),
            SizedBox(width: 12.w),
            const Text('Password Protected PDF'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              toolName != null
                  ? 'This PDF is password protected and cannot be $toolName directly.'
                  : 'This PDF is password protected.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Steps to proceed:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildStep('1', 'Go to "Remove Password" tool'),
                  SizedBox(height: 6.h),
                  _buildStep('2', 'Unlock your PDF with the password'),
                  SizedBox(height: 6.h),
                  _buildStep('3', 'Then use this tool on the unlocked PDF'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to tools
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static bool isPasswordError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('password') ||
        errorMessage.contains('encrypted') ||
        errorMessage.contains('cannot open an encrypted document') ||
        errorMessage.contains('invalid argument (password)');
  }
}
