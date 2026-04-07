import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/auth_provider.dart';
import '../providers/patrol_session_provider.dart';
import '../models/patrol_models.dart';

class PatrolHomePage extends StatefulWidget {
  final VoidCallback? onSwitchToCheckpoints;

  const PatrolHomePage({super.key, this.onSwitchToCheckpoints});

  @override
  State<PatrolHomePage> createState() => _PatrolHomePageState();
}

class _PatrolHomePageState extends State<PatrolHomePage> {
  int? _selectedConfigId;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = context.read<PatrolSessionProvider>().activeSession;
      if (session != null && session.waktuMulai != null) {
        final start = DateTime.tryParse(session.waktuMulai!);
        if (start != null && mounted) {
          setState(() => _elapsed = DateTime.now().difference(start));
        }
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _startPatrol() async {
    if (_selectedConfigId == null) return;
    final sw = MediaQuery.of(context).size.width;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mulai Patroli',
            style: TextStyle(
                fontSize: AppFontSize.subtitle(sw),
                fontWeight: FontWeight.w700)),
        content: Text('Anda yakin ingin memulai sesi patroli?',
            style: TextStyle(fontSize: AppFontSize.body(sw))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppFontSize.body(sw))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Mulai', style: TextStyle(fontSize: AppFontSize.body(sw))),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.startSession(_selectedConfigId!);
    if (success && mounted) {
      _startTimer();
      CustomSnackbar.showSuccess(context, 'Patroli dimulai');
    } else if (provider.error != null && mounted) {
      CustomSnackbar.showError(context, provider.error!);
    }
  }

