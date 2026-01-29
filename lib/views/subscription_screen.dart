import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../core/themes.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, sub, _) {
          final isSubscribed = sub.isSubscribed;
          final isProcessing = sub.isProcessing;

          return SingleChildScrollView(
            child: Column(
              children: [
                _StatusCard(isSubscribed: isSubscribed, lastPayment: sub.lastPaymentDate),
                _AccountCard(
                  controller: _emailController,
                  provider: sub,
                  isProcessing: isProcessing,
                ),
                const _BenefitsList(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isSubscribed)
                        _PaymentButton(provider: sub, isProcessing: isProcessing)
                      else
                        const _ActiveBadge(),
                      SizedBox(height: 12.h),
                      OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                await sub.load();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Restored subscription status.')),
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue, width: 2),
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: Text(
                          'Restore Purchase',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      Text(
                        'Questions? Contact Support',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your subscription supports continuous app development and new features',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.gray600, height: 1.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isSubscribed, required this.lastPayment});

  final bool isSubscribed;
  final DateTime? lastPayment;

  @override
  Widget build(BuildContext context) {
    final statusText = isSubscribed ? 'Subscription Active' : 'Subscription Inactive';
    final statusColor = isSubscribed ? AppColors.success : AppColors.gray600;
    final lastPaymentText = lastPayment != null
        ? 'Last payment on ${lastPayment!.toLocal().toString().split(' ').first}'
        : 'No payments yet';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54.r,
            width: 54.r,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              isSubscribed ? Icons.verified_rounded : Icons.lock_clock_rounded,
              color: statusColor,
              size: 28.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.gray900),
                ),
                SizedBox(height: 6.h),
                Text(
                  lastPaymentText,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.controller,
    required this.provider,
    required this.isProcessing,
  });

  final TextEditingController controller;
  final SubscriptionProvider provider;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final loggedInEmail = provider.userEmail;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          SizedBox(height: 10.h),
          if (loggedInEmail != null) ...[
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primaryBlue, size: 22.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    loggedInEmail,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.gray900),
                  ),
                ),
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          await provider.logout();
                          controller.clear();
                        },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: controller,
              enabled: !isProcessing,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final email = controller.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an email to log in.')),
                          );
                          return;
                        }
                        await provider.login(email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logged in as $email')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: isProcessing
                    ? SizedBox(
                        height: 18.r,
                        width: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Log in'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  @override
  Widget build(BuildContext context) {
    const benefits = <String>[
      'Unlimited document scans',
      'Ad-free experience across the app',
      'Priority access to new features',
      'High-quality PDF exports and sharing',
    ];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why go Premium?',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          SizedBox(height: 12.h),
          ...benefits.map(
            (benefit) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.gray800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  const _PaymentButton({required this.provider, required this.isProcessing});

  final SubscriptionProvider provider;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isProcessing
          ? null
          : () async {
              await provider.payAndSubscribe();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription activated. Thank you!')),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        elevation: 2,
      ),
      child: isProcessing
          ? SizedBox(
              height: 20.r,
              width: 20.r,
              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Column(
              children: [
                Text(
                  'Subscribe for \$4.99 / month',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Cancel anytime. Secure payment.',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.success, size: 22.r),
          SizedBox(width: 8.w),
          Text(
            'You are a premium member',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
