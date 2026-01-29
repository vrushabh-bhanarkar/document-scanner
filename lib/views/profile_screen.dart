import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/themes.dart';
import '../providers/subscription_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _processing = false;

  Future<void> _restorePurchases() async {
    setState(() => _processing = true);
    try {
      await Purchases.restorePurchases();
      await Provider.of<SubscriptionProvider>(context, listen: false).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore complete')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _processing = true);
    try {
      await FirebaseAuth.instance.signOut();
      await Provider.of<SubscriptionProvider>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    final email = sub.userEmail ?? FirebaseAuth.instance.currentUser?.email ?? 'Guest';
    final status = sub.isSubscribed ? 'Subscribed' : 'Free';
    final lastPayment = sub.lastPaymentDate != null ? DateFormat.yMMMd().format(sub.lastPaymentDate!) : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(email, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(status)),
                const SizedBox(width: 12),
                Text('Last payment: $lastPayment', style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Manage subscription'),
                subtitle: const Text('Buy or manage your subscription'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/paywall');
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Restore purchases'),
                subtitle: const Text('Restore purchases from the store'),
                trailing: _processing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.restore),
                onTap: _processing ? null : _restorePurchases,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Sign out'),
                subtitle: const Text('Sign out of your account'),
                trailing: const Icon(Icons.logout),
                onTap: _processing ? null : _signOut,
              ),
            ),
            const SizedBox(height: 16),
            if (!sub.isSubscribed)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('You can buy a subscription to unlock unlimited scans and cloud sync.', style: AppTextStyles.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
