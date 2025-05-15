import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

class UpgradePage extends StatefulWidget {
  final String token;

  const UpgradePage({required this.token});

  @override
  _UpgradePageState createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds = {'premium_monthly_v2', 'premium_yearly_v2'};
  bool _available = false;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _upgraded = false;
  String? _purchasedProductId;

  @override
  void initState() {
    super.initState();
    _initialize();
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
      _subscription?.cancel();
    });
  }

  Future<void> _initialize() async {
    final available = await _iap.isAvailable();
    setState(() => _available = available);
    if (!available) return;

    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null || response.productDetails.isEmpty) {
      _showSnackBar('Failed to load subscription options');
      return;
    }

    setState(() {
      _products = response.productDetails;
    });
  }

  void _buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
    setState(() => _purchasePending = true);
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        final res = await http.post(
          Uri.parse('https://caprizon.fly.dev/api/users/upgrade'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (res.statusCode == 200) {
          setState(() {
            _upgraded = true;
            _purchasePending = false;
            _purchasedProductId = purchase.productID;
          });
        } else {
          setState(() => _purchasePending = false);
          _showSnackBar('Failed to upgrade profile');
        }
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => _purchasePending = false);
        _showSnackBar('Purchase failed');
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_upgraded) {
      return Scaffold(
        appBar: AppBar(title: Text('Premium')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have successfully upgraded to Premium!'),
              if (_purchasedProductId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Plan: ${_purchasedProductId == 'premium_yearly_v2' ? 'Yearly' : 'Monthly'}'),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Upgrade to Premium')),
      body: Center(
        child: _available && _products.isNotEmpty
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final product in _products)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _purchasePending ? null : () => _buy(product),
                  child: Text('${product.title} — ${product.price}'),
                ),
              ),
            if (_purchasePending) CircularProgressIndicator(),
          ],
        )
            : Text('Subscriptions are not available'),
      ),
    );
  }
}
