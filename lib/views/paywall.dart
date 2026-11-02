import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../core/themes.dart';
import '../providers/subscription_provider.dart';

/// Full-featured Paywall supporting both RevenueCatUI Native Paywalls
/// and a high-converting in-app fallback UI with Lifetime, Yearly, and Monthly packages.
class PaywallScreen extends StatefulWidget {
  final bool autoPresentRevenueCatPaywall;

  const PaywallScreen({
    super.key,
    this.autoPresentRevenueCatPaywall = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Package? _selectedPackage;
  bool _hasAttemptedAutoPresent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subProvider = context.read<SubscriptionProvider>();
      // Auto-select Yearly by default or first available
      setState(() {
        _selectedPackage = subProvider.yearlyPackage ??
            subProvider.lifetimePackage ??
            subProvider.monthlyPackage;
      });

      // Optionally auto-present RevenueCat UI native paywall if requested
      if (widget.autoPresentRevenueCatPaywall && !_hasAttemptedAutoPresent) {
        _hasAttemptedAutoPresent = true;
        _presentRemotePaywall();
      }
    });
  }

  Future<void> _presentRemotePaywall() async {
    final subProvider = context.read<SubscriptionProvider>();
    final result = await subProvider.presentPaywall();
    if (!mounted) return;

    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to Void Version Pro!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handlePurchase(Package package) async {
    final subProvider = context.read<SubscriptionProvider>();
    final success = await subProvider.purchase(package);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Purchase successful! You now have Pro access.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (subProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${subProvider.errorMessage}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final subProvider = context.read<SubscriptionProvider>();
    final isPro = await subProvider.restorePurchases();

    if (!mounted) return;

    if (isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Purchases restored successfully! Pro access active.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscriptions found to restore.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final isPro = subProvider.isPro;
        final isProcessing = subProvider.isProcessing;

        // Auto-select package if not yet set
        _selectedPackage ??= subProvider.yearlyPackage ??
            subProvider.lifetimePackage ??
            subProvider.monthlyPackage;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.gray900),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : _handleRestore,
                child: const Text('Restore', style: TextStyle(color: AppColors.primaryBlue)),
              ),
            ],
          ),
          body: isProcessing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connecting with App Store...'),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pro Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: AppColors.primaryBlue, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'VOID VERSION PRO',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          isPro ? 'You are a Pro Member' : 'Unlock Everything',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPro
                              ? 'Enjoy all unlimited premium scanning and OCR tools.'
                              : 'Unlimited high-res scans, offline OCR text extraction, watermarks removal, and zero ads.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Features List
                        _buildFeatureRow(Icons.check_circle, 'Unlimited PDF Scans & Exports'),
                        _buildFeatureRow(Icons.check_circle, 'On-device OCR Text Extraction'),
                        _buildFeatureRow(Icons.check_circle, 'Remove All Watermarks'),
                        _buildFeatureRow(Icons.check_circle, '100% Ad-Free Experience'),
                        _buildFeatureRow(Icons.check_circle, 'Cloud Backup & Cross-Platform Sync'),
                        const SizedBox(height: 24),

                        // If already pro, show Customer Center management button
                        if (isPro) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Entitlement: void_version_pro Active',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => subProvider.presentCustomerCenter(),
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Manage Subscription (Customer Center)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Offerings Cards (Yearly, Lifetime, Monthly)
                          _buildPackageCard(
                            package: subProvider.yearlyPackage,
                            fallbackTitle: 'Yearly Plan',
                            fallbackPrice: '\$29.99 / year',
                            badge: 'BEST VALUE',
                            subtitle: 'Billed annually. Cancel anytime.',
                          ),
                          const SizedBox(height: 12),
                          _buildPackageCard(
                            package: subProvider.lifetimePackage,
                            fallbackTitle: 'Lifetime Access',
                            fallbackPrice: '\$79.99 one-time',
                            badge: 'ONE-TIME',
                            subtitle: 'Pay once, unlock Pro forever.',
                          ),
                          const SizedBox(height: 12),
                          _buildPackageCard(
                            package: subProvider.monthlyPackage,
                            fallbackTitle: 'Monthly Plan',
                            fallbackPrice: '\$4.99 / month',
                            subtitle: 'Billed monthly. Cancel anytime.',
                          ),
                          const SizedBox(height: 24),

                          // Purchase Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _selectedPackage == null
                                  ? null
                                  : () => _handlePurchase(_selectedPackage!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _selectedPackage != null
                                    ? 'Continue with ${_selectedPackage!.storeProduct.title.isNotEmpty ? _selectedPackage!.storeProduct.title : _selectedPackage!.identifier}'
                                    : 'Select a Plan',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Open Remote Paywall Button (Alternative)
                          TextButton.icon(
                            onPressed: _presentRemotePaywall,
                            icon: const Icon(Icons.palette_outlined, size: 16),
                            label: const Text('View RevenueCat Native Paywall'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.gray700),
                          ),
                        ],

                        const SizedBox(height: 20),
                        // Legal Footer
                        Text(
                          'Payment will be charged to your store account upon confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours prior to the end of the billing period.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.gray800, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required Package? package,
    required String fallbackTitle,
    required String fallbackPrice,
    String? badge,
    required String subtitle,
  }) {
    final isSelected = package != null && _selectedPackage == package;
    final title = package?.storeProduct.title.isNotEmpty == true
        ? package!.storeProduct.title
        : fallbackTitle;
    final price = package?.storeProduct.priceString ?? fallbackPrice;

    return GestureDetector(
      onTap: package == null
          ? null
          : () {
              setState(() {
                _selectedPackage = package;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
