import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.welcome_to_caprizon)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute (builder: (_) => const LoginPage()),
              ),
              child: Text(AppLocalizations.of(context)!.login),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: Text(AppLocalizations.of(context)!.register),
            ),
          ],
        ),
      ),
    );
  }
}
