import 'package:flutter/material.dart';
import '../core/themes.dart';
import '../widgets/app_buttons.dart';

enum PDFQuality {
  low,
  medium,
  high,
}

class ExportSettingsScreen extends StatefulWidget {
  const ExportSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  PDFQuality _selectedQuality = PDFQuality.high;
  bool _enablePasswordProtection = false;
  String _password = '';
  String _confirmPassword = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Settings'),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF Quality Section
            Text(
              'PDF Quality',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildQualityOption(
              PDFQuality.low,
              'Low Quality',
              'Smaller file size (~0.5 MB)',
              'Fast to share, but lower resolution',
            ),
            const SizedBox(height: 12),
            _buildQualityOption(
              PDFQuality.medium,
              'Medium Quality',
              'Medium file size (~1-2 MB)',
              'Balanced quality and size',
            ),
            const SizedBox(height: 12),
            _buildQualityOption(
              PDFQuality.high,
              'High Quality',
              'Larger file size (~3-5 MB)',
              'Best for printing and archiving',
            ),
            const SizedBox(height: 32),

            // Password Protection Section
            Text(
              'Security',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _enablePasswordProtection = !_enablePasswordProtection;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _enablePasswordProtection
                        ? AppColors.primaryBlue
                        : AppColors.gray200,
                  ),
                  boxShadow:
                      _enablePasswordProtection ? AppShadows.cardShadow : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _enablePasswordProtection
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: _enablePasswordProtection
                              ? AppColors.primaryBlue
                              : AppColors.gray300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _enablePasswordProtection
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Protect PDF',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lock PDF with a password',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_enablePasswordProtection) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  label: const Text('Password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm password',
                  label: const Text('Confirm Password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onChanged: (value) {
                  setState(() {
                    _confirmPassword = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 32),

            // Pro Features Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryTealGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to Pro',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remove watermarks & unlock advanced features',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Pro upgrade coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.secondaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Learn More'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            AppSecondaryButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Save & Export',
              icon: Icons.download,
              width: double.infinity,
              onPressed: _validateAndExport,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(
    PDFQuality quality,
    String title,
    String subtitle,
    String description,
  ) {
    final isSelected = _selectedQuality == quality;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuality = quality;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primaryBlueExtraLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.cardShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.gray300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndExport() {
    // Validate password if enabled
    if (_enablePasswordProtection) {
      if (_password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a password')),
        );
        return;
      }
      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      if (_password.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password must be at least 4 characters')),
        );
        return;
      }
    }

    // Show success and navigate to success screen
    Navigator.of(context).pushNamed('/export-success');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
