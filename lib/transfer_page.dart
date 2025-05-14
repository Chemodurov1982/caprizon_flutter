import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class TransferPage extends StatefulWidget {
  final String token;
  final String tokenId;
  final String fromUserId;
  final bool isAdmin;

  final dynamic tokenSymbol;

  const TransferPage({
    Key? key,
    required this.token,
    required this.tokenId,
    required this.fromUserId,
    required this.isAdmin,
    required this.tokenSymbol,
  }) : super(key: key);

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String? selectedUserId;
  final amountController = TextEditingController();
  final messageController = TextEditingController();
  bool isLoading = true;
  List<Map<String, String>> users = [];

  // Новый стейт для отображения баланса пользователя
  double userBalance = 0;

  @override
  void initState() {
    super.initState();
    loadUsers();
    fetchBalance();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    final response = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/token/${widget.tokenId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      final filtered = data
          .where((u) => u['_id'].toString() != widget.fromUserId)
          .map<Map<String, String>>((u) => {
        'userId': u['_id'].toString(),
        'email': u['email'].toString(),
        'name': u['name'].toString(),
      })
          .toList();
      setState(() {
        users = filtered;
        selectedUserId = users.isNotEmpty ? users[0]['userId'] : null;
      });
    } else {
      setState(() => users = []);
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchBalance() async {
    final response = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/balances/${widget.fromUserId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final balances = Map<String, dynamic>.from(data['balances']);
      setState(() {
        userBalance = (balances[widget.tokenId] ?? 0).toDouble();
      });
    }
  }

  Future<void> submitTransfer(String fromUser, String toUser) async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('isPremium') ?? false;

    if (!isPremium) {
      final profileResp = await http.get(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (profileResp.statusCode == 200) {
        final profile = jsonDecode(profileResp.body);
        final count = profile['transactionCount'] ?? 0;
        if (count >= 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Free users can only make 20 transactions')),
          );
          return;
        }
      }
    }

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/transfer'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fromUserId': fromUser,
        'toUserId': toUser,
        'amount': amount,
        'message': messageController.text,
        'tokenId': widget.tokenId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction successful')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction failed')),
      );
    }
  }

  Future<void> submitRequest() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0 || selectedUserId == null) return;

    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/requests'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requesterId': widget.fromUserId,
        'ownerId': selectedUserId!,
        'tokenId': widget.tokenId,
        'amount': amount,
        'message': messageController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to token owner')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request failed to send')),
      );
    }
  }

  void onSendPressed() {
    if (selectedUserId == null) return;
    submitTransfer(widget.fromUserId, selectedUserId!);
  }

  void onRequestPressed() {
    if (selectedUserId == null) return;
    submitRequest(); // отправка запроса, независимо от isAdmin
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Operations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Отображаем баланс текущего пользователя
            Text('Your balance: ${widget.tokenSymbol} ${userBalance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const Text(
                'No other participants available',
                style: TextStyle(fontSize: 16),
              )
            else
              DropdownButton<String>(
                isExpanded: true,
                value: selectedUserId,
                hint: const Text('Select user'),
                onChanged: (v) => setState(() => selectedUserId = v),
                items: users.map((user) {
                  final id = user['userId']!;
                  final email = user['email']!;
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(user['name'] ?? user['email']!),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSendPressed,
                    child: const Text('Send Tokens'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRequestPressed,
                    child: const Text('Request Tokens'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
