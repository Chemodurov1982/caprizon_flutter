import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradePage extends StatefulWidget {
  final String token;

  const UpgradePage({super.key, required this.token});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  String status = '';
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  late Stream<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _subscription = _iap.purchaseStream;
    _subscription.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          _activatePremium();
        }
      }
    });
  }

  Future<void> _loadProducts() async {
    const ids = {'premium_monthly', 'premium_yearly'};
    final response = await _iap.queryProductDetails(ids);
    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> _buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _activatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('• Unlimited transactions'),
            const Text('• Create multiple tokens'),
            const Text('• View full transaction history'),
            const SizedBox(height: 24),
            if (_products.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: _products.map((product) => ListTile(
                  title: Text(product.title),
                  subtitle: Text(product.description),
                  trailing: Text(product.price),
                  onTap: () => _buy(product),
                )).toList(),
              ),
            const SizedBox(height: 16),
            if (status.isNotEmpty) Text(status),
          ],
        ),
      ),
    );
  }
}
