import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? message;
  bool loading = false;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      message = null;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        message = 'Please enter your email.';
        loading = false;
      });
      return;
    }

    final url = Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/forgot-password');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    setState(() {
      loading = false;
      if (response.statusCode == 200) {
        message = 'Password reset link sent. Check your email.';
      } else {
        final data = jsonDecode(response.body);
        message = data['error'] ?? 'Something went wrong.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading ? const CircularProgressIndicator() : const Text('Reset Password'),
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: message!.startsWith('Password') ? Colors.green : Colors.red),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
