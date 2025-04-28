import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IncomingRequestsPage extends StatefulWidget {
  final String token;
  final String userId;

  const IncomingRequestsPage({
    Key? key,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  State<IncomingRequestsPage> createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadIncoming();
  }

  Future<void> _loadIncoming() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final uri = Uri.parse(
      'https://caprizon-a721205e360f.herokuapp.com/api/requests/incoming/${widget.userId}',
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

  // после approve/reject перезагружаем список
  Future<void> _respond(String requestId, String action) async {
    final uri = Uri.parse(
        'https://caprizon-a721205e360f.herokuapp.com/api/requests/$requestId/respond');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );
    if (resp.statusCode == 200) {
      _loadIncoming();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${resp.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
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
                horizontal: 16, vertical: 8
            ),
            child: ListTile(
              title: Text('From: ${req['requesterId']}'),
              subtitle: Text(
                'Amount: ${req['amount']}\n'
                    'Note: ${req['message'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _respond(req['_id'], 'approve'),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () => _respond(req['_id'], 'reject'),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
