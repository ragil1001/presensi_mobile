import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';

class CsDailyStatsCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;

  const CsDailyStatsCard({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final remaining = totalTasks - completedTasks;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final isComplete = progress >= 1.0;
    final accentColor = isComplete ? AppColors.success : AppColors.primary;

    return Container(
      padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.045),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => SizedBox(
                  width: sw * 0.18,
                  height: sw * 0.18,
                  child: CustomPaint(
                    painter: _CircleProgressPainter(
                      progress: value,
                      accentColor: accentColor,
                      trackColor: accentColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: (sw * 0.045).clamp(16.0, 20.0),
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppFontSize.paddingH(sw)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Semua Selesai!' : 'Progress Hari Ini',
                      style: TextStyle(
                        fontSize: AppFontSize.body(sw),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: AppFontSize.small(sw),
                          color: AppColors.textTertiary,
                        ),
                        children: [
                          TextSpan(
                            text: '$completedTasks',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          TextSpan(text: ' dari $totalTasks tugas selesai'),
                        ],
                      ),
                    ),
                    if (!isComplete) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sisa $remaining tugas lagi',
                        style: TextStyle(
                          fontSize: AppFontSize.caption(sw),
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppFontSize.paddingV(sw)),
          Row(
            children: [
              _buildStatChip(Icons.assignment_outlined, 'Total', totalTasks,
                  AppColors.info, sw),
              const SizedBox(width: 8),
              _buildStatChip(Icons.check_circle_outline_rounded, 'Selesai',
                  completedTasks, AppColors.success, sw),
              const SizedBox(width: 8),
              _buildStatChip(Icons.pending_outlined, 'Sisa', remaining,
                  AppColors.warning, sw),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, int value, Color color, double sw) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              '$value',
              style: TextStyle(
                fontSize: AppFontSize.body(sw),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;

  _CircleProgressPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 7.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [
            accentColor.withValues(alpha: 0.6),
            accentColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}
