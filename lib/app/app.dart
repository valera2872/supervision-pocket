import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/app/theme/app_theme.dart';
import 'package:supervision_pocket/core/security/local_data_reset_service.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/lock/presentation/unlock_screen.dart';
import 'package:supervision_pocket/features/onboarding/presentation/onboarding_flow.dart';
import 'package:supervision_pocket/features/role/presentation/role_selection_screen.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/presentation/supervisor_shell.dart';
import 'package:supervision_pocket/features/today/presentation/main_shell.dart';

class SupervisionPocketApp extends StatefulWidget {
  const SupervisionPocketApp({
    required this.controller,
    required this.caseController,
    required this.supervisorController,
    super.key,
  });

  final AppController controller;
  final CaseController caseController;
  final SupervisorController supervisorController;

  @override
  State<SupervisionPocketApp> createState() => _SupervisionPocketAppState();
}

class _SupervisionPocketAppState extends State<SupervisionPocketApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      widget.controller.lock();
    }
  }

  Future<void> _resetAllData() async {
    await LocalDataResetService().clearVaultFiles();
    await widget.caseController.initialize();
    await widget.supervisorController.initialize();
    await widget.controller.resetApplication();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supervision Pocket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return switch (widget.controller.gate) {
            AppGate.loading => const _LoadingScreen(),
            AppGate.onboarding => OnboardingFlow(
                onCompleted: widget.controller.finishOnboarding,
              ),
            AppGate.locked => UnlockScreen(controller: widget.controller),
            AppGate.roleSelection => RoleSelectionScreen(
                currentRole: widget.controller.role,
                onSelected: widget.controller.chooseRole,
                onBack: widget.controller.cancelRoleSelection,
                onLock: widget.controller.lock,
              ),
            AppGate.ready => widget.controller.role == UserRole.supervisor
                ? SupervisorShell(
                    controller: widget.supervisorController,
                    onLock: widget.controller.lock,
                    onChangeRole: widget.controller.requestRoleSelection,
                    onResetAll: _resetAllData,
                  )
                : MainShell(
                    onLock: widget.controller.lock,
                    onChangeRole: widget.controller.requestRoleSelection,
                    onResetAll: _resetAllData,
                    caseController: widget.caseController,
                  ),
          };
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
