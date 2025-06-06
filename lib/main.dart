import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'entry_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // подключение локализаций

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    try {
      final response = await http.get(
        Uri.parse('https://caprizon-a721205e360f.herokuapp.com/api/users/check-subscription'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPremium = data['isPremium'] ?? false;
        await prefs.setBool('isPremium', isPremium);
        print('🔄 Subscription status refreshed: \$isPremium');
      }
    } catch (e) {
      print('❌ Subscription check failed: \$e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartupPage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    if (token != null && userId != null) {
      return HomePage(token: token, userId: userId);
    }
    return const EntryPage();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF394168);
    const secondaryColor = Color(0xFFE91E63);
    const backgroundColor = Color(0xFFF5F5F5);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
    );

    return MaterialApp(
      title: 'Caprizon',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme()
            .apply(bodyColor: colorScheme.onBackground),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((states) =>
          states.contains(MaterialState.selected)
              ? secondaryColor
              : null),
          trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
          states.contains(MaterialState.selected)
              ? secondaryColor.withOpacity(0.5)
              : null),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(secondaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.all(secondaryColor),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getStartupPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
