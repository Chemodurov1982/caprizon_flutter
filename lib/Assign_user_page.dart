import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignUserPage extends StatefulWidget {
  final String token;
  final String tokenId;

  const AssignUserPage({super.key, required this.token, required this.tokenId});

  @override
  State<AssignUserPage> createState() => _AssignUserPageState();
}

class _AssignUserPageState extends State<AssignUserPage> {
  TextEditingController emailController = TextEditingController();
  String message = '';

  // Function to add a user to the token
  Future<void> addUserToToken() async {
    final email = emailController.text.trim();
    print (email);
    if (email.isEmpty) {
      setState(() => message = 'Please enter an email');
      return;
    }

    // Send a request to search for the user by email
    final response = await http.post(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/search'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'}, // Send token for authorization
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final userId = userData['userId'];

      // If userId is found, send it to the server for adding the user to the token
      final assignResponse = await http.post(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens/assign-user'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokenId': widget.tokenId,
          'userId': userId, // Send userId instead of email
        }),
      );

      if (assignResponse.statusCode == 200) {
        setState(() => message = 'User added successfully');
      } else {
        setState(() => message = 'Failed to add user to token');
      }
    } else {
      setState(() => message = 'Error searching for user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign User to Token')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the participant\'s email:'),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addUserToToken,
              child: const Text('Add User'),
            ),
            const SizedBox(height: 16),
            if (message.isNotEmpty)
              Text(
                message,
                style: TextStyle(
                  color: message.startsWith('User added') ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
