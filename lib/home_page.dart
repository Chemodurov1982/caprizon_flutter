import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'token_rules_page.dart';
import 'create_token.dart';
import 'mint_page.dart';
import 'token_selector.dart';
import 'transfer_page.dart';
import 'transaction_history_page.dart';
import 'assign_user_page.dart';
import 'incoming_requests_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  final String userId;

  const HomePage({super.key, required this.token, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  List<Map<String, dynamic>> tokens = [];
  Map<String, dynamic> balances = {};
  List<dynamic> recentTransactions = [];
  String? selectedTokenId;
  int pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserName().then((_) => fetchTokens());
  }

  Future<void> fetchUserName() async {
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/me'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() => userName = data['name'] ?? '');
    }
  }

  Future<void> fetchTokens() async {
    final resp = await http.get(Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens'));
    if (resp.statusCode != 200) return;

    final list = jsonDecode(resp.body) as List;
    // map all tokens, then filter by membership
    final allTokens = list.map((t) {
      final m = List<String>.from((t['members'] ?? []) as List);
      return {
        ...Map<String, dynamic>.from(t),
        'tokenId': t['tokenId']?.toString() ?? t['_id'].toString(),
        'adminId': t['adminId']?.toString() ?? t['adminId'],
        'members': m,
      };
    }).toList();

    final userTokens = allTokens.where((t) {
      final members = t['members'] as List<String>;
      return members.contains(widget.userId);
    }).toList();

    setState(() {
      tokens = userTokens;
      if (selectedTokenId == null && tokens.isNotEmpty) {
        selectedTokenId = tokens[0]['tokenId'];
      }
    });

    if (selectedTokenId != null) {
      await fetchBalances();
      await fetchRecentTransactions();
      await fetchPendingRequests();
    }
  }

  Future<void> fetchBalances() async {
    if (selectedTokenId == null) return;
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/balances/${widget.userId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() => balances = Map<String, dynamic>.from(data['balances']));
    }
  }

  Future<void> fetchRecentTransactions() async {
    if (selectedTokenId == null) return;
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/transactions/token/$selectedTokenId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      // **only keep txs where current user is sender or recipient:**
      final involved = data.where((tx) =>
      tx['from'].toString() == widget.userId ||
          tx['to'].toString()   == widget.userId
      ).toList();
      setState(() => recentTransactions = involved.take(5).toList());
    }

  }

  Future<void> fetchPendingRequests() async {
    if (selectedTokenId == null) {
      setState(() => pendingRequestsCount = 0);
      return;
    }
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/requests/incoming/${widget.userId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      final count = data.where((r) => r['tokenId'] == selectedTokenId).length;
      setState(() => pendingRequestsCount = count);
    }
  }

  void openMintPage() {
    if (selectedTokenId == null) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TokenMintPage(
          token: widget.token,
          tokenId: selectedTokenId!,
          userId: widget.userId,
        ),
      ),
    ).then((_) => fetchBalances());
  }

  void openAssignUserPage() {
    if (selectedTokenId == null) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => AssignUserPage(
          token: widget.token,
          tokenId: selectedTokenId!,
        ),
      ),
    );
  }

  void openTransferPage(bool isAdmin) {
    if (selectedTokenId == null) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TransferPage(
          token: widget.token,
          tokenId: selectedTokenId!,
          fromUserId: widget.userId,
          isAdmin: isAdmin,
        ),
      ),
    ).then((result) {
      if (result == true) {
        fetchBalances();
        fetchRecentTransactions();
      }
    });
  }

  void openHistoryPage() {
    if (selectedTokenId == null) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TransactionHistoryPage(
          token: widget.token,
          userId: widget.userId,
          tokenId: selectedTokenId!,
        ),
      ),
    );
  }

  void openIncomingRequests() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => IncomingRequestsPage(
          token: widget.token,
          userId: widget.userId,
        ),
      ),
    ).then((_) async {
      await fetchBalances();
      await fetchRecentTransactions();
      await fetchPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedBalance = selectedTokenId != null
        ? (balances[selectedTokenId] ?? 0)
        : 0;
    final selectedToken = selectedTokenId != null
        ? tokens.firstWhereOrNull((t) => t['tokenId'] == selectedTokenId)
        : null;
    final isAdmin = selectedToken != null && selectedToken['adminId'] == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caprizon Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => CreateTokenPage(token: widget.token)),
            ).then((_) => fetchTokens()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting:
              if (userName.isNotEmpty)
                Text('Hello, $userName!',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              TokenSelector(
                tokens: tokens,
                selected: selectedTokenId,
                onChanged: (value) async {
                  setState(() => selectedTokenId = value);
                  await fetchBalances();
                  await fetchRecentTransactions();
                  await fetchPendingRequests();
                },
              ),
              const SizedBox(height: 16),

              Text('Balance: $selectedBalance',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),

              if (isAdmin) ...[
                ElevatedButton(
                  onPressed: openMintPage,
                  child: const Text('Create Tokens'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: openAssignUserPage,
                  child: const Text('Assign Users'),
                ),
                const SizedBox(height: 8),
              ],
              if (selectedTokenId != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => TokenRulesPage(
                        token: widget.token,
                        tokenId: selectedTokenId!,
                        userId: widget.userId,
                        isAdmin: isAdmin,
                      ),
                    ),
                  );
                },
                child: const Text('Token Rules'),
              ),
              const SizedBox(height: 8),
              if (selectedTokenId != null)
              ElevatedButton(
                onPressed: () => openTransferPage(isAdmin),
                child: const Text('Transactions'),
              ),
              const SizedBox(height: 8),

              if (pendingRequestsCount > 0) ...[
                ElevatedButton(
                  onPressed: openIncomingRequests,
                  child: Text('View Requests ($pendingRequestsCount)'),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: openHistoryPage,
                      child: const Text('View Full History')),
                ],
              ),

              ...recentTransactions.map((tx) => ListTile(
                title: Text('From ${tx['fromName']} to ${tx['toName']}'),
                subtitle: Text(tx['message'] ?? ''),
                trailing: Text('${tx['amount']}'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
