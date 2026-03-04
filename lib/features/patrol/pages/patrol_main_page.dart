import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Consumer<PatrolSessionProvider>(
        builder: (context, sessionProvider, _) {
          final hasSession = sessionProvider.hasActiveSession;
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                'Security Patrol',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                const PatrolHomePage(),
                if (hasSession) const PatrolCheckpointPage(),
                const PatrolHistoryPage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                // Adjust index if checkpoint tab is hidden
                if (!hasSession && index >= 1) {
                  setState(() =>
                      _currentIndex = index == 1 ? 2 : index);
                } else {
                  setState(() => _currentIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF1E40AF),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                if (hasSession)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.checklist_outlined),
                    activeIcon: Icon(Icons.checklist),
                    label: 'Checkpoint',
                  ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
