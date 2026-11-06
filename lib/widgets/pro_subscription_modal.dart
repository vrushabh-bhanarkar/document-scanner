import 'package:flutter/material.dart';

class ProSubscriptionModal extends StatelessWidget {
  final String featureName;
  final VoidCallback onSubscribed;

  const ProSubscriptionModal({
    super.key,
    required this.featureName,
    required this.onSubscribed,
  });

  static void show(BuildContext context, String featureName, VoidCallback onSubscribed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProSubscriptionModal(
        featureName: featureName,
        onSubscribed: onSubscribed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Unlock $featureName",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upgrade to SleekScan Pro to unlock AI document analysis, lossless Word/Excel export, and ultra compression.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildBenefitRow(Icons.check_circle_outline, "AI Chat & Summaries for documents up to 50MB"),
          _buildBenefitRow(Icons.check_circle_outline, "Export to Word (.docx) with exact table formatting"),
          _buildBenefitRow(Icons.check_circle_outline, "Remove all interstitial banner ads"),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onSubscribed();
            },
            child: const Text("Start 7-Day Free Trial", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }
}
