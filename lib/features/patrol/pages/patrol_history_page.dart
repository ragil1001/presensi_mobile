import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/patrol_history_provider.dart';
import '../models/patrol_models.dart';
import '../../../core/constants/app_routes.dart';

class PatrolHistoryPage extends StatefulWidget {
  const PatrolHistoryPage({super.key});

  @override
  State<PatrolHistoryPage> createState() => _PatrolHistoryPageState();
}

class _PatrolHistoryPageState extends State<PatrolHistoryPage> {
  late int _bulan;
  late int _tahun;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<PatrolHistoryProvider>().loadSessions(_bulan, _tahun);
  }

  void _prevMonth() {
    setState(() {
      if (_bulan == 1) {
        _bulan = 12;
        _tahun--;
      } else {
        _bulan--;
      }
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      if (_bulan == 12) {
        _bulan = 1;
        _tahun++;
      } else {
        _bulan++;
      }
    });
    _load();
  }

  String _monthLabel() {
    final dt = DateTime(_tahun, _bulan);
    return DateFormat('MMMM yyyy', 'id').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatrolHistoryProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _monthLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('Tidak ada riwayat patroli',
                                  style:
                                      TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: provider.sessions.length,
                            itemBuilder: (context, index) {
                              return _SessionCard(
                                session: provider.sessions[index],
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.patrolHistoryDetail,
                                    arguments: provider.sessions[index].id,
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PatrolSession session;
  final VoidCallback? onTap;

  const _SessionCard({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = session.isSelesai
        ? Colors.green
        : session.isDibatalkan
            ? Colors.red
            : Colors.orange;
    final statusLabel = session.isSelesai
        ? 'SELESAI'
        : session.isDibatalkan
            ? 'DIBATALKAN'
            : 'BERLANGSUNG';

    String? durasi;
    if (session.waktuMulai != null && session.waktuSelesai != null) {
      final start = DateTime.tryParse(session.waktuMulai!);
      final end = DateTime.tryParse(session.waktuSelesai!);
      if (start != null && end != null) {
        final diff = end.difference(start);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        durasi = h > 0 ? '${h}j ${m}m' : '${m} menit';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.configNama ?? 'Patroli',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (session.projectNama != null)
                Text(session.projectNama!,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    session.tanggal,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (session.waktuMulai != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(
                          DateTime.tryParse(session.waktuMulai!) ??
                              DateTime.now()),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  if (durasi != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(durasi,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.qr_code_scanner,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${session.scansCount ?? session.totalCheckpointScan} scan',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
