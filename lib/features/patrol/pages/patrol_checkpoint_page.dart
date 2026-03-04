import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patrol_session_provider.dart';
import '../widgets/patrol_checkpoint_card.dart';

class PatrolCheckpointPage extends StatelessWidget {
  const PatrolCheckpointPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PatrolSessionProvider>(
      builder: (context, provider, _) {
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
          return const Center(
            child: Text('Tidak ada checkpoint',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshProgress(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Daftar Checkpoint',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${provider.scannedCount}/${provider.totalCheckpoints}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isOrdered)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Checkpoint harus di-scan secara berurutan',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: checkpoints.length,
                  itemBuilder: (context, index) {
                    final cp = checkpoints[index];
                    return PatrolCheckpointCard(
                      checkpoint: cp,
                      showOrder: isOrdered,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
