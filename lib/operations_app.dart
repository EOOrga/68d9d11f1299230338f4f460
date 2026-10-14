import 'package:flutter/material.dart';

import 'operations_data.dart';

const _navy = Color(0xFFFF1F88);
const _deepBlue = Color(0xFFFF961F);
const _gold = Color(0xFFFF261F);
const _silver = Color(0xFFD8DDE2);
const _paper = Color(0xFFFFFBF2);
const _success = Color(0xFF19745F);
const _danger = Color(0xFFB84A43);

class SCPBreuxOpsApp extends StatefulWidget {
  const SCPBreuxOpsApp({
    required this.repository,
    required this.screenshotMode,
    super.key,
  });

  final OperationsRepository repository;
  final bool screenshotMode;

  @override
  State<SCPBreuxOpsApp> createState() => _SCPBreuxOpsAppState();
}

class _SCPBreuxOpsAppState extends State<SCPBreuxOpsApp> {
  late final OperationsController _controller;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _controller = OperationsController(
      repository: widget.repository,
      screenshotMode: widget.screenshotMode,
    );
    _loadFuture = _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingScreen();
          }
          return OperationsHome(controller: _controller);
        },
      ),
    );
  }
}

ThemeData _buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: _navy,
    brightness: Brightness.light,
  );
  final scheme = base.copyWith(
    primary: _navy,
    onPrimary: Colors.white,
    secondary: _gold,
    onSecondary: _navy,
    tertiary: _deepBlue,
    surface: _paper,
    onSurface: const Color(0xFF17202A),
    error: _danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _paper,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: _paper,
      foregroundColor: _navy,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: _navy,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _navy.withValues(alpha: 0.08)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _gold, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: _gold.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({required this.controller, super.key});

  final OperationsController controller;

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  int _selectedIndex = 0;

  OperationType? get _activeType => switch (_selectedIndex) {
    1 => OperationType.workOrder,
    2 => OperationType.payroll,
    3 => OperationType.reservation,
    4 => OperationType.incident,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final activeType = _activeType;

    return Scaffold(
      appBar: AppBar(
        title: Text(activeType?.label ?? 'Operations hub'),
        actions: [
          IconButton(
            key: const ValueKey('settingsAction'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => switch (_selectedIndex) {
            0 => DashboardPage(
              controller: widget.controller,
              onOpenType: _selectType,
            ),
            1 => OperationListPage(
              controller: widget.controller,
              type: OperationType.workOrder,
            ),
            2 => OperationListPage(
              controller: widget.controller,
              type: OperationType.payroll,
            ),
            3 => OperationListPage(
              controller: widget.controller,
              type: OperationType.reservation,
            ),
            _ => OperationListPage(
              controller: widget.controller,
              type: OperationType.incident,
            ),
          },
        ),
      ),
      floatingActionButton: activeType == null
          ? null
          : FloatingActionButton.extended(
              key: ValueKey('new-${activeType.storageKey}'),
              onPressed: () => _openForm(context, activeType),
              icon: const Icon(Icons.add),
              label: Text(activeType.actionLabel),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payroll',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Incidents',
          ),
        ],
      ),
    );
  }

  void _selectType(OperationType type) {
    setState(() {
      _selectedIndex = switch (type) {
        OperationType.workOrder => 1,
        OperationType.payroll => 2,
        OperationType.reservation => 3,
        OperationType.incident => 4,
      };
    });
  }

  Future<void> _openForm(BuildContext context, OperationType type) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OperationFormPage(controller: widget.controller, type: type),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(controller: widget.controller),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.controller,
    required this.onOpenType,
    super.key,
  });

  final OperationsController controller;
  final ValueChanged<OperationType> onOpenType;

  @override
  Widget build(BuildContext context) {
    final focusItems = controller.items.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 16),
        _MetricsGrid(controller: controller),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'SCP BREUX F ET THEPAULT C',
          action: TextButton(
            onPressed: () => onOpenType(OperationType.workOrder),
            child: const Text('Open work'),
          ),
        ),
        if (focusItems.isEmpty)
          const _EmptyState(
            icon: Icons.playlist_add_check,
            title: 'No operations yet',
            message: 'Add the first local record to start tracking daily work.',
          )
        else
          ...focusItems.map(
            (item) => OperationCard(
              item: item,
              onTap: () => _openDetail(context, controller, item),
            ),
          ),
        const SizedBox(height: 18),
        _SectionHeader(title: 'Workstreams'),
        _ActionGrid(controller: controller, onOpenType: onOpenType),
      ],
    );
  }

  void _openDetail(
    BuildContext context,
    OperationsController controller,
    OperationItem item,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OperationDetailPage(controller: controller, itemId: item.id),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'docs/icon.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Work orders, payroll, reservations, and incidents in one local workspace.',
                  style: TextStyle(color: _silver, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.controller});

  final OperationsController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Open records',
        value: controller.openCount.toString(),
        icon: Icons.pending_actions,
      ),
      _MetricData(
        label: 'Payroll value',
        value: 'EUR ${controller.payrollTotal.toStringAsFixed(0)}',
        icon: Icons.payments,
      ),
      _MetricData(
        label: 'Bookings',
        value: controller.countByType(OperationType.reservation).toString(),
        icon: Icons.event_available,
      ),
      _MetricData(
        label: 'Incidents',
        value: controller.countByType(OperationType.incident).toString(),
        icon: Icons.report_problem,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _MetricCard(data: metrics[index]),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: _gold, size: 24),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.controller, required this.onOpenType});

  final OperationsController controller;
  final ValueChanged<OperationType> onOpenType;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.08,
      children: OperationType.values.map((type) {
        return _ActionCard(
          type: type,
          count: controller.countByType(type),
          onTap: () => onOpenType(type),
        );
      }).toList(),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final OperationType type;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(type), color: _navy, size: 28),
              const Spacer(),
              Text(
                type.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count local records',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationListPage extends StatelessWidget {
  const OperationListPage({
    required this.controller,
    required this.type,
    super.key,
  });

  final OperationsController controller;
  final OperationType type;

  @override
  Widget build(BuildContext context) {
    final items = controller.byType(type);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _TypeSummary(type: type, items: items),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyState(
            icon: _iconFor(type),
            title: 'No ${type.label.toLowerCase()} yet',
            message: 'Use the create button to save a local ${type.singular}.',
          )
        else
          ...items.map(
            (item) => OperationCard(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OperationDetailPage(
                    controller: controller,
                    itemId: item.id,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeSummary extends StatelessWidget {
  const _TypeSummary({required this.type, required this.items});

  final OperationType type;
  final List<OperationItem> items;

  @override
  Widget build(BuildContext context) {
    final urgent = items
        .where((item) => {'High', 'Critical'}.contains(item.priority))
        .length;
    final status = items.isEmpty ? 'Ready' : '${items.length} active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _navy.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconFor(type), color: _navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$status · $urgent high priority',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OperationCard extends StatelessWidget {
  const OperationCard({required this.item, required this.onTap, super.key});

  final OperationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(label: item.status),
                  const SizedBox(width: 8),
                  _PriorityChip(label: item.priority),
                  const Spacer(),
                  Text(
                    formatCompactDate(item.dueAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InlineMeta(icon: Icons.person_outline, label: item.owner),
                  if (item.type == OperationType.payroll)
                    _InlineMeta(
                      icon: Icons.payments_outlined,
                      label: 'EUR ${item.amount.toStringAsFixed(0)}',
                    ),
                  if (item.type == OperationType.reservation)
                    _InlineMeta(
                      icon: Icons.groups_outlined,
                      label: '${item.partySize} guests',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationDetailPage extends StatelessWidget {
  const OperationDetailPage({
    required this.controller,
    required this.itemId,
    super.key,
  });

  final OperationsController controller;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = controller.findById(itemId);
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record removed')),
            body: const Center(
              child: Text('This local record no longer exists.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(item.type.singular),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OperationFormPage(
                      controller: controller,
                      type: item.type,
                      existing: item,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _DetailHeader(item: item),
              const SizedBox(height: 14),
              _DetailSection(
                title: 'Operational notes',
                child: Text(item.notes, style: const TextStyle(height: 1.45)),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                title: 'Schedule and ownership',
                child: Column(
                  children: [
                    _DetailRow(label: 'Owner', value: item.owner),
                    _DetailRow(label: 'Due', value: formatFullDate(item.dueAt)),
                    _DetailRow(label: 'Status', value: item.status),
                    _DetailRow(label: 'Priority', value: item.priority),
                    if (item.type == OperationType.payroll)
                      _DetailRow(
                        label: 'Payroll value',
                        value: 'EUR ${item.amount.toStringAsFixed(0)}',
                      ),
                    if (item.type == OperationType.reservation)
                      _DetailRow(
                        label: 'Party size',
                        value: '${item.partySize} guests',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.delete(item.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete local record'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.item});

  final OperationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(item.type), color: _gold, size: 34),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: item.status, dark: true),
              _PriorityChip(label: item.priority, dark: true),
              _Pill(
                label: formatCompactDate(item.dueAt),
                color: Colors.white,
                background: Colors.white.withValues(alpha: 0.12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationFormPage extends StatefulWidget {
  const OperationFormPage({
    required this.controller,
    required this.type,
    this.existing,
    super.key,
  });

  final OperationsController controller;
  final OperationType type;
  final OperationItem? existing;

  @override
  State<OperationFormPage> createState() => _OperationFormPageState();
}

class _OperationFormPageState extends State<OperationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _notesController;
  late final TextEditingController _amountController;
  late final TextEditingController _partyController;
  late String _status;
  late String _priority;
  late DateTime _dueAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _ownerController = TextEditingController(text: existing?.owner ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _amountController = TextEditingController(
      text: existing == null || existing.amount == 0
          ? ''
          : existing.amount.toStringAsFixed(0),
    );
    _partyController = TextEditingController(
      text: existing == null || existing.partySize == 0
          ? ''
          : existing.partySize.toString(),
    );
    _status = existing?.status ?? statusesFor(widget.type).first;
    _priority = existing?.priority ?? 'Normal';
    _dueAt = existing?.dueAt ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _partyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit ${widget.type.singular}' : widget.type.actionLabel,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _FormIntro(type: widget.type),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('titleField'),
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _titleLabel(widget.type),
                prefixIcon: Icon(_iconFor(widget.type)),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('ownerField'),
              controller: _ownerController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Owner or desk',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            if (widget.type == OperationType.payroll) ...[
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Report value in EUR',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.type == OperationType.reservation) ...[
              TextFormField(
                controller: _partyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Party size',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: statusesFor(widget.type)
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.priority_high_outlined),
              ),
              items: priorityLevels
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _priority = value ?? _priority),
            ),
            const SizedBox(height: 14),
            Text(
              'Due date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DueChoice(
                  label: 'Today',
                  selected: _isSameDay(_dueAt, DateTime.now()),
                  onSelected: () => _setDueOffset(0),
                ),
                _DueChoice(
                  label: 'Tomorrow',
                  selected: _isSameDay(
                    _dueAt,
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  onSelected: () => _setDueOffset(1),
                ),
                _DueChoice(
                  label: 'This week',
                  selected: _dueAt.difference(DateTime.now()).inDays == 4,
                  onSelected: () => _setDueOffset(4),
                ),
                _DueChoice(
                  label: 'Next week',
                  selected: _dueAt.difference(DateTime.now()).inDays == 7,
                  onSelected: () => _setDueOffset(7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('notesField'),
              controller: _notesController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Operational notes',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('saveRecordButton'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save record'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _setDueOffset(int days) {
    final now = DateTime.now();
    setState(() {
      _dueAt = DateTime(now.year, now.month, now.day).add(Duration(days: days));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final existing = widget.existing;
    final item = OperationItem(
      id: existing?.id ?? createOperationId(),
      type: widget.type,
      title: _titleController.text.trim(),
      owner: _ownerController.text.trim(),
      status: _status,
      priority: _priority,
      dueAt: _dueAt,
      notes: _notesController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      partySize: int.tryParse(_partyController.text.trim()) ?? 0,
      createdAt: existing?.createdAt ?? now,
    );
    await widget.controller.upsert(item);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.type});

  final OperationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _deepBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_iconFor(type), color: _gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Save this ${type.singular} on the device for daily follow-up.',
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DueChoice extends StatelessWidget {
  const _DueChoice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: _gold.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final OperationsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings and privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SettingsCard(
            icon: Icons.business_outlined,
            title: appName,
            body:
                'This workspace keeps work orders, payroll reports, reservations, and incidents organized for daily business tasks.',
          ),
          const _SettingsCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Local privacy',
            body:
                'No account is required. Records stay in local app storage, and the app declares no Android permissions.',
          ),
          const _SettingsCard(
            icon: Icons.cloud_off_outlined,
            title: 'No cloud sync',
            body:
                'The app does not upload records, collect analytics, or use advertising identifiers.',
          ),
          _SettingsCard(
            icon: Icons.mail_outline,
            title: 'Support',
            body: '$developerName\n$supportEmail',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear local records'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local records?'),
        content: const Text('This removes saved operations from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) {
      await controller.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Local records cleared')));
      }
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 44, color: _gold),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      color: dark ? Colors.white : _navy,
      background: dark
          ? Colors.white.withValues(alpha: 0.12)
          : _gold.withValues(alpha: 0.2),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(label);
    return _Pill(
      label: label,
      color: dark ? Colors.white : color,
      background: dark
          ? color.withValues(alpha: 0.5)
          : color.withValues(alpha: 0.12),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _deepBlue),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(OperationType type) {
  return switch (type) {
    OperationType.workOrder => Icons.build_circle_outlined,
    OperationType.payroll => Icons.payments_outlined,
    OperationType.reservation => Icons.event_available_outlined,
    OperationType.incident => Icons.report_problem_outlined,
  };
}

Color _priorityColor(String priority) {
  return switch (priority) {
    'Critical' => _danger,
    'High' => const Color(0xFF996515),
    'Low' => _success,
    _ => _deepBlue,
  };
}

String _titleLabel(OperationType type) {
  return switch (type) {
    OperationType.workOrder => 'Work order title',
    OperationType.payroll => 'Payroll report title',
    OperationType.reservation => 'Reservation title',
    OperationType.incident => 'Incident title',
  };
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
