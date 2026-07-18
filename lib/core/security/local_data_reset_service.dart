import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalDataResetService {
  LocalDataResetService({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<void> clearVaultFiles() async {
    final directory = await _directoryProvider();
    const names = [
      'cases.vault',
      'cases.vault.tmp',
      'supervisor_workspace.vault',
      'supervisor_workspace.vault.tmp',
    ];
    for (final name in names) {
      final file = File('${directory.path}/$name');
      if (await file.exists()) await file.delete();
    }
  }
}
