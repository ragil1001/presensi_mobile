// File: lib/features/navigation/widgets/custom_navbar.dart
// Fully responsive navbar — all sizes proportional to screen dimensions.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_confirm_dialog.dart';
import '../../../providers/presensi_provider.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTabSelected;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTabSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePresensiTap() async {
    final provider = Provider.of<PresensiProvider>(context, listen: false);
    final data = provider.presensiData;

    // Check 1: Ada jadwal hari ini?
    if (data?.jadwalHariIni == null) {
      _showWarningDialog(
        'Tidak Ada Jadwal',
        'Anda tidak memiliki jadwal hari ini.',
      );
      return;
    }

    final jadwal = data!.jadwalHariIni!;

    // Check 2: Izin/Cuti → blokir presensi
    if (jadwal.isIzin) {
      _showWarningDialog(
        'Sedang Izin / Cuti',
        'Anda tidak dapat presensi karena hari ini sedang izin/cuti yang sudah disetujui.',
      );
      return;
    }

    // Check 3: Libur → langsung masuk tanpa cek waktu
    if (jadwal.isLibur) {
      await Navigator.pushNamed(context, '/absensi');
      if (mounted) {
        Provider.of<PresensiProvider>(context, listen: false).refreshPresensiData();
      }
      return;
    }

    // Check 3: Cek waktu toleransi
    if (jadwal.waktuMulai != null && data.projectInfo != null) {
      final now = TimeOfDay.now();
      final shiftParts = jadwal.waktuMulai!.split(':');
      if (shiftParts.length >= 2) {
        final shiftHour = int.tryParse(shiftParts[0]) ?? 0;
        final shiftMinute = int.tryParse(shiftParts[1]) ?? 0;
        final toleransi = data.projectInfo!.waktuToleransi;

        // Hitung waktu mulai presensi
        final totalMinutes = shiftHour * 60 + shiftMinute - toleransi;
        final startHour = totalMinutes ~/ 60;
        final startMinute = totalMinutes % 60;
        final nowMinutes = now.hour * 60 + now.minute;

        if (nowMinutes < totalMinutes) {
          final startTime =
              '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
          _showWarningDialog(
            'Belum Waktunya Presensi',
            'Presensi dapat dimulai pukul $startTime.\nShift dimulai pukul ${jadwal.waktuMulai}.',
          );
          return;
        }
      }
    }

    await Navigator.pushNamed(context, '/absensi');
    if (mounted) {
      Provider.of<PresensiProvider>(context, listen: false).refreshPresensiData();
    }
  }

  void _showWarningDialog(String title, String message) {
    CustomConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: 'OK',
      icon: Icons.info_outline,
      iconColor: AppColors.warning,
      showCancel: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // All key dimensions proportional to screen size
    final navbarHeight = (screenHeight * 0.095).clamp(70.0, 90.0);
    final circleRadius = (screenWidth * 0.13).clamp(42.0, 54.0);
    final centerButtonSize = circleRadius * 1.4;
    final navIconSize = (screenWidth * 0.06).clamp(20.0, 27.0);
    final presensiLabelFontSize = (screenWidth * 0.03).clamp(10.0, 13.0);
    final presensiLabelSpacing = (screenHeight * 0.018).clamp(8.0, 32.0);
    final navItemWidth = (screenWidth * 0.27).clamp(90.0, 120.0);
    final navItemHeight = (screenHeight * 0.078).clamp(55.0, 72.0);
    final centerGap = (screenWidth * 0.15).clamp(50.0, 70.0);
    final activeFontSize = (screenWidth * 0.037).clamp(12.0, 16.0);
    final inactiveFontSize = (screenWidth * 0.032).clamp(11.0, 14.0);
    final iconBoxHeight = (navItemHeight * 0.43).clamp(22.0, 30.0);
    final labelBoxHeight = (navItemHeight * 0.33).clamp(18.0, 24.0);
    final cornerRadius = (screenWidth * 0.1).clamp(32.0, 44.0);
    final notchDepth = (screenHeight * 0.045).clamp(32.0, 42.0);
    final painterCircleRadius = circleRadius + screenWidth * 0.025;

    return SizedBox(
      height: navbarHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(screenWidth, navbarHeight + screenWidth * 0.025),
            painter: NavbarPainter(
              circleRadius: painterCircleRadius,
              cornerRadius: cornerRadius,
              notchDepth: notchDepth,
            ),
          ),
          Positioned(
            top: -centerButtonSize / 1.8,
            left: screenWidth / 2 - centerButtonSize / 2,
            child: GestureDetector(
              onTap: _handlePresensiTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                          blurRadius: screenWidth * 0.05,
                          spreadRadius: screenWidth * 0.005,
                          offset: Offset(0, screenHeight * 0.01),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final double barHeight = centerButtonSize * 0.07;
                        final double top =
                            centerButtonSize -
                            (centerButtonSize + barHeight) * _controller.value;

                        return Container(
                          width: centerButtonSize,
                          height: centerButtonSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFC107),
                                Color(0xFFFF9800),
                                Color(0xFFF44336),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipOval(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: top,
                                  child: Opacity(
                                    opacity: 0.95,
                                    child: Container(
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    Icons.fingerprint,
                                    color: Colors.white,
                                    size: circleRadius * 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: presensiLabelSpacing),
                  Text(
                    "PRESENSI",
                    style: TextStyle(
                      fontSize: presensiLabelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedHome01,
                    color: widget.currentIndex == 0
                        ? const Color(0xFFFF9800)
                        : Colors.black87,
                    size: navIconSize,
                  ),
                  label: "BERANDA",
                  isActive: widget.currentIndex == 0,
                  onTap: () => widget.onTabSelected?.call(0),
                  itemWidth: navItemWidth,
                  itemHeight: navItemHeight,
                  activeFontSize: activeFontSize,
                  inactiveFontSize: inactiveFontSize,
                  iconBoxHeight: iconBoxHeight,
                  labelBoxHeight: labelBoxHeight,
                ),
                SizedBox(width: centerGap),
                _NavItem(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedGoogleDoc,
                    color: widget.currentIndex == 1
                        ? const Color(0xFFFF9800)
                        : Colors.black87,
                    size: navIconSize,
                  ),
                  label: "RIWAYAT",
                  isActive: widget.currentIndex == 1,
                  onTap: () => widget.onTabSelected?.call(1),
                  itemWidth: navItemWidth,
                  itemHeight: navItemHeight,
                  activeFontSize: activeFontSize,
                  inactiveFontSize: inactiveFontSize,
                  iconBoxHeight: iconBoxHeight,
                  labelBoxHeight: labelBoxHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final double itemWidth;
  final double itemHeight;
  final double activeFontSize;
  final double inactiveFontSize;
  final double iconBoxHeight;
  final double labelBoxHeight;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    required this.itemWidth,
    required this.itemHeight,
    required this.activeFontSize,
    required this.inactiveFontSize,
    required this.iconBoxHeight,
    required this.labelBoxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: iconBoxHeight,
              child: Center(child: icon),
            ),
            SizedBox(height: iconBoxHeight * 0.14),
            SizedBox(
              height: labelBoxHeight,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isActive ? activeFontSize : inactiveFontSize,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFFFF9800) : Colors.black87,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavbarPainter extends CustomPainter {
  final double circleRadius;
  final double cornerRadius;
  final double notchDepth;

  NavbarPainter({
    required this.circleRadius,
    required this.cornerRadius,
    required this.notchDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(centerX - circleRadius - 20, 0);
    path.quadraticBezierTo(
      centerX - circleRadius,
      0,
      centerX - circleRadius + 10,
      notchDepth * 0.3,
    );
    path.cubicTo(
      centerX - circleRadius * 0.5,
      notchDepth * 0.8,
      centerX - circleRadius * 0.3,
      notchDepth,
      centerX,
      notchDepth,
    );
    path.cubicTo(
      centerX + circleRadius * 0.3,
      notchDepth,
      centerX + circleRadius * 0.5,
      notchDepth * 0.8,
      centerX + circleRadius - 10,
      notchDepth * 0.3,
    );
    path.quadraticBezierTo(
      centerX + circleRadius,
      0,
      centerX + circleRadius + 20,
      0,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.grey.shade50],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    final innerShadowPath = Path();
    innerShadowPath.moveTo(centerX - circleRadius + 10, notchDepth * 0.3);
    innerShadowPath.cubicTo(
      centerX - circleRadius * 0.5,
      notchDepth * 0.8,
      centerX - circleRadius * 0.3,
      notchDepth,
      centerX,
      notchDepth,
    );
    innerShadowPath.cubicTo(
      centerX + circleRadius * 0.3,
      notchDepth,
      centerX + circleRadius * 0.5,
      notchDepth * 0.8,
      centerX + circleRadius - 10,
      notchDepth * 0.3,
    );

    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(innerShadowPath, innerShadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
