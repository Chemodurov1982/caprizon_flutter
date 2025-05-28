import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTokenPage extends StatefulWidget {
  final String token;
  const CreateTokenPage({super.key, required this.token});

  @override
  State<CreateTokenPage> createState() => _CreateTokenPageState();
}

class _CreateTokenPageState extends State<CreateTokenPage> {
  final nameController = TextEditingController();
  final symbolController = TextEditingController();
  String message = '';
  bool? isPremium; // Nullable — чтобы показывать loader

  @override
  void initState() {
    super.initState();
    fetchPremiumStatus();
  }

  Future<void> fetchPremiumStatus() async {
    print('🔍 Fetching premium status...');
    final response = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/me'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', data['isPremium'] ?? false);

      setState(() {
        isPremium = data['isPremium'] ?? false;
        print('✅ Premium status fetched: $isPremium');
      });
    } else {
      setState(() {
        isPremium = false; // Фоллбэк
        message = 'Failed to verify premium status.';
        print('❌ Failed to fetch premium status');
      });
    }
  }

  Future<void> createToken() async {
    print('🟡 createToken() called');
    final name = nameController.text.trim();
    final symbol = symbolController.text.trim();
    print('📝 name: $name, symbol: $symbol');

    if (name.isEmpty || symbol.isEmpty) {
      print('⛔ Token name or symbol is empty — returning early');
      return;
    }

    print('🚀 Sending request to create token...');
    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({ 'name': name, 'symbol': symbol }),
    );

    print('📬 Response received. Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() => message = '✅ Token created successfully.');
    } else {
      final bodyText = response.body;
      setState(() => message = '❌ Failed (${response.statusCode}): $bodyText');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isPremium == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Token')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Token Name')),
            TextField(controller: symbolController, decoration: const InputDecoration(labelText: 'Symbol')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: createToken, child: const Text('Create')),
            const SizedBox(height: 12),
            if (message.isNotEmpty) Text(message),
          ],
        ),
      ),
    );
  }
}
