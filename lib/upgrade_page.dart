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
  bool _restoring = false;
  List<ProductDetails> _products = [];
  final String _monthlyId = 'premium_monthly_v2';
  final String _yearlyId = 'premium_yearly_v2';
  final Set<String> _pendingProductIds = {}; // Track pending product IDs

  @override
  void initState() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen((purchases) {
      for (var purchase in purchases) {
        print('🛒 Обновление покупки: ${purchase.status}, ID: ${purchase.purchaseID}');

        if (purchase.purchaseID == null) {
          print('⚠️ Покупка без ID, пропускаем: ${purchase.productID}');
          continue;
        }

        if (purchase.pendingCompletePurchase) {
          print('⏳ Завершаем незавершённую покупку: ${purchase.productID}');
          _inAppPurchase.completePurchase(purchase);
          continue;
        }

        if (purchase.status == PurchaseStatus.pending) {
          _pendingProductIds.remove(purchase.productID);
        }

        if (purchase.status == PurchaseStatus.purchased) {
          print('✅ Новая покупка, обрабатываем...');
          _verifyAndUpgrade(purchase);
          _pendingProductIds.remove(purchase.productID);
        }

        if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
          _pendingProductIds.remove(purchase.productID);
        }
      }
    });
    _initialize();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 Смена пользователя, очищаем _pendingProductIds');
    _pendingProductIds.clear();
    _inAppPurchase.restorePurchases();
  }

  Future<void> _initialize() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    setState(() => _available = isAvailable);
    print('🛍️ Покупки доступны: $isAvailable');
    if (!isAvailable) return;

    const Set<String> _kIds = {'premium_monthly_v2', 'premium_yearly_v2'};
    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('❌ Не найдены продукты: ${response.notFoundIDs}');
    }
    setState(() => _products = response.productDetails);
    print('📦 Найденные продукты: ${_products.map((p) => p.id).toList()}');
  }

  Future<void> _verifyAndUpgrade(PurchaseDetails purchase) async {
    print('📨 Отправка подписки на сервер...');
    final receipt = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;

    if (widget.token.isEmpty) {
      print('🚫 Токен пустой');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: токен не найден')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/upgrade'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'receipt': receipt,
        'productId': productId,
      }),
    );

    print('🔄 Ответ сервера: ${response.statusCode}, ${response.body}');

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
        SnackBar(content: Text('Ошибка: $errorMessage')),
      );
    }
  }

  bool _isPurchasePending(String productId) {
    return _pendingProductIds.contains(productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upgrade to Premium')),
      body: _available
          ? Column(
        children: [
          Expanded(
            child: ListView(
              children: _products.map((product) {
                return ListTile(
                  title: Text(product.title),
                  subtitle: Text(product.description),
                  trailing: Text(product.price),
                  onTap: () async {
                    print('👆 Нажата подписка: ${product.id}');

                    if (_isPurchasePending(product.id)) {
                      print('⚠️ Подписка уже в процессе оформления: ${product.id}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Подписка уже оформляется')),
                      );
                      return;
                    }

                    _pendingProductIds.add(product.id);
                    final PurchaseParam purchaseParam =
                    PurchaseParam(productDetails: product);
                    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
                  },
                );
              }).toList(),
            ),
          ),
          if (_restoring) Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _restoring = true);
              print('🔄 Восстановление покупок...');
              await _inAppPurchase.restorePurchases();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Восстановление покупок запущено')),
              );
              await Future.delayed(Duration(seconds: 2));
              setState(() => _restoring = false);
            },
            child: Text('Восстановить покупки'),
          ),
        ],
      )
          : Center(child: Text('Покупки недоступны')),
    );
  }
}
