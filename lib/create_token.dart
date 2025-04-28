import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> createToken() async {
    final name = nameController.text.trim();
    final symbol = symbolController.text.trim();
    if (name.isEmpty || symbol.isEmpty) return;

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({ 'name': name, 'symbol': symbol }),
    );

    if (response.statusCode == 200) {
      setState(() => message = 'Token created successfully and you are now an admin and member.');
    } else {
      setState(() => message = 'Failed to create token');
    }
  }

  @override
  Widget build(BuildContext context) {
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
