import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UpgradePage extends StatefulWidget {
  final String token;

  UpgradePage({required this.token});

  @override
  _UpgradePageState createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  final String _monthlyId = 'premium_monthly_v2';
  final String _yearlyId = 'premium_yearly_v2';
  final Set<String?> _processedPurchaseIds = {}; // Track processed purchases

  @override
  void initState() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased &&
            !_processedPurchaseIds.contains(purchase.purchaseID)) {
          _processedPurchaseIds.add(purchase.purchaseID);
          _verifyAndUpgrade(purchase);
        }
      }
    });
    _initialize();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processedPurchaseIds.clear(); // Clear processed purchases on user switch
  }

  Future<void> _initialize() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    setState(() => _available = isAvailable);
    if (!isAvailable) return;

    const Set<String> _kIds = {'premium_monthly_v2', 'premium_yearly_v2'};
    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Не найдены продукты: \${response.notFoundIDs}');
    }
    setState(() => _products = response.productDetails);
  }

  Future<void> _verifyAndUpgrade(PurchaseDetails purchase) async {
    final receipt = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;

    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: токен не найден')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/upgrade'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \${widget.token}',
      },
      body: jsonEncode({
        'receipt': receipt,
        'productId': productId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подписка активирована')),
      );
    } else {
      final errorMessage = data['error'] ?? 'неизвестная ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: \$errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upgrade to Premium')),
      body: _available
          ? ListView(
        children: _products.map((product) {
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: Text(product.price),
            onTap: () {
              final PurchaseParam purchaseParam =
              PurchaseParam(productDetails: product);
              _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
            },
          );
        }).toList(),
      )
          : Center(child: Text('Покупки недоступны')),
    );
  }
}
