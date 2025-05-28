import 'package:caprizon/upgrade_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'entry_page.dart';
import 'token_rules_page.dart';
import 'create_token.dart';
import 'sent_requests_page.dart';
import 'mint_page.dart';
import 'token_selector.dart';
import 'transfer_page.dart';
import 'transaction_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assign_user_page.dart';
import 'incoming_requests_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  int sentRequestsCount = 0;
  bool isPremium = false;


  @override
  void initState() {
    super.initState();
    fetchUserName().then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final premium = prefs.getBool('isPremium') ?? false;
      setState(() => isPremium = premium);
      await fetchTokens();
    });
  }

  Future<void> fetchUserName() async {
    try {
      final resp = await http.get(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final prefs = await SharedPreferences.getInstance();
        final premium = data['isPremium'] ?? false;
        await prefs.setBool('isPremium', premium);

        if (!mounted) return;
        setState(() {
          userName = data['name'] ?? '';
          isPremium = premium;
        });
      } else {
        debugPrint('❌ Failed to fetch user: ${resp.statusCode} ${resp.body}');
        // если токен недействителен — сбросить и вернуться на экран входа
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EntryPage()),
        );
      }
    } catch (e) {
      debugPrint('❌ Exception in fetchUserName: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EntryPage()),
      );
    }
  }


  Future<void> fetchTokens() async {
    final resp = await http.get(Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/tokens'));
    if (resp.statusCode != 200) return;

    final list = jsonDecode(resp.body) as List;
    final allTokens = list.map((t) {
      final m = List<String>.from((t['members'] ?? []) as List);
      return {
        ...Map<String, dynamic>.from(t),
        'tokenId': t['tokenId']?.toString() ?? t['_id'].toString(),
        'adminId': t['adminId']?.toString() ?? t['adminId'],
        'members': m,
      };
    }).toList();

    // Load admin names
    final uniqueAdminIds = allTokens.map((t) => t['adminId'] as String).toSet();
    Map<String, String> adminNames = {};

    for (final adminId in uniqueAdminIds) {
      final resp = await http.get(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/by-id/$adminId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        adminNames[adminId] = data['name'] ?? data['email'] ?? 'Unknown';
      } else {
        adminNames[adminId] = 'Unknown';
      }
    }

    final enrichedTokens = allTokens.map((t) {
      final adminId = t['adminId'] as String;
      return {
        ...t,
        'adminName': adminNames[adminId] ?? adminId,
      };
    }).toList();

    final userTokens = enrichedTokens.where((t) {
      final members = t['members'] as List<String>;
      return members.contains(widget.userId);
    }).toList();

    if (!mounted) return;
    setState(() {
      tokens = userTokens;
      if (selectedTokenId == null && tokens.isNotEmpty) {
        selectedTokenId = tokens[0]['tokenId'];
      }
    });

// 🔎 ОТЛАДКА: выводим список токенов и дату правил
    print('🧪 Available tokens:');
    for (final t in tokens) {
      print('  ${t['name']} (${t['tokenId']}), updated: ${t['lastRulesUpdate']}');
    }


    if (selectedTokenId != null) {
      await fetchBalances();
      await fetchRecentTransactions();
      await fetchPendingRequests();
      await fetchSentRequests();
    }
    // Проверка на обновление правил токена
    final selectedToken = tokens.firstWhereOrNull((t) => t['tokenId'] == selectedTokenId);
    print('🧪 selectedToken = ${selectedToken?['name']}, id = $selectedTokenId');
    print('🔎 lastRulesUpdate: ${selectedToken?['lastRulesUpdate']}');
    final lastUpdateStr = selectedToken?['lastRulesUpdate'];
    print('🔎 lastRulesUpdate: $lastUpdateStr');
    if (selectedTokenId != null && lastUpdateStr != null) {
      final lastUpdate = DateTime.tryParse(lastUpdateStr);
      final prefs = await SharedPreferences.getInstance();
      final lastSeenKey = 'seenRulesTimestamp_$selectedTokenId';
      final lastSeenStr = prefs.getString(lastSeenKey);
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;

      if (lastUpdate != null && (lastSeen == null || lastSeen.isBefore(lastUpdate))) {
        if (!mounted) return;
        final tokenName = selectedToken?['name'] ?? 'Token';
        final tokenSymbol = selectedToken?['symbol'] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠ Rules updated for $tokenName ($tokenSymbol)')),
        );
        await prefs.setString(lastSeenKey, lastUpdate.toIso8601String());
      }
    }


  }
  Future<void> fetchSentRequests() async {
    final resp = await http.get(
      Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/requests/sent/${widget.userId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      final pending = data.where((r) => r['status'] == 'pending').length;
      setState(() => sentRequestsCount = pending);
    } else {
      setState(() => sentRequestsCount = 0);
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
      final involved = data.where((tx) =>
      tx['from'].toString() == widget.userId ||
          tx['to'].toString() == widget.userId
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

  Future<void> refreshPage() async {
    await fetchTokens();
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

    final selectedToken = tokens.firstWhereOrNull(
          (t) => t['tokenId'] == selectedTokenId,
    );

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TransferPage(
          token: widget.token,
          tokenId: selectedTokenId!,
          fromUserId: widget.userId,
          isAdmin: isAdmin,
          tokenSymbol: selectedToken?['symbol'] ?? '',
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
          tokenSymbol: tokens.firstWhereOrNull((t) => t['tokenId'] == selectedTokenId)?['symbol'] ?? '',
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
      await fetchSentRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userName.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    final selectedBalance = selectedTokenId != null
        ? (balances[selectedTokenId] ?? 0)
        : 0;
    final selectedToken = selectedTokenId != null
        ? tokens.firstWhereOrNull((t) => t['tokenId'] == selectedTokenId)
        : null;
    final isAdmin = selectedToken != null && selectedToken['adminId'] == widget.userId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Caprizon Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Token',
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => CreateTokenPage(token: widget.token),
                ),
              ).then((_) => fetchTokens());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.hello(userName),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (!isPremium)
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UpgradePage(token: widget.token),
                                ),
                              );
                              if (result == true) {
                                await fetchUserName();
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.upgrade_to_premium),
                          ),
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const EntryPage()),
                            );
                          },
                          child: Text(AppLocalizations.of(context)!.logout),
                        ),
                      ],
                    ),
                  ],
                ),


                const SizedBox(height: 12),
                TokenSelector(
                  tokens: tokens,
                  selected: selectedTokenId,
                  onChanged: (value) async {
                    setState(() => selectedTokenId = value);
                    await fetchBalances();
                    await fetchRecentTransactions();
                    await fetchPendingRequests();
                    await fetchSentRequests();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.balance(
                    selectedToken?['symbol'] ?? '',
                    selectedBalance.toStringAsFixed(2),
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  ElevatedButton(
                    onPressed: openMintPage,
                    child: Text(AppLocalizations.of(context)!.create_tokens),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: openAssignUserPage,
                    child: Text(AppLocalizations.of(context)!.add_members),
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
                    child: Text(AppLocalizations.of(context)!.token_rules),
                  ),
                const SizedBox(height: 8),

                const SizedBox(height: 16),
                if (selectedTokenId != null)
                  ElevatedButton(
                    onPressed: () => openTransferPage(isAdmin),
                    child: Text(AppLocalizations.of(context)!.transactions),
                  ),
                const SizedBox(height: 8),
                if (sentRequestsCount > 0)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SentRequestsPage(
                            token: widget.token,
                            userId: widget.userId,
                          ),
                        ),
                      ).then((_) => fetchSentRequests()); // обновить после возврата
                    },
                    child: Text(
                      AppLocalizations.of(context)!.pending_request_with_count(sentRequestsCount),
                    ),
                  ),


                const SizedBox(height: 8),
                if (pendingRequestsCount > 0) ...[

                  ElevatedButton(
                    onPressed: openIncomingRequests,
                    child: Text(AppLocalizations.of(context)!.view_requests_with_count(pendingRequestsCount)
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.recent_transactions,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: openHistoryPage,
                        child: Text(AppLocalizations.of(context)!.view_full_history)),
                  ],
                ),
                ...recentTransactions.map((tx) {
                  final isIncoming = tx['to'] == widget.userId;
                  final symbol = selectedToken?['symbol'] ?? '';
                  final sign = isIncoming ? '+' : '-';
                  final amountText = '$sign$symbol ${tx['amount']}';

                  return ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.from_to(
                          tx['fromName'] ?? '',
                          tx['toName'] ?? '',
                        )
                    ),
                    subtitle: Text(tx['message'] ?? ''),
                    trailing: Text(
                      amountText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncoming ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
