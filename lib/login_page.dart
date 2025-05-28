import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userId', data['userId']);
      print('🔐 Сервер вернул токен: ${data['token']}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userId: data['userId'],
            token: data['token'],
          ),
        ),
      );
    } else {
      setState(() {
        error = jsonDecode(response.body)['error'] ?? 'Login failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.login)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.password),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context)!.login),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                );
              },
              child: Text(AppLocalizations.of(context)!.forgot_password),
            ),
          ],
        ),
      ),
    );
  }
}
