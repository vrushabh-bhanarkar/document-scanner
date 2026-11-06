import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';

/// Modern SleekScan Pro Paywall Screen
/// Presenting:
/// - Monthly: sleekscan_pro_monthly
/// - Annual: sleekscan_pro_annual
/// Gating: Watermark removal, Cloud Sync, and Web Dashboard export.
class PaywallScreen extends StatefulWidget {
  final bool autoPresentRevenueCatPaywall;

  const PaywallScreen({
    super.key,
    this.autoPresentRevenueCatPaywall = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum PlanType { annual, monthly }

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = true;
  bool _isProcessingPurchase = false;
  PlanType _selectedPlan = PlanType.annual;

  Package? _annualPackage;
  Package? _monthlyPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        for (final pkg in current.availablePackages) {
          final id = pkg.identifier.toLowerCase();
          final prodId = pkg.storeProduct.identifier.toLowerCase();

          if (id.contains('annual') ||
              id.contains('yearly') ||
              prodId.contains('sleekscan_pro_annual') ||
              prodId.contains('yearly') ||
              pkg.packageType == PackageType.annual) {
            _annualPackage = pkg;
          } else if (id.contains('monthly') ||
              prodId.contains('sleekscan_pro_monthly') ||
              prodId.contains('monthly') ||
              pkg.packageType == PackageType.monthly) {
            _monthlyPackage = pkg;
          }
        }
      }
    } catch (e) {
      debugPrint('[PaywallScreen] Error loading offerings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Package? get _activeSelectedPackage {
    return _selectedPlan == PlanType.annual ? _annualPackage : _monthlyPackage;
  }

  Future<void> _startProAccess() async {
    final package = _activeSelectedPackage;
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Package is currently unavailable from Google Play. Please try again later.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessingPurchase = true);

    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final customerInfo = purchaseResult.customerInfo;
      final isPro = RevenueCatService.instance.isProActive(customerInfo);

      if (isPro) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to SleekScan Pro! All features unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase completed, but Pro entitlement is still syncing.'),
          ),
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase error: ${e.message ?? e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPurchase = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isProcessingPurchase = true);

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = RevenueCatService.instance.isProActive(customerInfo);

      if (!mounted) return;
      if (isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Purchases successfully restored! Pro plan is active.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active SleekScan Pro subscription found to restore.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore purchases: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPurchase = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate premium theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessingPurchase ? null : _restorePurchases,
            child: const Text(
              'Restore',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⚡ UNLOCK PRO ACCESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Headline
                    const Text(
                      'SleekScan Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professional scanning, cloud sync, and zero watermarks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feature Matrix
                    _buildFeatureItem(
                      icon: Icons.branding_watermark_outlined,
                      title: 'No Watermark on Exports',
                      subtitle: 'Clean, professional multi-page PDF documents',
                    ),
                    _buildFeatureItem(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Cloud Backup & Sync (Supabase)',
                      subtitle: 'Auto-sync scans safely to secure cloud storage',
                    ),
                    _buildFeatureItem(
                      icon: Icons.language_outlined,
                      title: 'Web Portal & OCR Search',
                      subtitle: 'Search & copy scanned OCR text from any browser',
                    ),
                    _buildFeatureItem(
                      icon: Icons.draw_outlined,
                      title: 'Digital E-Signatures & Stamps',
                      subtitle: 'Draw, save, and stamp signatures with no limits',
                    ),
                    const SizedBox(height: 24),

                    // Pricing Selector Cards
                    _buildPricingCard(
                      plan: PlanType.annual,
                      title: 'Annual Pro',
                      packageId: 'sleekscan_pro_annual',
                      priceString: _annualPackage?.storeProduct.priceString ??
                          '\$29.99 / year',
                      subtext: '\$2.49 / month · Billed annually',
                      tag: 'SAVE 50% · BEST VALUE',
                    ),
                    const SizedBox(height: 12),
                    _buildPricingCard(
                      plan: PlanType.monthly,
                      title: 'Monthly Pro',
                      packageId: 'sleekscan_pro_monthly',
                      priceString: _monthlyPackage?.storeProduct.priceString ??
                          '\$4.99 / month',
                      subtext: 'Billed monthly · Cancel anytime',
                      tag: null,
                    ),
                    const SizedBox(height: 24),

                    // CTA Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          _isProcessingPurchase ? null : _startProAccess,
                      child: _isProcessingPurchase
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start Pro Access',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Footer guarantee & links
                    Text(
                      'Secured with Google Play In-App Billing. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required PlanType plan,
    required String title,
    required String packageId,
    required String priceString,
    required String subtext,
    required String? tag,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade600,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              priceString,
              style: TextStyle(
                color: isSelected ? const Color(0xFF60A5FA) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
