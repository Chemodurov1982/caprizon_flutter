import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'entry_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ваши фирменные цвета
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
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),

        // глобальный текстовый стиль через GoogleFonts
        textTheme: GoogleFonts.interTextTheme()
            .apply(bodyColor: colorScheme.onBackground),

        // стиль для кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // теперь задаём активный цвет для переключателей / чекбоксов через темы виджетов:
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => states.contains(MaterialState.selected)
                ? secondaryColor
                : null,
          ),
          trackColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => states.contains(MaterialState.selected)
                ? secondaryColor.withOpacity(0.5)
                : null,
          ),
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

        // и т.д. для других элементов...
      ),
      home: const EntryPage(),
    );
  }
}
