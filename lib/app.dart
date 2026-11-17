import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_startup.dart';
import 'services/app_preferences.dart';
import 'services/measurement_store.dart';

class TansiyonSekerDefterimApp extends StatelessWidget {
  const TansiyonSekerDefterimApp({super.key, this.store, this.preferences});
  final MeasurementStore? store;
  final AppPreferences? preferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: AppStartup(store: store, preferences: preferences),
    );
  }
}
