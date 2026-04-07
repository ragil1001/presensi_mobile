import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_font_size.dart';
import '../providers/patrol_session_provider.dart';
import 'patrol_home_page.dart';
import 'patrol_checkpoint_page.dart';
import 'patrol_history_page.dart';

class PatrolMainPage extends StatefulWidget {
  const PatrolMainPage({super.key});

  @override
  State<PatrolMainPage> createState() => _PatrolMainPageState();
}

class _PatrolMainPageState extends State<PatrolMainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatrolSessionProvider>().loadConfigs();
    });
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Consumer<PatrolSessionProvider>(
      builder: (context, sessionProvider, _) {
        final hasSession = sessionProvider.hasActiveSession;
        final maxIndex = hasSession ? 2 : 1;
        final safeIndex = _currentIndex.clamp(0, maxIndex);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, sw),
                Expanded(
                  child: _buildPage(safeIndex, hasSession),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Beranda', safeIndex),
                    if (hasSession)
                      _buildNavItem(
                          1, Icons.checklist_rounded, 'Checkpoint', safeIndex),
                    _buildNavItem(hasSession ? 2 : 1, Icons.history_rounded,
                        'Riwayat', safeIndex),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index, bool hasSession) {
    if (hasSession) {
      return switch (index) {
        1 => const PatrolCheckpointPage(),
        2 => const PatrolHistoryPage(),
        _ => PatrolHomePage(onSwitchToCheckpoints: () => _onTabChanged(1)),
      };
    }
    return switch (index) {
      1 => const PatrolHistoryPage(),
      _ => const PatrolHomePage(),
    };
  }

  Widget _buildHeader(BuildContext context, double sw) {
    final iconBox = AppFontSize.headerIconBox(sw);
    final iconInner = AppFontSize.headerIcon(sw);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconInner,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Security Patrol',
            style: TextStyle(
              fontSize: AppFontSize.title(sw),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconBox),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onTabChanged(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.primaryDark : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
