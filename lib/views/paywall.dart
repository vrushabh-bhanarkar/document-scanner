import 'package:flutter/material.dart';

import '../core/themes.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade to Pro', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Purchases are currently disabled in this build.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            Text('You can continue using the app without a subscription.',
                style: AppTextStyles.bodyMedium),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
