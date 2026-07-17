import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/data/case_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(FlutterSecurityStore());
  final caseController = CaseController(EncryptedCaseRepository());
  await controller.initialize();
  await caseController.initialize();
  runApp(
    SupervisionPocketApp(
      controller: controller,
      caseController: caseController,
    ),
  );
}
