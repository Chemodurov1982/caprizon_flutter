import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpgradePage extends StatefulWidget {
  final String token;

  const UpgradePage({super.key, required this.token});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  String status = '';

  Future<void> upgrade() async {
    final resp = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/upgrade'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    setState(() {
      if (resp.statusCode == 200) {
        status = 'You are now a premium user!';
        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pop(context, true);
        });
      } else {
        status = 'Upgrade failed. Try again.';
      }
    });
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
            ElevatedButton(
              onPressed: upgrade,
              child: const Text('Upgrade Now'),
            ),
            const SizedBox(height: 16),
            if (status.isNotEmpty) Text(status),
          ],
        ),
      ),
    );
  }
}
