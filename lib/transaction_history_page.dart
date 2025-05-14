import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String token;
  final String userId;
  final String tokenId;
  final String tokenSymbol;

  const TransactionHistoryPage({
    super.key,
    required this.token,
    required this.userId,
    required this.tokenId,
    required this.tokenSymbol,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<dynamic> transactions = [];
  bool isPremium = false;

  Future<void> fetchTransactions() async {
    final response = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/transactions/token/${widget.tokenId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;

      final prefs = await SharedPreferences.getInstance();
      isPremium = prefs.getBool('isPremium') ?? false;


      final filtered = data.where((tx) {
        return tx['from'] == widget.userId || tx['to'] == widget.userId;
      }).toList();

      // Показываем только 5, если не Premium
      final limited = isPremium ? filtered : filtered.take(5).toList();

      setState(() => transactions = limited);
    } else {
      setState(() => transactions = []);
    }
  }


  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPremium ? 'Transaction History' : 'Last 5 Transactions (Free)',
        ),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions found.'))
          : ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isIncoming = tx['to'] == widget.userId;
          final sign = isIncoming ? '+' : '-';
          final amountText = '$sign${widget.tokenSymbol} ${tx['amount']}';
          // parse timestamp if present
          String when = '';
          if (tx['timestamp'] != null) {
            try {
              final dt = DateTime.parse(tx['timestamp']).toLocal();
              when = '${dt.toLocal()}';
            } catch (_) {}
          }
          return ListTile(
            title: Text('From ${tx['fromName']} to ${tx['toName']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tx['message'] != null && tx['message'].toString().isNotEmpty)
                  Text('Message: ${tx['message']}'),
                if (when.isNotEmpty) Text('At: $when'),
              ],
            ),
            trailing: Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.red,
              ),
            ),
          );
        }
      ),
    );
  }
}
