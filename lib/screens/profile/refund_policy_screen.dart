import 'package:flutter/material.dart';
import '../../utils/l.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  Widget _policyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, height: 1.4)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L.t('refund_policy')), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title
            Text(
              L.t('refund_policy'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // 🔹 Subtitle (soft & friendly)
            Text(
              L.t('refund_policy_intro'),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Policy Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _policyItem(L.t('refund_item_1')),
                  _policyItem(L.t('refund_item_2')),
                  _policyItem(L.t('refund_item_3')),
                  _policyItem(L.t('refund_item_4')),
                  _policyItem(L.t('refund_item_5')),
                  _policyItem(L.t('refund_item_6')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
