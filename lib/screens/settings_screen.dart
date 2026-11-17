import 'package:flutter/material.dart';

import '../core/constants/legal_text.dart';
import '../core/diagnostics/app_log.dart';
import '../core/theme/app_colors.dart';
import '../services/app_preferences.dart';
import '../services/measurement_store.dart';
import '../services/rewarded_ads.dart';
import '../services/support_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.store,
    this.ads,
  });

  final AppPreferences preferences;
  final MeasurementStore store;
  final RewardedAds? ads;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _support = SupportController(
    widget.preferences,
    widget.ads ?? GoogleRewardedAds(),
  );

  String _version = 'Yükleniyor…';
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final version = await DeviceMeasurementStorage.channel
          .invokeMethod<String>('appVersion')
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _version = version ?? 'Bilinmiyor';
        });
      }
    } catch (error, stack) {
      logFailure(
        'Uygulama sürümünü okuma',
        error,
        stack,
      );

      if (mounted) {
        setState(() {
          _version = 'Bilinmiyor';
        });
      }
    }
  }

  void _showSuccessMessage() {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 22,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.bloodSugar,
                        size: 24,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Veriler silindi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(
      const Duration(milliseconds: 1500),
      entry.remove,
    );
  }

  Future<void> _deleteAllData() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.bloodPressure.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.bloodPressure,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tüm veriler silinsin mi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kaydettiğin tüm tansiyon ve şeker ölçümleri silinir. Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(
                              color: Color(0xFFE2E0DC),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Vazgeç',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.bloodPressure,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Tümünü Sil',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      await widget.store.deleteAll();

      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      _showSuccessMessage();
    } catch (error, stack) {
      logFailure(
        'Tüm ölçüm kayıtlarını silme',
        error,
        stack,
      );

      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veriler silinemedi. Lütfen tekrar deneyin.',
          ),
        ),
      );
    }
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEAE8E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 9,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _support.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _support,
            widget.preferences,
          ]),
          builder: (context, _) {
            return ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28,
              ),
              children: [
                const Text(
                  'Uygulama ayarları',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gizlilik, destek ve uygulama bilgilerini görüntüle.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 22),

                // DESTEK
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.bloodSugar.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.favorite_border_rounded,
                              color: AppColors.bloodSugar,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Text(
                              'Uygulamaya destek ol',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'İsteğe bağlı olarak bir reklam izleyerek uygulamanın geliştirilmesine destek olabilirsin.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.mutedText,
                        ),
                      ),
                      if (widget.preferences.supporter) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bloodSugar.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 16,
                                  color: AppColors.bloodSugar,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Destekçi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.bloodSugar,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed:
                              _support.busy ? null : _support.watch,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.text,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: _support.busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Reklam izle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      if (_support.message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _support.message!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TIBBİ UYARI
                _card(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Row(
  children: [
    Icon(
      Icons.medical_information_outlined,
      color: AppColors.bloodPressure,
    ),
    SizedBox(width: 10),
    Expanded(
      child: Text(
        'Tıbbi uyarı',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    ),
  ],
),
                      SizedBox(height: 12),
                      Text(
                        LegalText.medicalNotice,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // UYGULAMA
                _sectionTitle('UYGULAMA'),

                _card(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
  Icons.info_outline_rounded,
  color: AppColors.text,
),
                        title: const Text(
                          'Uygulama hakkında',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Tansiyon ve şeker ölçümlerini kaydetmene ve takip etmene yardımcı olur.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ),

                      const Divider(
                        height: 1,
                        color: Color(0xFFEAE8E4),
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.text,
                        ),
                        title: const Text(
                          'Gizlilik Politikası',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.text,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder<void>(
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                              pageBuilder: (
                                context,
                                _,
                                __,
                              ) {
                                return Scaffold(
                                  backgroundColor:
                                      AppColors.background,
                                  appBar: AppBar(
                                    backgroundColor:
                                        AppColors.background,
                                    surfaceTintColor:
                                        Colors.transparent,
                                    title: const Text(
                                      'Gizlilik Politikası',
                                    ),
                                  ),
                                  body: const SafeArea(
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.all(24),
                                      child: SelectableText(
                                        LegalText.privacy,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const Divider(
                        height: 1,
                        color: Color(0xFFEAE8E4),
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.text,
                        ),
                        title: const Text(
                          'Sürüm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        trailing: Text(
                          _version,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // VERİLER
                _sectionTitle('VERİLER'),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.bloodPressure.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
child: Material(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  clipBehavior: Clip.antiAlias,
  child: ListTile(                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.bloodPressure.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: AppColors.bloodPressure,
                      ),
                    ),
                    title: const Text(
                      'Tüm verileri sil',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bloodPressure,
                      ),
                    ),
                    subtitle: const Text(
                      'Tüm tansiyon ve şeker ölçümlerini sil',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                    trailing: _deleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.bloodPressure,
                          ),
                    onTap: _deleting
                        ? null
                        : _deleteAllData,
                  ),
                ),
              ),
              ],
            );
          },
        ),
      ),
    );
  }
}