  Future<void> _endPatrol() async {
    final session = context.read<PatrolSessionProvider>().activeSession;
    if (session == null) return;
    final sw = MediaQuery.of(context).size.width;
    final catatanController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Selesaikan Patroli',
            style: TextStyle(
                fontSize: AppFontSize.subtitle(sw),
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Anda yakin ingin menyelesaikan sesi patroli?',
                style: TextStyle(fontSize: AppFontSize.body(sw))),
            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppFontSize.body(sw))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Selesaikan',
                style: TextStyle(fontSize: AppFontSize.body(sw))),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.endSession(
      session.id,
      catatan:
          catatanController.text.isNotEmpty ? catatanController.text : null,
    );
    if (success && mounted) {
      _durationTimer?.cancel();
      CustomSnackbar.showSuccess(context, 'Patroli selesai');
    }
  }

  Future<void> _cancelPatrol() async {
    final session = context.read<PatrolSessionProvider>().activeSession;
    if (session == null) return;
    final sw = MediaQuery.of(context).size.width;
    final alasanController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Patroli',
            style: TextStyle(
                fontSize: AppFontSize.subtitle(sw),
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Anda yakin ingin membatalkan sesi patroli?',
                style: TextStyle(fontSize: AppFontSize.body(sw))),
            const SizedBox(height: 12),
            TextField(
              controller: alasanController,
              decoration: InputDecoration(
                labelText: 'Alasan (opsional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppFontSize.body(sw))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Batalkan Patroli',
                style: TextStyle(fontSize: AppFontSize.body(sw))),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.cancelSession(
      session.id,
      alasan:
          alasanController.text.isNotEmpty ? alasanController.text : null,
    );
    if (success && mounted) {
      _durationTimer?.cancel();
      CustomSnackbar.showWarning(context, 'Patroli dibatalkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.06;

    return Consumer<PatrolSessionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const _PatrolHomeShimmer();
        }
        if (provider.error != null && provider.configs.isEmpty) {
          return ErrorStateWidget(
            message: provider.error!,
            onRetry: () => provider.loadConfigs(),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await provider.loadConfigs();
            if (provider.hasActiveSession) {
              await provider.refreshProgress();
            }
          },
          child: ListView(
            padding: EdgeInsets.all(padding),
            children: [
              _buildGreeting(sw),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
                style: TextStyle(
                  fontSize: AppFontSize.small(sw),
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              if (provider.hasActiveSession)
                _buildActiveSessionView(provider, sw)
              else
                _buildStartView(provider, sw),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreeting(double sw) {
    final authProvider = context.read<AuthProvider>();
    final karyawan = authProvider.currentUser;
    final namaParts = karyawan?.nama.split(' ') ?? [];
    final userName = namaParts.length >= 2
        ? '${namaParts[0]} ${namaParts[1]}'
        : (namaParts.isNotEmpty ? namaParts[0] : 'User');

    return Text(
      'Halo, $userName!',
      style: TextStyle(
        fontSize: (sw * 0.055).clamp(20.0, 24.0),
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStartView(PatrolSessionProvider provider, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.045),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Konfigurasi Patroli',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppFontSize.body(sw),
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.configs.isEmpty)
                Text(
                  'Tidak ada konfigurasi patroli aktif.',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppFontSize.small(sw),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedConfigId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  hint: Text('Pilih konfigurasi...',
                      style: TextStyle(
                          fontSize: AppFontSize.body(sw),
                          color: AppColors.textTertiary)),
                  items: provider.configs.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.namaKonfigurasi,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: AppFontSize.body(sw)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedConfigId = val),
                ),
            ],
          ),
        ),
        if (_selectedConfigId != null) ...[
          const SizedBox(height: 12),
          _buildConfigInfoCard(
              provider.configs.firstWhere((c) => c.id == _selectedConfigId),
              sw),
        ],
        const SizedBox(height: 20),
        _buildGradientButton(
          sw: sw,
          label: provider.isStarting ? 'Memulai...' : 'Mulai Patroli',
          icon: Icons.play_arrow_rounded,
          onPressed: _selectedConfigId != null && !provider.isStarting
              ? _startPatrol
              : null,
          isLoading: provider.isStarting,
        ),
      ],
    );
  }

  Widget _buildConfigInfoCard(PatrolConfig config, double sw) {
    return Container(
      padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(sw * 0.045),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('Info Konfigurasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.body(sw),
                    color: AppColors.primaryDark,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Mode', config.modeLabel, sw),
          _infoRow('Checkpoint', '${config.checkpointsCount} titik', sw),
          if (config.durasiPatroliMenit != null)
            _infoRow('Durasi', '${config.durasiPatroliMenit} menit', sw),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView(PatrolSessionProvider provider, double sw) {
    final session = provider.activeSession!;
    final config = session.config ??
        (provider.configs.isNotEmpty
            ? provider.configs.firstWhere(
                (c) => c.id == session.configId,
                orElse: () => provider.configs.first,
              )
            : null);
    final isOrdered = config?.isOrdered ?? false;
    final nextCp = provider.nextCheckpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.045),
            border:
                Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sesi Patroli Sedang Berlangsung',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppFontSize.body(sw),
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Konfigurasi', session.configNama ?? '-', sw),
              _infoRow('Mode', config?.modeLabel ?? '-', sw),
              _infoRow(
                  'Mulai',
                  session.waktuMulai != null
                      ? DateFormat('HH:mm').format(
                          (DateTime.tryParse(session.waktuMulai!) ??
                              DateTime.now()).toLocal())
                      : '-',
                  sw),
              _infoRow('Durasi', _formatDuration(_elapsed), sw),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.045),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0,
                    end: provider.totalCheckpoints > 0
                        ? provider.scannedCount / provider.totalCheckpoints
                        : 0.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => SizedBox(
                  width: sw * 0.16,
                  height: sw * 0.16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                      ),
                      Center(
                        child: Text(
                          '${provider.scannedCount}/${provider.totalCheckpoints}',
                          style: TextStyle(
                            fontSize: AppFontSize.small(sw),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppFontSize.paddingH(sw)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Checkpoint',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.body(sw),
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.scannedCount} dari ${provider.totalCheckpoints} checkpoint sudah di-scan',
                      style: TextStyle(
                        fontSize: AppFontSize.small(sw),
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isOrdered && nextCp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(sw * 0.045),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.navigate_next,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 6),
                    Text('Checkpoint Selanjutnya',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.body(sw),
                          color: AppColors.warning,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(nextCp.nama,
                    style: TextStyle(
                        fontSize: AppFontSize.subtitle(sw),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (nextCp.lantai != null && nextCp.lantai!.isNotEmpty)
                  Text('Lantai: ${nextCp.lantai}',
                      style: TextStyle(
                          fontSize: AppFontSize.small(sw),
                          color: AppColors.textSecondary)),
                if (nextCp.deskripsi != null && nextCp.deskripsi!.isNotEmpty)
                  Text(nextCp.deskripsi!,
                      style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: AppFontSize.caption(sw))),
              ],
            ),
          ),
        ],
        if (config != null && config.isFree) ...[
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(sw * 0.045),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode bebas — Anda dapat memilih titik patroli secara bebas tanpa urutan.',
                    style: TextStyle(
                        fontSize: AppFontSize.small(sw),
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                sw: sw,
                label: 'Scan QR',
                icon: Icons.qr_code_scanner,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.patrolScan,
                ).then((_) {
                  if (mounted) provider.refreshProgress();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.patrolReport,
                ).then((_) {
                  if (mounted) provider.refreshProgress();
                }),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Laporan',
                        style: TextStyle(
                          fontSize: AppFontSize.button(sw),
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: provider.isEnding ? null : _endPatrol,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 6),
                      Text('Selesaikan Sesi',
                          style: TextStyle(
                            fontSize: AppFontSize.body(sw),
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: provider.isEnding ? null : _cancelPatrol,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel_outlined,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 6),
                      Text('Batalkan Sesi',
                          style: TextStyle(
                            fontSize: AppFontSize.body(sw),
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, double sw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: sw * 0.25,
            child: Text(label,
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: AppFontSize.small(sw),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required double sw,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              onPressed();
            }
          : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : AppColors.grey,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.button(sw),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatrolHomeShimmer extends StatelessWidget {
  const _PatrolHomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 200, height: 24),
            const SizedBox(height: 6),
            const ShimmerBox(width: 140, height: 14),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 200, height: 14),
                  SizedBox(height: 12),
                  ShimmerBox(height: 48, borderRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ShimmerBox(height: 52, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}
