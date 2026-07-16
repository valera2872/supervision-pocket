import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/app.dart';
import 'package:supervision_pocket/app/app_controller.dart';
import 'package:supervision_pocket/core/security/security_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(FlutterSecurityStore());
  await controller.initialize();
  runApp(SupervisionPocketApp(controller: controller));
}
