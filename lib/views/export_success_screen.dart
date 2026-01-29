import 'package:flutter/material.dart';
import '../core/themes.dart';
import '../widgets/app_buttons.dart';

class ExportSuccessScreen extends StatefulWidget {
  const ExportSuccessScreen({Key? key}) : super(key: key);

  @override
  State<ExportSuccessScreen> createState() => _ExportSuccessScreenState();
}

class _ExportSuccessScreenState extends State<ExportSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Checkmark Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Success Message
                  Text(
                    'PDF Created Successfully!',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Your document is ready to share or save. Check your downloads folder.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.gray600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // File Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('File Name', 'Invoice_2026_01_07.pdf'),
                        const SizedBox(height: 12),
                        _buildInfoRow('File Size', '2.4 MB'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Pages', '5'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Status', 'Password Protected ✓',
                            valueColor: AppColors.emerald),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSecondaryButton(
                    label: 'Share PDF',
                    icon: Icons.share,
                    width: double.infinity,
                    onPressed: () {
                      // Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing PDF...')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Back to Home',
                    icon: Icons.home,
                    width: double.infinity,
                    onPressed: () {
                      Navigator.of(context)
                          .popUntil(ModalRoute.withName('/dashboard'));
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTertiaryButton(
                    label: 'Scan Another Document',
                    icon: Icons.add_circle_outline,
                    width: double.infinity,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/scanner');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.gray900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
