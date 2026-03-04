import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/patrol_session_provider.dart';
import '../models/patrol_models.dart';
import '../../../core/constants/app_routes.dart';

class PatrolHomePage extends StatefulWidget {
  const PatrolHomePage({super.key});

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Patroli'),
        content: const Text('Anda yakin ingin memulai sesi patroli?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.startSession(_selectedConfigId!);
    if (success && mounted) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patroli dimulai'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endPatrol() async {
    final session = context.read<PatrolSessionProvider>().activeSession;
    if (session == null) return;
    final catatanController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Patroli'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Anda yakin ingin menyelesaikan sesi patroli?'),
            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.endSession(
      session.id,
      catatan: catatanController.text.isNotEmpty
          ? catatanController.text
          : null,
    );
    if (success && mounted) {
      _durationTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patroli selesai'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cancelPatrol() async {
    final session = context.read<PatrolSessionProvider>().activeSession;
    if (session == null) return;
    final alasanController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Patroli'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Anda yakin ingin membatalkan sesi patroli?'),
            const SizedBox(height: 12),
            TextField(
              controller: alasanController,
              decoration: const InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Batalkan Patroli'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final provider = context.read<PatrolSessionProvider>();
    final success = await provider.cancelSession(
      session.id,
      alasan: alasanController.text.isNotEmpty
          ? alasanController.text
          : null,
    );
    if (success && mounted) {
      _durationTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patroli dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatrolSessionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.configs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.configs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.loadConfigs(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadConfigs();
            if (provider.hasActiveSession) {
              await provider.refreshProgress();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting
              Text(
                'Halo, Petugas!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              if (provider.hasActiveSession)
                _buildActiveSessionView(provider)
              else
                _buildStartView(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartView(PatrolSessionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Config selector
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Konfigurasi Patroli',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (provider.configs.isEmpty)
                  const Text(
                    'Tidak ada konfigurasi patroli aktif.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _selectedConfigId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Pilih konfigurasi...'),
                    items: provider.configs.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.namaKonfigurasi, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedConfigId = val),
                  ),
              ],
            ),
          ),
        ),

        // Config info
        if (_selectedConfigId != null) ...[
          const SizedBox(height: 12),
          _buildConfigInfoCard(provider.configs
              .firstWhere((c) => c.id == _selectedConfigId)),
        ],

        const SizedBox(height: 20),

        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedConfigId != null && !provider.isStarting
                ? _startPatrol
                : null,
            icon: provider.isStarting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(provider.isStarting ? 'Memulai...' : 'Mulai Patroli'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigInfoCard(PatrolConfig config) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF0F4FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E40AF)),
                const SizedBox(width: 8),
                const Text('Info Konfigurasi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Mode', config.modeLabel),
            _infoRow('Checkpoint', '${config.checkpointsCount} titik'),
            if (config.durasiPatroliMenit != null)
              _infoRow('Durasi', '${config.durasiPatroliMenit} menit'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionView(PatrolSessionProvider provider) {
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
        // Active session card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Patroli Sedang Berlangsung',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow('Konfigurasi', session.configNama ?? '-'),
                _infoRow('Mode', config?.modeLabel ?? '-'),
                _infoRow('Mulai', session.waktuMulai != null
                    ? DateFormat('HH:mm').format(
                        DateTime.tryParse(session.waktuMulai!) ?? DateTime.now())
                    : '-'),
                _infoRow('Durasi', _formatDuration(_elapsed)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Progress
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: provider.totalCheckpoints > 0
                            ? provider.scannedCount / provider.totalCheckpoints
                            : 0,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1E40AF),
                      ),
                      Center(
                        child: Text(
                          '${provider.scannedCount}/${provider.totalCheckpoints}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress Checkpoint',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.scannedCount} dari ${provider.totalCheckpoints} checkpoint sudah di-scan',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Next checkpoint info (for ordered modes)
        if (isOrdered && nextCp != null) ...[
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            color: const Color(0xFFFFF7ED),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.navigate_next,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 6),
                      Text('Checkpoint Selanjutnya',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(nextCp.nama,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (nextCp.lantai != null && nextCp.lantai!.isNotEmpty)
                    Text('Lantai: ${nextCp.lantai}',
                        style: TextStyle(color: Colors.grey.shade600)),
                  if (nextCp.deskripsi != null &&
                      nextCp.deskripsi!.isNotEmpty)
                    Text(nextCp.deskripsi!,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],

        if (config != null && config.isFree) ...[
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1E40AF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode bebas — Anda dapat memilih titik patroli secara bebas tanpa urutan.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.patrolScan,
                ).then((_) {
                  if (mounted) provider.refreshProgress();
                }),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.patrolReport,
                ).then((_) {
                  if (mounted) provider.refreshProgress();
                }),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // End / Cancel buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.isEnding ? null : _endPatrol,
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                label: const Text('Selesaikan',
                    style: TextStyle(color: Colors.green)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.isEnding ? null : _cancelPatrol,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label:
                    const Text('Batalkan', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
