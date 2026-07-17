import 'package:flutter/material.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/presentation/cases_screen.dart';
import 'package:supervision_pocket/features/supervision/presentation/supervision_screen.dart';
import 'package:supervision_pocket/features/today/presentation/today_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.onLock,
    required this.onChangeRole,
    required this.caseController,
    super.key,
  });

  final VoidCallback onLock;
  final VoidCallback onChangeRole;
  final CaseController caseController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(
        onLock: widget.onLock,
        onChangeRole: widget.onChangeRole,
        caseController: widget.caseController,
      ),
      CasesScreen(controller: widget.caseController),
      SupervisionScreen(controller: widget.caseController),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Случаи',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Супервизия',
          ),
        ],
      ),
    );
  }
}
