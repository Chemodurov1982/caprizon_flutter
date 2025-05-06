import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();
  final nameController = TextEditingController();
  String error = '';

  Future<void> register() async {
    final email = emailController.text.trim().replaceAll(' ', '');
    final password = passwordController.text;
    final repeatPassword = repeatPasswordController.text;
    final name = nameController.text.trim();

    if (password != repeatPassword) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() => error = 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: repeatPasswordController, decoration: const InputDecoration(labelText: 'Repeat Password'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: register, child: const Text('Register')),
            const SizedBox(height: 12),
            if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
