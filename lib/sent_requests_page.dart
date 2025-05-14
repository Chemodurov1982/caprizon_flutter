import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SentRequestsPage extends StatefulWidget {
  final String token;
  final String userId;

  const SentRequestsPage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<SentRequestsPage> createState() => _SentRequestsPageState();
}

class _SentRequestsPageState extends State<SentRequestsPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadSent();
  }

  Future<void> _loadSent() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final uri = Uri.parse(
      'https://caprizon-a721205e360f.herokuapp.com/api/requests/sent/${widget.userId}',
    );
    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      setState(() {
        _requests = data.cast<Map<String, dynamic>>();
      });
    } else {
      setState(() {
        _error = 'Failed to load: ${resp.statusCode}';
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : _requests.isEmpty
          ? const Center(child: Text('No pending requests'))
          : ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (_, i) {
          final req = _requests[i];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('To: ${req['ownerName'] ?? req['ownerId']}'),
              subtitle: Text(
                'Amount: ${req['amount']}\nNote: ${req['message'] ?? ''}\nStatus: ${req['status']}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
