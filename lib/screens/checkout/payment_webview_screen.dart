import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../order_success_screen.dart';
import '../../utils/l.dart';
import '../../theme/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // ✅ غيري هذا لـ URL التطبيق الفعلي
  static const String _callbackBase =
      'https://poetic-creponne-e07173.netlify.app';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            if (url.startsWith(_callbackBase) && !_callbackHandled) {
              _callbackHandled = true;
              _handleCallback(url);
            }
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            if (url.startsWith(_callbackBase) && !_callbackHandled) {
              _callbackHandled = true;
              _handleCallback(url);
            }
          },
          onNavigationRequest: (req) {
            if (req.url.startsWith(_callbackBase)) {
              if (!_callbackHandled) {
                _callbackHandled = true;
                _handleCallback(req.url);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _callbackHandled = false;
  Future<void> _handleCallback(String url) async {
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    final paymentId = uri.queryParameters['id'];

    final supabase = Supabase.instance.client;

    if (status == 'paid') {
      // ✅ حدّث الطلب
      try {
        await supabase
            .from('orders')
            .update({'status': 'confirmed', 'payment_id': paymentId})
            .eq('id', widget.orderId);
        debugPrint('ORDER UPDATED TO CONFIRMED ✅');
      } catch (e) {
        debugPrint('UPDATE FAILED ❌: $e');
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        (_) => false,
      );
    } else {
      // ❌ فشل الدفع
      await supabase
          .from('orders')
          .update({'status': 'payment_failed', 'payment_id': paymentId})
          .eq('id', widget.orderId);

      if (!mounted) return;
      Navigator.pop(context, 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(L.t('secure_payment')),
        backgroundColor: AppColors.card(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, 'cancelled'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            ),
        ],
      ),
    );
  }
}
