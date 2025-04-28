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
      setState(() => error = 'Введите корректный e-mail');
      return;
    }
    if (name.isEmpty) {
      setState(() => error = 'Введите имя');
      return;
    }
    if (password.length < 6) {
      setState(() => error = 'Пароль должен быть не менее 6 символов');
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
      setState(() => error = 'Этот e-mail уже зарегистрирован');
      return;
    } else if (checkResponse.statusCode != 404) {
      // Любая другая ошибка (например, 500)
      setState(() => error = 'Не удалось проверить e-mail: попробуйте позже');
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
          'Ошибка регистрации';
      setState(() => error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
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
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: register,
              child: const Text('Зарегистрироваться'),
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
