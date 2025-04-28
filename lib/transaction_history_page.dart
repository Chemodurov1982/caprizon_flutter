import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionHistoryPage extends StatefulWidget {
  final String token;
  final String userId;
  final String tokenId;

  const TransactionHistoryPage({
    super.key,
    required this.token,
    required this.userId,
    required this.tokenId,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<dynamic> transactions = [];

  Future<void> fetchTransactions() async {
    final response = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/transactions/token/${widget.tokenId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      // filter to only those where current user is involved
      final filtered = data.where((tx) {
        return tx['from'] == widget.userId || tx['to'] == widget.userId;
      }).toList();
      setState(() => transactions = filtered);
    } else {
      // handle error or empty
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
      appBar: AppBar(title: const Text('Transaction History')),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions found.'))
          : ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
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
            trailing: Text('${tx['amount']}'),
          );
        },
      ),
    );
  }
}
