import 'package:flutter/material.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: checkpoint.sudahScan
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: checkpoint.sudahScan
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: checkpoint.sudahScan
                      ? const Icon(Icons.check, color: Colors.green, size: 20)
                      : showOrder
                          ? Text(
                              '${checkpoint.orderIndex}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            )
                          : Icon(Icons.circle_outlined,
                              color: Colors.grey.shade400, size: 20),
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
                              fontSize: 14,
                              color: checkpoint.sudahScan
                                  ? Colors.green.shade700
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (checkpoint.isWajib)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'Wajib',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
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
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    if (checkpoint.deskripsi != null &&
                        checkpoint.deskripsi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        checkpoint.deskripsi!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (checkpoint.sudahScan)
                Icon(Icons.verified, color: Colors.green.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
