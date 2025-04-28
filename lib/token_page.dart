import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokenPage extends StatefulWidget {
  final String token;
  final String userId;

  const TokenPage({super.key, required this.token, required this.userId});

  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  List<Map<String, dynamic>> tokens = [];
  List<String> members = [];
  String? selectedTokenId;
  String message = '';

  Future<void> fetchTokens() async {
    final response = await http.get(Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      setState(() {
        tokens = list.map((t) => {
          ...Map<String, dynamic>.from(t),
          'tokenId': t['tokenId'].toString(),
        }).toList();
      });
    }
  }

  Future<void> addMember(String tokenId, String userId) async {
    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/add-member'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'tokenId': tokenId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        message = 'User added successfully';
        fetchTokens();  // Refresh the list of tokens
      });
    } else {
      setState(() {
        message = 'Failed to add user';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tokens')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (tokens.isNotEmpty)
              DropdownButton<String>(
                value: selectedTokenId,
                hint: const Text('Select a Token'),
                onChanged: (value) {
                  setState(() {
                    selectedTokenId = value;
                  });
                },
                items: tokens.map((token) {
                  return DropdownMenuItem<String>(
                    value: token['tokenId'],
                    child: Text(token['name']),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedTokenId != null ? () {
                // Here you can open a dialog or page to select a user to add to the token
                // For now, let's just call addMember directly with a dummy userId
                addMember(selectedTokenId!, "dummyUserId");
              } : null,
              child: const Text('Add Member to Token'),
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
