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

  Future<void> _confirmAndDelete(String requestId) async {
    print('Tapped delete for requestId: \$requestId');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRequest(requestId);
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    final uri = Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/requests/$requestId');
    final resp = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (resp.statusCode == 200) {
      setState(() {
        _requests.removeWhere((r) => r['requestId'] == requestId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete request')),
      );
    }
  }

  String formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('To: ${req['ownerName'] ?? req['ownerId']}'),
              subtitle: Text(
                'Amount: ${req['amount']}\n'
                    'Note: ${req['message'] ?? ''}\n'
                    'Status: ${req['status']}\n'
                    'Created: ${formatDate(req['createdAt'] ?? '')}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  final id = req['requestId'];
                  if (id != null) {
                    _confirmAndDelete(id);
                  } else {
                    print('⚠️ requestId is null for request: \$req');
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
