import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervision_pocket/features/cases/application/case_controller.dart';
import 'package:supervision_pocket/features/cases/domain/case_models.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/sync/data/cloud_sync_service.dart';
import 'package:supervision_pocket/features/transfer/data/supervision_transfer_service.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({
    required this.role,
    this.caseController,
    this.supervisorController,
    super.key,
  });

  final String role;
  final CaseController? caseController;
  final SupervisorController? supervisorController;

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final CloudSyncService _service = CloudSyncService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _invitationLink = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;
  bool _loading = false;
  bool _registerMode = false;
  String? _message;
  String? _createdInvitationLink;
  List<CloudConnection> _connections = const [];
  List<CloudRequestItem> _requests = const [];

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) _refresh();
    });
    if (_service.currentUser != null) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _invitationLink.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_service.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _connections = const [];
        _requests = const [];
      });
      return;
    }
    await _run(() async {
      final results = await Future.wait([
        _service.listConnections(),
        _service.listRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _connections = results[0] as List<CloudConnection>;
        _requests = results[1] as List<CloudRequestItem>;
      });
    }, successMessage: null);
  }

  Future<void> _authenticate() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _message = 'Введите email и пароль не короче 6 символов.');
      return;
    }
    if (_displayName.text.trim().isEmpty) {
      setState(() => _message = 'Укажите имя, которое увидит второй участник.');
      return;
    }
    await _run(() async {
      if (_registerMode) {
        final response = await _service.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
          role: widget.role,
        );
        if (response.session == null) {
          if (!mounted) return;
          setState(() {
            _message =
                'Аккаунт создан. Откройте письмо Supabase и подтвердите email, затем войдите.';
          });
          return;
        }
      } else {
        await _service.signIn(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
          role: widget.role,
        );
      }
      await _refresh();
    }, successMessage: _registerMode ? 'Аккаунт создан' : 'Вход выполнен');
  }

  Future<void> _createInvitation() async {
    await _run(() async {
      final invitation = await _service.createInvitation();
      if (!mounted) return;
      setState(() => _createdInvitationLink = invitation.shareLink);
      await Clipboard.setData(ClipboardData(text: invitation.shareLink));
    }, successMessage: 'Ссылка приглашения скопирована');
  }

  Future<void> _acceptInvitation() async {
    if (_invitationLink.text.trim().isEmpty) {
      setState(() => _message = 'Вставьте полную ссылку приглашения.');
      return;
    }
    await _run(() async {
      await _service.acceptInvitation(_invitationLink.text);
      _invitationLink.clear();
      await _refresh();
    }, successMessage: 'Связь с супервизором создана');
  }

  Future<void> _sendEntry(
    CaseFile caseFile,
    ReflectionEntry entry,
  ) async {
    final available = _connections.where((item) => item.keyAvailable).toList();
    if (available.isEmpty) {
      setState(() => _message = 'Сначала подключитесь к супервизору.');
      return;
    }
    final selected = await showModalBottomSheet<CloudConnection>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              'Кому передать запрос?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final connection in available)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.supervisor_account_outlined),
                ),
                title: Text(connection.peerName),
                subtitle: const Text('Передача с шифрованием на устройстве'),
                onTap: () => Navigator.pop(context, connection),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;

    final payload = TransferRequestPayload(
      caseAlias: caseFile.alias,
      ageRange: caseFile.ageRange,
      caseContext: caseFile.context,
      mode: entry.mode == ReflectionMode.casePreparation
          ? 'casePreparation'
          : 'quick',
      observedFact: entry.observedFact,
      interpretation: entry.interpretation,
      feeling: entry.feeling,
      impulse: entry.impulse,
      actionTaken: entry.actionTaken,
      stuckPoint: entry.stuckPoint,
      question: entry.supervisionQuestion,
      clientRequest: entry.clientRequest,
      relevantContext: entry.relevantContext,
      currentDynamics: entry.currentDynamics,
      workingHypothesis: entry.workingHypothesis,
      previousAttempts: entry.previousAttempts,
      resources: entry.resources,
      ethicalContext: entry.ethicalContext,
      requestType: entry.requestType.name,
      createdAt: entry.createdAt,
    );
    await _run(() async {
      await _service.sendRequest(
        connection: selected,
        payload: payload.toJson(),
      );
      await _refresh();
    }, successMessage: 'Запрос передан супервизору');
  }

  Future<void> _saveInSupervisorWorkspace(CloudRequestItem item) async {
    final controller = widget.supervisorController;
    final payload = item.payload;
    if (controller == null || payload == null) return;
    final connection = _connections
        .where((candidate) => candidate.id == item.connectionId)
        .firstOrNull;
    final peerName = connection?.peerName ?? 'Супервизант';
    final material = TransferRequestPayload.fromJson(payload);

    await _run(() async {
      var supervisee = controller.supervisees
          .where((candidate) => candidate.displayName == peerName)
          .firstOrNull;
      supervisee ??= await controller.addSupervisee(
        displayName: peerName,
        professionalContext: 'Подключён через защищённую связь',
      );
      await controller.addRequest(
        superviseeId: supervisee.id,
        question: material.question,
        context: material.toSupervisorContext(),
      );
      await _service.markRequestSeen(item.id);
      await _refresh();
    }, successMessage: 'Запрос сохранён в кабинете супервизора');
  }

  Future<void> _revoke(CloudConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отключить специалиста?'),
        content: Text(
          'Связь с «${connection.peerName}» будет отозвана. Новые запросы по ней передать нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await _service.revokeConnection(connection.id);
      await _refresh();
    }, successMessage: 'Связь отозвана');
  }

  Future<void> _run(
    Future<void> Function() operation, {
    required String? successMessage,
  }) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await operation();
      if (!mounted || successMessage == null) return;
      setState(() => _message = successMessage);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (error) {
      if (mounted) setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _service.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Защищённая связь'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Обновить',
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _SecurityIntro(role: widget.role),
            const SizedBox(height: 16),
            if (_message != null) ...[
              _MessageCard(message: _message!),
              const SizedBox(height: 12),
            ],
            if (_loading) const LinearProgressIndicator(),
            if (_loading) const SizedBox(height: 12),
            if (user == null) _buildAuth(context) else _buildAccount(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildAuth(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _registerMode ? 'Создать аккаунт' : 'Войти',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Аккаунт нужен только для доставки зашифрованных пакетов между двумя пользователями.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Как вас подписать',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _authenticate,
              child: Text(_registerMode ? 'Создать аккаунт' : 'Войти'),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _registerMode = !_registerMode),
              child: Text(
                _registerMode
                    ? 'У меня уже есть аккаунт'
                    : 'Создать новый аккаунт',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccount(BuildContext context, User user) {
    final incoming = _requests
        .where((item) => item.senderId != user.id)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(_displayName.text.trim().isEmpty
                ? user.email ?? 'Аккаунт'
                : _displayName.text.trim()),
            subtitle: Text(user.email ?? ''),
            trailing: TextButton(
              onPressed: _loading
                  ? null
                  : () => _run(
                        _service.signOut,
                        successMessage: 'Вы вышли из аккаунта',
                      ),
              child: const Text('Выйти'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.role == 'supervisor') ...[
          _SupervisorInvitationCard(
            link: _createdInvitationLink,
            onCreate: _loading ? null : _createInvitation,
          ),
          const SizedBox(height: 16),
        ] else ...[
          _AcceptInvitationCard(
            controller: _invitationLink,
            onAccept: _loading ? null : _acceptInvitation,
          ),
          const SizedBox(height: 16),
        ],
        _ConnectionsCard(
          connections: _connections,
          onRevoke: _revoke,
        ),
        const SizedBox(height: 16),
        if (widget.role == 'psychologist')
          _PreparedRequestsCard(
            controller: widget.caseController,
            connectionsAvailable:
                _connections.any((connection) => connection.keyAvailable),
            onSend: _sendEntry,
          )
        else
          _IncomingRequestsCard(
            requests: incoming,
            connections: _connections,
            onSave: _saveInSupervisorWorkspace,
          ),
      ],
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') || text.contains('ClientException')) {
      return 'Нет соединения с сервером. Проверьте интернет и повторите.';
    }
    return text;
  }
}

class _SecurityIntro extends StatelessWidget {
  const _SecurityIntro({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сервер не получает открытый текст кейса',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  role == 'supervisor'
                      ? 'Запрос расшифровывается только на устройстве супервизора.'
                      : 'Кейс шифруется на вашем устройстве до отправки.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message),
    );
  }
}

class _SupervisorInvitationCard extends StatelessWidget {
  const _SupervisorInvitationCard({
    required this.link,
    required this.onCreate,
  });

  final String? link;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Пригласить психолога',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Создайте одноразовую ссылку и передайте её психологу. Она действует 7 дней.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Создать приглашение'),
            ),
            if (link != null) ...[
              const SizedBox(height: 12),
              SelectableText(link!),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: link!)),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Скопировать ещё раз'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AcceptInvitationCard extends StatelessWidget {
  const _AcceptInvitationCard({
    required this.controller,
    required this.onAccept,
  });

  final TextEditingController controller;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Подключиться к супервизору',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Вставьте полную ссылку, которую прислал супервизор.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Ссылка приглашения',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAccept,
              child: const Text('Подключиться'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard({
    required this.connections,
    required this.onRevoke,
  });

  final List<CloudConnection> connections;
  final Future<void> Function(CloudConnection) onRevoke;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Подключения', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (connections.isEmpty)
              const Text('Активных подключений пока нет.')
            else
              for (final connection in connections)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    connection.keyAvailable
                        ? Icons.verified_user_outlined
                        : Icons.key_off_outlined,
                  ),
                  title: Text(connection.peerName),
                  subtitle: Text(
                    connection.keyAvailable
                        ? 'Ключ связи сохранён на устройстве'
                        : 'Ожидается завершение подключения',
                  ),
                  trailing: IconButton(
                    tooltip: 'Отозвать связь',
                    onPressed: () => onRevoke(connection),
                    icon: const Icon(Icons.link_off_rounded),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PreparedRequestsCard extends StatelessWidget {
  const _PreparedRequestsCard({
    required this.controller,
    required this.connectionsAvailable,
    required this.onSend,
  });

  final CaseController? controller;
  final bool connectionsAvailable;
  final Future<void> Function(CaseFile, ReflectionEntry) onSend;

  @override
  Widget build(BuildContext context) {
    final questions = controller?.supervisionQuestions ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Передать подготовленный запрос',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (!connectionsAvailable)
              const Text('Сначала подключитесь к супервизору.')
            else if (questions.isEmpty)
              const Text('В разделе «Супервизия» пока нет подготовленных вопросов.')
            else
              for (final item in questions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.entry.supervisionQuestion),
                  subtitle: Text('${item.caseFile.alias} · ${item.caseFile.ageRange}'),
                  trailing: IconButton.filledTonal(
                    tooltip: 'Передать',
                    onPressed: () => onSend(item.caseFile, item.entry),
                    icon: const Icon(Icons.send_outlined),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _IncomingRequestsCard extends StatelessWidget {
  const _IncomingRequestsCard({
    required this.requests,
    required this.connections,
    required this.onSave,
  });

  final List<CloudRequestItem> requests;
  final List<CloudConnection> connections;
  final Future<void> Function(CloudRequestItem) onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Входящие запросы',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (requests.isEmpty)
              const Text('Новых запросов пока нет.')
            else
              for (final item in requests) _IncomingRequestTile(
                item: item,
                connection: connections
                    .where((candidate) => candidate.id == item.connectionId)
                    .firstOrNull,
                onSave: () => onSave(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({
    required this.item,
    required this.connection,
    required this.onSave,
  });

  final CloudRequestItem item;
  final CloudConnection? connection;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final payload = item.payload;
    if (payload == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline),
        title: Text(connection?.peerName ?? 'Полученный запрос'),
        subtitle: Text(item.decryptionError ?? 'Запрос зашифрован'),
      );
    }
    final material = TransferRequestPayload.fromJson(payload);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(material.question),
      subtitle: Text(
        '${connection?.peerName ?? 'Супервизант'} · ${material.caseAlias}',
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(material.toSupervisorContext()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Сохранить в кабинет'),
          ),
        ),
      ],
    );
  }
}
