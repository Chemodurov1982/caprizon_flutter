import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'entry_page.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final TextEditingController _promoController = TextEditingController();
  String? _promoMessage;
  bool _promoLoading = false;

  @override
  void initState() {
    print('🔼 UpgradePage стартует с токеном: ${widget.token}');
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen((purchases) async {
      for (var purchase in purchases) {
        if (purchase.purchaseID == null) {
          continue;
        }

        if (purchase.status == PurchaseStatus.pending) {
          _pendingProductIds.remove(purchase.productID);
        }

        if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          await _verifyAndUpgrade(purchase);

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }

          _pendingProductIds.remove(purchase.productID);
        } else if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
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
    _pendingProductIds.clear();
    _inAppPurchase.restorePurchases();
  }

  Future<void> _initialize() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    setState(() => _available = isAvailable);
    if (!isAvailable) return;

    const Set<String> _kIds = {'premium_monthly_v2', 'premium_yearly_v2'};
    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(_kIds);
    setState(() => _products = response.productDetails);
  }

  Future<void> _verifyAndUpgrade(PurchaseDetails purchase) async {
    final receipt = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;

    if (widget.token.isEmpty) {
      return;
    }
    print('📡 Отправка запроса с headers: ${{
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    }}');
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

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);
    }
  }

  bool _isPurchasePending(String productId) {
    return _pendingProductIds.contains(productId);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to permanently delete your account? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await http.delete(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/delete'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => EntryPage()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _applyPromoCode() async {
    setState(() {
      _promoLoading = true;
      _promoMessage = null;
    });

    final promoCode = _promoController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/promo-codes/redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'code': promoCode}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Обновляем профиль после промокода
        final profileRes = await http.get(
          Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/me'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (profileRes.statusCode == 200) {
          final profile = jsonDecode(profileRes.body);
          final isPremium = profile['isPremium'] ?? false;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', isPremium);
        }

        setState(() {
          _promoMessage = '✅ Premium activated via promo code!';
        });
        Navigator.pop(context, true);
      } else {
        setState(() {
          _promoMessage = '❌ ${data['error'] ?? 'Failed to apply promo code'}';
        });
      }
    } catch (e) {
      setState(() {
        _promoMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _promoLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upgrade to Premium')),
      body: _available
          ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('With a Premium subscription, you can:', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('- Create unlimited community tokens', style: TextStyle(fontSize: 14)),
                Text('- Mint and transfer tokens without limits', style: TextStyle(fontSize: 14)),
                Text('- Remove transaction limits', style: TextStyle(fontSize: 14)),
                Text('- Get early access to new features', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _products.map((product) {
                return ListTile(
                  title: Text(product.title),
                  subtitle: Text(product.description),
                  trailing: Text(product.price),
                  onTap: () async {
                    if (_isPurchasePending(product.id)) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Or enter a promo code:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    labelText: 'Promo Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _promoLoading ? null : _applyPromoCode,
                  child: _promoLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Apply Promo Code'),
                ),
                if (_promoMessage != null) ...[
                  SizedBox(height: 12),
                  Text(
                    _promoMessage!,
                    style: TextStyle(color: _promoMessage!.startsWith('✅') ? Colors.green : Colors.red),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse('https://chemodurov1982.github.io/caprizon-privacy/'));
                  },
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'));
                  },
                  child: const Text('Terms of Use'),
                ),
              ],
            ),
          ),

          if (_restoring)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _restoring = true);
              try {
                await _inAppPurchase.restorePurchases();
              } on PlatformException catch (e) {}
              await Future.delayed(Duration(seconds: 2));
              setState(() => _restoring = false);
            },
            child: Text('Restore Purchases'),
          ),
          ElevatedButton(
            onPressed: _deleteAccount,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Account'),
          )
        ],
      )
          : Center(child: Text('Purchases unavailable')),
    );
  }
}
