import 'package:flutter/material.dart';
import 'package:supervision_pocket/core/widgets/reset_application_dialog.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/presentation/supervisor_shell.dart';
import 'package:supervision_pocket/features/transfer/presentation/request_transfer_flow.dart';

class SupervisorWorkspaceHost extends StatelessWidget {
  const SupervisorWorkspaceHost({
    required this.controller,
    required this.onLock,
    required this.onChangeRole,
    required this.onResetAll,
    super.key,
  });

  final SupervisorController controller;
  final VoidCallback onLock;
  final VoidCallback onChangeRole;
  final Future<void> Function() onResetAll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SupervisorShell(
          controller: controller,
          onLock: onLock,
          onChangeRole: onChangeRole,
        ),
        Positioned(
          right: 16,
          bottom: 92,
          child: SafeArea(
            minimum: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'supervisor-reset',
                  tooltip: 'Начать заново',
                  onPressed: () => showResetApplicationDialog(
                    context,
                    onReset: onResetAll,
                  ),
                  child: const Icon(Icons.restart_alt_rounded),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'supervisor-import',
                  onPressed: () => importRequestPackage(context, controller),
                  icon: const Icon(Icons.move_to_inbox_outlined),
                  label: const Text('Получить запрос'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
