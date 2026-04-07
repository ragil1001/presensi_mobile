import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/patrol_session_provider.dart';
import '../widgets/patrol_checkpoint_card.dart';
import 'patrol_history_detail_page.dart';

class PatrolCheckpointPage extends StatefulWidget {
  const PatrolCheckpointPage({super.key});

  @override
  State<PatrolCheckpointPage> createState() => _PatrolCheckpointPageState();
}

class _PatrolCheckpointPageState extends State<PatrolCheckpointPage> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await context.read<PatrolSessionProvider>().refreshProgress();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Consumer<PatrolSessionProvider>(
      builder: (context, provider, _) {
        if (_isRefreshing) {
          return _CheckpointShimmer(sw: sw);
        }

        final session = provider.activeSession;
        final config = session?.config ??
            (provider.configs.isNotEmpty
                ? provider.configs.firstWhere(
                    (c) => c.id == (session?.configId ?? 0),
                    orElse: () => provider.configs.first,
                  )
                : null);
        final isOrdered = config?.isOrdered ?? false;
        final checkpoints = provider.checkpoints;

        if (checkpoints.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 48,
                          color: AppColors.textTertiary
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('Tidak ada checkpoint',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: AppFontSize.body(sw))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sw * 0.06, 16, sw * 0.06, 8),
                  child: Row(
                    children: [
                      Text(
                        'Daftar Checkpoint',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.body(sw),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${provider.scannedCount}/${provider.totalCheckpoints}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: AppFontSize.small(sw),
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOrdered)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
                    child: Text(
                      'Checkpoint harus di-scan secara berurutan',
                      style: TextStyle(
                          fontSize: AppFontSize.caption(sw),
                          color: AppColors.warning),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cp = checkpoints[index];
                    return PatrolCheckpointCard(
                      checkpoint: cp,
                      showOrder: isOrdered,
                      onTap: cp.sudahScan && session != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatrolHistoryDetailPage(
                                      sessionId: session.id),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                  childCount: checkpoints.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

class _CheckpointShimmer extends StatelessWidget {
  final double sw;
  const _CheckpointShimmer({required this.sw});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: EdgeInsets.all(sw * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                ShimmerBox(width: sw * 0.4, height: 16),
                const Spacer(),
                const ShimmerBox(width: 50, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShimmerBox(height: 80, borderRadius: sw * 0.035),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
