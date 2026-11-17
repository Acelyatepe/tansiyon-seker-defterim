import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../services/measurement_store.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class AppStartup extends StatefulWidget {
  const AppStartup({
    super.key,
    this.preferences,
    this.store,
  });

  final AppPreferences? preferences;
  final MeasurementStore? store;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late final AppPreferences _preferences =
      widget.preferences ??
      AppPreferences(DevicePreferencesStorage());

  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    try {
      await _preferences.load();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    if (widget.preferences == null) {
      _preferences.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SizedBox.expand(),
      );
    }

    if (_failed) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tercihler okunamadı. Lütfen tekrar deneyin.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_preferences.welcomeSeen) {
      return WelcomeScreen(
        preferences: _preferences,
        onContinue: () => setState(() {}),
      );
    }

    return HomeScreen(
      store: widget.store,
      preferences: _preferences,
    );
  }
}