import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/supervisor/application/supervisor_controller.dart';
import 'package:supervision_pocket/features/supervisor/domain/supervisor_models.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({
    required this.controller,
    required this.onLock,
    required this.onChangeRole,
    super.key,
  });

  final SupervisorController controller;
  final VoidCallback onLock;
  final VoidCallback onChangeRole;

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Кабинет супервизора', 'Супервизанты', 'Запросы'];
    final pages = [
      _SupervisorHome(controller: widget.controller),
      _SuperviseesPage(controller: widget.controller),
      _RequestsPage(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: widget.onChangeRole,
            tooltip: 'Сменить роль',
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            onPressed: widget.onLock,
            tooltip: 'Заблокировать',
            icon: const Icon(Icons.lock_outline_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Люди',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Запросы',
          ),
        ],
      ),
    );
  }
}

class _SupervisorHome extends StatelessWidget {
  const _SupervisorHome({required this.controller});

  final SupervisorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'ЛОКАЛЬНЫЙ ПРОТОТИП',
                      style: TextStyle(
                        color: Color(0xFFD6E5E9),
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Всё к ближайшей супервизии — в одном месте',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Добавляйте супервизантов, собирайте их вопросы и отмечайте, что войдёт в повестку встречи.',
                    style: TextStyle(
                      color: Color(0xFFDCE8ED),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    value: '${controller.supervisees.length}',
                    label: 'супервизантов',
                    icon: Icons.groups_2_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    value: '${controller.newRequests.length}',
                    label: 'новых запросов',
                    icon: Icons.mark_unread_chat_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showAddSuperviseeSheet(context, controller),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Добавить супервизанта'),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Запросы к встрече',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (controller.plannedRequests.isNotEmpty)
                  Text(
                    '${controller.plannedRequests.length} в повестке',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.requests.isEmpty)
              const _EmptyPanel(
                icon: Icons.forum_outlined,
                title: 'Запросов пока нет',
                text:
                    'До защищённой синхронизации запрос можно внести вручную после того, как супервизант передал его удобным способом.',
              )
            else
              ...controller.requests.take(3).map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(
                        controller: controller,
                        request: request,
                      ),
                    ),
                  ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sync_lock_outlined, color: AppColors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Сейчас данные остаются только на этом устройстве. Приглашения и автоматическая передача между телефонами появятся после подключения защищённого сервера.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuperviseesPage extends StatelessWidget {
  const _SuperviseesPage({required this.controller});

  final SupervisorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Text(
            'Люди, с которыми вы работаете',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Используйте профессиональное имя или понятный вам псевдоним. Клиентские данные здесь не нужны.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => showAddSuperviseeSheet(context, controller),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Добавить супервизанта'),
          ),
          const SizedBox(height: 18),
          if (controller.supervisees.isEmpty)
            const _EmptyPanel(
              icon: Icons.groups_outlined,
              title: 'Список пока пуст',
              text:
                  'Добавьте первого супервизанта. Приложение создаст локальный код приглашения для будущего защищённого подключения.',
            )
          else
            ...controller.supervisees.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.paleTeal,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                profile.displayName.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (profile.professionalContext.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.professionalContext,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paleBlue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.key_rounded,
                                size: 19,
                                color: AppColors.navy,
                              ),
                              const SizedBox(width: 9),
                              const Text('Код: '),
                              Text(
                                profile.invitationCode,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Скопировать код',
                                onPressed: () => _copyInviteCode(
                                  context,
                                  profile.invitationCode,
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Код приглашения скопирован')),
    );
  }
}

class _RequestsPage extends StatelessWidget {
  const _RequestsPage({required this.controller});

  final SupervisorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Text(
            'Что обсудить на супервизии',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Новые запросы можно добавить в повестку, а после встречи отметить завершёнными.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: controller.supervisees.isEmpty
                ? null
                : () => showAddRequestSheet(context, controller),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Добавить переданный запрос'),
          ),
          if (controller.supervisees.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Сначала добавьте хотя бы одного супервизанта.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 18),
          if (controller.requests.isEmpty)
            const _EmptyPanel(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Здесь появятся запросы',
              text:
                  'В этой версии запросы вносятся вручную. Следующий серверный этап позволит супервизанту передавать их прямо из своей карточки.',
            )
          else
            ...controller.requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  controller: controller,
                  request: request,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.controller, required this.request});

