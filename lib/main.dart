import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/data/supervisor_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (_) => const _FriendlyErrorPanel();

  try {
    final controller = AppController(FlutterSecurityStore());
    final caseController = CaseController(EncryptedCaseRepository());
    final supervisorController = SupervisorController(
      EncryptedSupervisorRepository(),
    );
    await controller.initialize();
    await Future.wait([
      caseController.initialize(),
      supervisorController.initialize(),
    ]);
    runApp(
      SupervisionPocketApp(
        controller: controller,
        caseController: caseController,
        supervisorController: supervisorController,
      ),
    );
  } catch (_) {
    runApp(const _StartupFailureApp());
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: _FriendlyErrorPanel(),
        ),
      ),
    );
  }
}

class _FriendlyErrorPanel extends StatelessWidget {
  const _FriendlyErrorPanel();

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48),
              SizedBox(height: 16),
              Text(
                'Не удалось открыть этот экран',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                'Закройте приложение и откройте его снова. Сохранённые записи останутся на устройстве.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
