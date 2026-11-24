import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';
import '../theme/app_theme.dart';

/// Production SleekScan Pro Paywall Screen
/// - Visual Comparison: Free (Offline Core) vs Pro (Cloud Sync, No Watermarks, Password Lock, Unlimited Batch Scans)
/// - Plan selection toggling between Monthly and Annual with discount tags
/// - Integrated purchasing via `purchases_flutter` with error handling, loading states, and "Restore Purchases"
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
            'Package is currently unavailable from Store. Please try again later.',
          ),
          backgroundColor: AppTheme.warningAmber,
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
            backgroundColor: AppTheme.emerald,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase completed, syncing Pro entitlement...'),
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
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorRed,
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
            backgroundColor: AppTheme.emerald,
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
          backgroundColor: AppTheme.errorRed,
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
      backgroundColor: AppTheme.darkSlate,
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
              child: CircularProgressIndicator(color: AppTheme.indigoLight),
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
                            colors: [AppTheme.indigo, AppTheme.emerald],
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
                    const Text(
                      'Professional scanning, cloud sync, and zero watermarks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Visual Comparison Table: Free vs Pro
                    _buildVisualComparisonTable(),
                    const SizedBox(height: 24),

                    // Pricing Selector Cards
                    _buildPricingCard(
                      plan: PlanType.annual,
                      title: 'Annual Pro',
                      priceString: _annualPackage?.storeProduct.priceString ??
                          '\$29.99 / year',
                      subtext: '\$2.49 / month · Billed annually',
                      tag: 'SAVE 50% · BEST VALUE',
                    ),
                    const SizedBox(height: 12),
                    _buildPricingCard(
                      plan: PlanType.monthly,
                      title: 'Monthly Pro',
                      priceString: _monthlyPackage?.storeProduct.priceString ??
                          '\$4.99 / month',
                      subtext: 'Billed monthly · Cancel anytime',
                      tag: null,
                    ),
                    const SizedBox(height: 24),

                    // CTA Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.indigo,
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

                    // Footer guarantee & terms
                    const Text(
                      'Secured with Google Play & App Store Billing. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
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

  /// Visual comparison: Free (Offline Core) vs Pro (Cloud Sync, No Watermarks, Password Lock, Unlimited Batch Scans)
  Widget _buildVisualComparisonTable() {
    return Container(
      decoration: AppTheme.cardDecoration(
        surfaceColor: AppTheme.cardSurface,
        borderColor: AppTheme.borderDark,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Free Plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Pro Plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.emeraldLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderDark),

          // Comparison Rows
          _buildComparisonRow(
            feature: 'Cloud Sync (Supabase)',
            freeVal: '❌ None',
            proVal: '✅ Auto Sync',
            isProHighlight: true,
          ),
          _buildComparisonRow(
            feature: 'PDF Watermark',
            freeVal: 'Watermarked',
            proVal: '✅ 100% Clean',
            isProHighlight: true,
          ),
          _buildComparisonRow(
            feature: 'AES-128 Password Lock',
            freeVal: '❌ Locked',
            proVal: '✅ Unlimited',
            isProHighlight: true,
          ),
          _buildComparisonRow(
            feature: 'Batch Scanning',
            freeVal: '5 Scans/day',
            proVal: '✅ Unlimited',
            isProHighlight: true,
          ),
          _buildComparisonRow(
            feature: 'Offline Core Scanner',
            freeVal: '✅ Included',
            proVal: '✅ Included',
            isProHighlight: false,
          ),
          _buildComparisonRow(
            feature: 'On-Device ML Kit OCR',
            freeVal: '✅ Included',
            proVal: '✅ Included',
            isProHighlight: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String feature,
    required String freeVal,
    required String proVal,
    required bool isProHighlight,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.borderDark, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              feature,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeVal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              proVal,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isProHighlight ? AppTheme.emeraldLight : Colors.white,
                fontSize: 12,
                fontWeight: isProHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required PlanType plan,
    required String title,
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
          color: isSelected ? AppTheme.cardSurface : AppTheme.darkSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.indigo : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.indigo.withOpacity(0.25),
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
              color: isSelected ? AppTheme.indigoLight : AppTheme.textMuted,
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
                            color: AppTheme.emeraldDark,
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
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              priceString,
              style: TextStyle(
                color: isSelected ? AppTheme.indigoLight : Colors.white,
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