  final SupervisorController controller;
  final SharedSupervisionRequest request;

  @override
  Widget build(BuildContext context) {
    final supervisee = controller.findSupervisee(request.superviseeId);
    final presentation = _statusPresentation(request.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    supervisee?.displayName ?? 'Супервизант',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<SupervisionRequestStatus>(
                  tooltip: 'Изменить статус',
                  onSelected: (status) =>
                      controller.updateRequestStatus(request.id, status),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: SupervisionRequestStatus.newRequest,
                      child: Text('Новый запрос'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.planned,
                      child: Text('Добавить в повестку'),
                    ),
                    PopupMenuItem(
                      value: SupervisionRequestStatus.completed,
                      child: Text('Завершён'),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: presentation.background,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                presentation.label,
                style: TextStyle(
                  color: presentation.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(request.question, style: Theme.of(context).textTheme.bodyLarge),
            if (request.context.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(request.context, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Text(
              _dateLabel(request.receivedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 38, color: AppColors.teal),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddSuperviseeSheet(
  BuildContext context,
  SupervisorController controller,
) async {
  final nameController = TextEditingController();
  final contextController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Новый супервизант',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте только профессиональные сведения, необходимые для организации супервизии.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя или рабочий псевдоним',
                  hintText: 'Например: Анна',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите имя или псевдоним'
                    : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contextController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Профессиональный контекст',
                  hintText: 'Например: начинающий детский психолог',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext, true);
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (accepted == true) {
    await controller.addSupervisee(
      displayName: nameController.text,
      professionalContext: contextController.text,
    );
  }
  nameController.dispose();
  contextController.dispose();
}

Future<void> showAddRequestSheet(
  BuildContext context,
  SupervisorController controller,
) async {
  if (controller.supervisees.isEmpty) return;
  final questionController = TextEditingController();
  final contextController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var superviseeId = controller.supervisees.first.id;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Переданный запрос',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Временный ручной ввод до появления защищённой синхронизации между устройствами.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: superviseeId,
                  decoration: const InputDecoration(
                    labelText: 'Супервизант',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.supervisees
                      .map(
                        (profile) => DropdownMenuItem(
                          value: profile.id,
                          child: Text(profile.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => superviseeId = value ?? superviseeId,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: questionController,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Вопрос к супервизии',
                    hintText: 'Что супервизант хочет понять или обсудить?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Введите вопрос'
                      : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contextController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Короткий контекст',
                    hintText: 'Только обезличенные сведения',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(sheetContext, true);
                    }
                  },
                  child: const Text('Сохранить запрос'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (accepted == true) {
    await controller.addRequest(
      superviseeId: superviseeId,
      question: questionController.text,
      context: contextController.text,
    );
  }
  questionController.dispose();
  contextController.dispose();
}

({String label, Color foreground, Color background}) _statusPresentation(
  SupervisionRequestStatus status,
) {
  return switch (status) {
    SupervisionRequestStatus.newRequest => (
        label: 'Новый',
        foreground: AppColors.safety,
        background: const Color(0xFFF6E8E6),
      ),
    SupervisionRequestStatus.planned => (
        label: 'В повестке',
        foreground: AppColors.navy,
        background: AppColors.paleBlue,
      ),
    SupervisionRequestStatus.completed => (
        label: 'Завершён',
        foreground: AppColors.teal,
        background: AppColors.paleTeal,
      ),
  };
}

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} · $hour:$minute';
}
