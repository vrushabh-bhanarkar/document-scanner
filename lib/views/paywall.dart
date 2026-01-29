import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';

import '../core/themes.dart';
import '../providers/subscription_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _loading = true);
    try {
      final offerings = await Purchases.getOfferings();
      setState(() => _offerings = offerings);
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _purchase(Package pkg) async {
    setState(() => _loading = true);
    try {
      await Purchases.purchasePackage(pkg);
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.isNotEmpty) {
        await Provider.of<SubscriptionProvider>(context, listen: false).setSubscribed(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful')));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      await Purchases.restorePurchases();
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.isNotEmpty) {
        await Provider.of<SubscriptionProvider>(context, listen: false).setSubscribed(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored purchases')));
        if (mounted) Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No purchases to restore')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade to Pro', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('No ads, unlimited cloud storage, high-quality OCR', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _offerings != null && _offerings!.current != null && _offerings!.current!.availablePackages.isNotEmpty)
              ..._offerings!.current!.availablePackages.map((pkg) {
                final price = pkg.storeProduct.priceString ?? pkg.identifier;
                return Card(
                  child: ListTile(
                    title: Text(pkg.storeProduct.title ?? pkg.identifier),
                    subtitle: Text(pkg.storeProduct.description ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () => _purchase(pkg),
                      child: Text('Buy $price'),
                    ),
                  ),
                );
              }).toList()
            else if (!_loading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No purchase options available right now.', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _loadOfferings, child: const Text('Retry')),
                ],
              ),
            const Spacer(),
            ElevatedButton(onPressed: subscriptionProvider.isSubscribed ? null : _restore, child: const Text('Restore Purchases')),
          ],
        ),
      ),
    );
  }
}
