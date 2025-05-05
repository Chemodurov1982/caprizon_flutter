import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokenRulesPage extends StatefulWidget {
  final String token;
  final String tokenId;
  final String userId;
  final bool isAdmin;

  const TokenRulesPage({
    Key? key,
    required this.token,
    required this.tokenId,
    required this.userId,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<TokenRulesPage> createState() => _TokenRulesPageState();
}

class _TokenRulesPageState extends State<TokenRulesPage> {
  List<String> rules = [];
  final controller = TextEditingController();
  bool loading = true;
  String message = '';

  Future<void> fetchRules() async {
    setState(() => loading = true);
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/${widget.tokenId}/rules'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final r = (data['rules'] as List).map((e) => e.toString()).toList();
      setState(() {
        rules = r;
        controller.text = r.join('\n');
        loading = false;
      });
    } else {
      setState(() {
        message = 'Failed to fetch rules';
        loading = false;
      });
    }
  }

  Future<void> saveRules() async {
    final lines = controller.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final resp = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/set-rules'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tokenId': widget.tokenId,
        'rules': lines,
      }),
    );

    if (resp.statusCode == 200) {
      setState(() => message = 'Rules saved successfully');
    } else {
      setState(() => message = 'Failed to save rules');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Rules')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isAdmin)
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Enter one rule per line',
                    border: OutlineInputBorder(),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: rules.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(rules[i]),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (widget.isAdmin)
              ElevatedButton(
                onPressed: saveRules,
                child: const Text('Save Rules'),
              ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.contains('success') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
