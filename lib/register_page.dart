import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  // Базовый URL вашего API
  final String baseUrl = 'https://caprizon-a721205e360f.herokuapp.com';

  Future<void> register() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text;

    // Локальная проверка формата e-mail
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => error = 'Incorrect e-mail');
      return;
    }
    if (name.isEmpty) {
      setState(() => error = 'Input name');
      return;
    }
    if (password.length < 6) {
      setState(() => error = 'Password must contain not less than 6 symbols');
      return;
    }

    // 1) Проверяем, не зарегистрирован ли уже такой e-mail
    final checkResponse = await http.post(
      Uri.parse('$baseUrl/api/users/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (checkResponse.statusCode == 200) {
      // Сервер ответил 200 — такой e-mail уже есть в базе
      setState(() => error = 'This e-mail is already registered');
      return;
    } else if (checkResponse.statusCode != 404) {
      // Любая другая ошибка (например, 500)
      setState(() => error = 'E-mail check failed: try again later');
      return;
    }
    // Если статус 404 — значит такого e-mail нет и можно регистрировать

    // 2) Отправляем запрос на регистрацию
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final userId = data['userId'] as String;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => HomePage(token: token, userId: userId),
        ),
      );
    } else {
      final message = (jsonDecode(response.body)['error'] as String?) ??
          'Registration failed';
      setState(() => error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: register,
              child: const Text('Register'),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
