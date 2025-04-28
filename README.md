import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return const MaterialApp(
title: 'Token Wallet',
home: LoginPage(),
);
}
}

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final emailController = TextEditingController();
final passwordController = TextEditingController();
String error = '';

Future<void> login() async {
final response = await http.post(
Uri.parse('http://localhost:3000/api/login'),
headers: {'Content-Type': 'application/json'},
body: jsonEncode({
'email': emailController.text,
'password': passwordController.text,
}),
);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userId = data['userId'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(token: token, userId: userId),
        ),
      );
    } else {
      setState(() => error = 'Login failed');
    }
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Login')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
const SizedBox(height: 16),
ElevatedButton(onPressed: login, child: const Text('Login')),
if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
],
),
),
);
}
}

class HomePage extends StatefulWidget {
final String token;
final String userId;

const HomePage({super.key, required this.token, required this.userId});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
double balance = 0;
final recipientController = TextEditingController();
final amountController = TextEditingController();

Future<void> fetchBalance() async {
final response = await http.get(
Uri.parse('http://localhost:3000/api/balance/${widget.userId}'),
headers: {'Authorization': 'Bearer ${widget.token}'},
);
if (response.statusCode == 200) {
setState(() => balance = jsonDecode(response.body)['balance'].toDouble());
}
}

Future<void> sendTokens() async {
final recipientId = recipientController.text;
final amount = double.tryParse(amountController.text) ?? 0;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/transfer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'fromUserId': widget.userId,
        'toUserId': recipientId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      await fetchBalance();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer successful')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer failed')));
    }
}

@override
void initState() {
super.initState();
fetchBalance();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Token Wallet')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Balance: \$${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24)),
const SizedBox(height: 16),
TextField(controller: recipientController, decoration: const InputDecoration(labelText: 'Recipient ID')),
TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
const SizedBox(height: 16),
ElevatedButton(onPressed: sendTokens, child: const Text('Send Tokens')),
],
),
),
);
}
}
