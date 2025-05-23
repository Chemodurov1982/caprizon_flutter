import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class UpgradePage extends StatefulWidget {
  final String token;
  const UpgradePage({Key? key, required this.token}) : super(key: key);

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      print('❌ In-app purchases not available.');
      setState(() => _loading = false);
      return;
    }

    final response = await _iap.queryProductDetails({'premium_monthly', 'premium_yearly'});
    print('📦 Loaded products: ${response.productDetails}');
    print('❗ StoreKit error: ${response.error}');

    setState(() {
      _products = response.productDetails.toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        leading: BackButton(),
      ),
      body: _products.isEmpty
          ? const Center(
        child: Text(
          "No subscriptions found. Please try again or check your StoreKit configuration.",
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: Text(product.price),
            onTap: () {
              // Future: purchase logic
            },
          );
        },
      ),
    );
  }
}
