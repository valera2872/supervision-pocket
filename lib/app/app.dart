import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/app/theme/app_theme.dart';
import 'package:supervision_pocket/features/lock/presentation/unlock_screen.dart';
import 'package:supervision_pocket/features/onboarding/presentation/onboarding_flow.dart';
import 'package:supervision_pocket/features/today/presentation/main_shell.dart';

class SupervisionPocketApp extends StatefulWidget {
  const SupervisionPocketApp({required this.controller, super.key});

  final AppController controller;

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
            AppGate.ready => MainShell(onLock: widget.controller.lock),
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
