import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../services/measurement_store.dart';
import '../services/app_preferences.dart';
import 'settings_screen.dart';
import 'average_screen.dart';
import 'history_screen.dart';
import 'add_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.store,
    required this.preferences,
  });

  final MeasurementStore? store;
  final AppPreferences preferences;

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final MeasurementStore _store =
      widget.store ??
      MeasurementStore(
        DeviceMeasurementStorage(),
      );

  bool _loadFailed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadFailed = false;
      _loading = true;
    });

    try {
      await _store.load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.store == null) {
      _store.dispose();
    }

    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration:
            Duration.zero,
        pageBuilder: (
          context,
          _,
          __,
        ) =>
            SettingsScreen(
          preferences: widget.preferences,
          store: _store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          AppStrings.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        toolbarHeight: 64,
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 14,
            ),
            child: Material(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(15),
              child: InkWell(
                onTap: _openSettings,
                borderRadius:
                    BorderRadius.circular(15),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.settings_outlined,
                    size: 22,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: Text(
                  'Kayıtlar yükleniyor…',
                  style: TextStyle(
                    color:
                        AppColors.mutedText,
                  ),
                ),
              )
            : Column(
                children: [
                  if (_loadFailed)
                    Container(
                      margin:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        8,
                        20,
                        8,
                      ),
                      padding:
                          const EdgeInsets
                              .all(16),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Kayıtlar okunamadı. Mevcut dosyanız korunuyor; kayıt işlemleri için tekrar deneyin.',
                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .text,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          TextButton(
                            onPressed: _load,
                            child:
                                const Text(
                              'Tekrar dene',
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: switch (
                        _selectedIndex) {
                      0 => AddScreen(
                          onSave:
                              _store.add,
                        ),
                      1 => AverageScreen(
                          store: _store,
                        ),
                      _ => HistoryScreen(
                          store: _store,
                        ),
                    },
                  ),
                ],
              ),
      ),

      bottomNavigationBar:
          _ModernBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          if (_selectedIndex == index) {
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _ModernBottomNavigation
    extends StatelessWidget {
  const _ModernBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          12,
        ),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(24),
          border: Border.all(
            color:
                const Color(0xFFEAE8E4),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavigationItem(
              icon: Icons.add_rounded,
              label: AppStrings.add,
              selected:
                  selectedIndex == 0,
              onTap: () =>
                  onSelected(0),
            ),
            _NavigationItem(
              icon:
                  Icons.bar_chart_rounded,
              label: AppStrings.average,
              selected:
                  selectedIndex == 1,
              onTap: () =>
                  onSelected(1),
            ),
            _NavigationItem(
              icon:
                  Icons.history_rounded,
              label: AppStrings.history,
              selected:
                  selectedIndex == 2,
              onTap: () =>
                  onSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem
    extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(18),
          splashFactory:
              NoSplash.splashFactory,
          highlightColor:
              Colors.transparent,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.text
                      .withValues(
                        alpha: 0.07,
                      )
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? AppColors.text
                      : AppColors
                          .mutedText,
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: selected
                        ? AppColors.text
                        : AppColors
                            .mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}