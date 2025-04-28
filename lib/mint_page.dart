import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokenMintPage extends StatefulWidget {
  final String token;
  final String tokenId;
  final String userId;

  const TokenMintPage({super.key, required this.token, required this.tokenId, required this.userId});

  @override
  State<TokenMintPage> createState() => _TokenMintPageState();
}

class _TokenMintPageState extends State<TokenMintPage> {
  final amountController = TextEditingController();
  String message = '';

  Future<void> mint() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        message = 'Invalid amount';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/mint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'tokenId': widget.tokenId,
        'userId': widget.userId,
        'amount': amount,
      }),
    );

    setState(() {
      if (response.statusCode == 200) {
        message = 'Minted successfully';
      } else {
        final responseData = jsonDecode(response.body);
        message = 'Mint failed: ${responseData['error'] ?? 'Unknown error'}';
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mint Tokens')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: mint, child: const Text('Mint')),
            const SizedBox(height: 8),
            if (message.isNotEmpty) Text(message),
          ],
        ),
      ),
    );
  }
}
