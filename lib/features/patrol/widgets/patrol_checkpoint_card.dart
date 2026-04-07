import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../models/patrol_models.dart';

class PatrolCheckpointCard extends StatelessWidget {
  final CheckpointProgress checkpoint;
  final bool showOrder;
  final VoidCallback? onTap;

  const PatrolCheckpointCard({
    super.key,
    required this.checkpoint,
    this.showOrder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: 4),
        padding: EdgeInsets.all(AppFontSize.paddingH(sw)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.035),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: checkpoint.sudahScan
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: checkpoint.sudahScan
                      ? AppColors.success
                      : AppColors.textTertiary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: checkpoint.sudahScan
                    ? const Icon(Icons.check,
                        color: AppColors.success, size: 20)
                    : showOrder
                        ? Text(
                            '${checkpoint.orderIndex}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: AppFontSize.small(sw),
                              color: AppColors.textSecondary,
                            ),
                          )
                        : const Icon(Icons.circle_outlined,
                            color: AppColors.textTertiary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          checkpoint.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSize.body(sw),
                            color: checkpoint.sudahScan
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (checkpoint.lantai != null &&
                      checkpoint.lantai!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Lantai: ${checkpoint.lantai}',
                      style: TextStyle(
                          fontSize: AppFontSize.small(sw),
                          color: AppColors.textSecondary),
                    ),
                  ],
                  if (checkpoint.deskripsi != null &&
                      checkpoint.deskripsi!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      checkpoint.deskripsi!,
                      style: TextStyle(
                          fontSize: AppFontSize.small(sw),
                          color: AppColors.textTertiary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
