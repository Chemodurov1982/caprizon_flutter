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

    _subscription = InAppPurchase.instance.purchaseStream.listen(
          (purchases) {
        for (final purchase in purchases) {
          if (purchase.status == PurchaseStatus.purchased) {
            print("✅ Покупка успешна: ${purchase.productID}");

            // Пример: отправка данных на сервер
            // await _verifyPurchase(purchase.verificationData.serverVerificationData, purchase.productID);

          } else if (purchase.status == PurchaseStatus.error) {
            print("❌ Ошибка при покупке: ${purchase.error}");
          }
        }
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        print("❗ Ошибка потока покупок: $error");
      },
    );
  }


  void _initialize() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      print('❌ In-app purchases not available.');
      setState(() => _loading = false);
      return;
    }

    final response = await _iap.queryProductDetails({'premium_monthly_v2', 'premium_yearly_v2'});
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
              onTap: () async {
                final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
                final bool available = await InAppPurchase.instance.isAvailable();

                if (!available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("In-app purchases not available")),
                  );
                  return;
                }

                final success = await InAppPurchase.instance.buyNonConsumable(
                  purchaseParam: purchaseParam,
                );

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Purchase failed")),
                  );
                }
              };

            },
          );
        },
      ),
    );
  }
}
