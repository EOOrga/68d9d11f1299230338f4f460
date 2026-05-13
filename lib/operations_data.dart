import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const appName = 'SCP BREUX F ET THEPAULT C';
const developerName = 'SCP BREUX F ET THEPAULT C';
const supportEmail = 'support@scpbreuxfthepaultc.app';
const applicationId = 'com.taziggg100.scpbreuxfthepaultc';

enum OperationType { workOrder, payroll, reservation, incident }

extension OperationTypeText on OperationType {
  String get storageKey => switch (this) {
    OperationType.workOrder => 'work_order',
    OperationType.payroll => 'payroll',
    OperationType.reservation => 'reservation',
    OperationType.incident => 'incident',
  };

  String get label => switch (this) {
    OperationType.workOrder => 'Work orders',
    OperationType.payroll => 'Payroll reports',
    OperationType.reservation => 'Reservations',
    OperationType.incident => 'Incidents',
  };

  String get singular => switch (this) {
    OperationType.workOrder => 'work order',
    OperationType.payroll => 'payroll report',
    OperationType.reservation => 'reservation',
    OperationType.incident => 'incident',
  };

  String get actionLabel => switch (this) {
    OperationType.workOrder => 'New work order',
    OperationType.payroll => 'New report',
    OperationType.reservation => 'New reservation',
    OperationType.incident => 'New incident',
  };
}

OperationType operationTypeFromStorage(String value) {
  return OperationType.values.firstWhere(
    (type) => type.storageKey == value,
    orElse: () => OperationType.workOrder,
  );
}

class OperationItem {
  const OperationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.status,
    required this.priority,
    required this.dueAt,
    required this.notes,
    required this.amount,
    required this.partySize,
    required this.createdAt,
  });

  final String id;
  final OperationType type;
  final String title;
  final String owner;
  final String status;
  final String priority;
  final DateTime dueAt;
  final String notes;
  final double amount;
  final int partySize;
  final DateTime createdAt;

  OperationItem copyWith({
    String? id,
    OperationType? type,
    String? title,
    String? owner,
    String? status,
    String? priority,
    DateTime? dueAt,
    String? notes,
    double? amount,
    int? partySize,
    DateTime? createdAt,
  }) {
    return OperationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      partySize: partySize ?? this.partySize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.storageKey,
      'title': title,
      'owner': owner,
      'status': status,
      'priority': priority,
      'dueAt': dueAt.toIso8601String(),
      'notes': notes,
      'amount': amount,
      'partySize': partySize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OperationItem.fromJson(Map<String, Object?> json) {
    return OperationItem(
      id: json['id'] as String? ?? createOperationId(),
      type: operationTypeFromStorage(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      status: json['status'] as String? ?? 'Queued',
      priority: json['priority'] as String? ?? 'Normal',
      dueAt:
          DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      partySize: (json['partySize'] as num?)?.round() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

abstract class OperationsRepository {
  Future<List<OperationItem>> load();

  Future<void> save(List<OperationItem> items);
}

class FileOperationsRepository implements OperationsRepository {
  static const _fileName = 'scp_breux_operations_records_v1.json';

  File get _recordsFile => File('${Directory.systemTemp.path}/$_fileName');

  @override
  Future<List<OperationItem>> load() async {
    final file = _recordsFile;
    if (!await file.exists()) {
      return <OperationItem>[];
    }
    final raw = await file.readAsString();
    if (raw.isEmpty) {
      return <OperationItem>[];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <OperationItem>[];
    }
    if (decoded is! List) {
      return <OperationItem>[];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => OperationItem.fromJson(entry.cast<String, Object?>()))
        .toList();
  }

  @override
  Future<void> save(List<OperationItem> items) async {
    final file = _recordsFile;
    await file.parent.create(recursive: true);
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await file.writeAsString(encoded, flush: true);
  }
}

class MemoryOperationsRepository implements OperationsRepository {
  MemoryOperationsRepository([List<OperationItem>? initialItems])
    : _items = List<OperationItem>.from(initialItems ?? const []);

  List<OperationItem> _items;

  @override
  Future<List<OperationItem>> load() async => List<OperationItem>.from(_items);

  @override
  Future<void> save(List<OperationItem> items) async {
    _items = List<OperationItem>.from(items);
  }
}

class OperationsController extends ChangeNotifier {
  OperationsController({
    required OperationsRepository repository,
    required bool screenshotMode,
  }) : _repository = repository,
       _screenshotMode = screenshotMode;

  final OperationsRepository _repository;
  final bool _screenshotMode;
  final List<OperationItem> _items = <OperationItem>[];
  bool _loaded = false;

  bool get loaded => _loaded;

  List<OperationItem> get items => List<OperationItem>.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _items
      ..clear()
      ..addAll(await _repository.load());
    _items.sort(_sortByDueDate);
    _loaded = true;
    notifyListeners();
  }

  List<OperationItem> byType(OperationType type) {
    return _items.where((item) => item.type == type).toList()
      ..sort(_sortByDueDate);
  }

  OperationItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  int countByType(OperationType type) {
    return _items.where((item) => item.type == type).length;
  }

  int countByStatus(String status) {
    return _items.where((item) => item.status == status).length;
  }

  int get openCount {
    return _items
        .where(
          (item) => !{
            'Closed',
            'Complete',
            'Approved',
            'Resolved',
          }.contains(item.status),
        )
        .length;
  }

  double get payrollTotal {
    return _items
        .where((item) => item.type == OperationType.payroll)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  Future<void> upsert(OperationItem item) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    _items.sort(_sortByDueDate);
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (_screenshotMode) {
      return;
    }
    await _repository.save(_items);
  }
}

int _sortByDueDate(OperationItem left, OperationItem right) {
  final dueCompare = left.dueAt.compareTo(right.dueAt);
  if (dueCompare != 0) {
    return dueCompare;
  }
  return left.createdAt.compareTo(right.createdAt);
}

String createOperationId() => DateTime.now().microsecondsSinceEpoch.toString();

List<String> statusesFor(OperationType type) {
  return switch (type) {
    OperationType.workOrder => const [
      'Queued',
      'In progress',
      'Blocked',
      'Complete',
    ],
    OperationType.payroll => const [
      'Draft',
      'Reviewed',
      'Submitted',
      'Approved',
    ],
    OperationType.reservation => const [
      'Requested',
      'Confirmed',
      'In service',
      'Closed',
    ],
    OperationType.incident => const ['Open', 'Investigating', 'Resolved'],
  };
}

List<String> get priorityLevels => const ['Low', 'Normal', 'High', 'Critical'];

String defaultTitleFor(OperationType type) {
  return switch (type) {
    OperationType.workOrder => 'Maintenance request',
    OperationType.payroll => 'Payroll control report',
    OperationType.reservation => 'Client reservation',
    OperationType.incident => 'Incident report',
  };
}

String formatCompactDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String formatFullDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

List<OperationItem> seedOperations() {
  final base = DateTime(2026, 5, 12, 9);
  return <OperationItem>[
    OperationItem(
      id: 'work-001',
      type: OperationType.workOrder,
      title: 'Kitchen equipment service',
      owner: 'Camille Roux',
      status: 'In progress',
      priority: 'High',
      dueAt: base.add(const Duration(hours: 4)),
      notes:
          'Technician assigned, parts staged, client update due before closing.',
      amount: 0,
      partySize: 0,
      createdAt: base.subtract(const Duration(days: 2)),
    ),
    OperationItem(
      id: 'work-002',
      type: OperationType.workOrder,
      title: 'Vehicle stock checklist',
      owner: 'Nadia Leclerc',
      status: 'Queued',
      priority: 'Normal',
      dueAt: base.add(const Duration(days: 1)),
      notes: 'Confirm tools and consumables before the morning route.',
      amount: 0,
      partySize: 0,
      createdAt: base.subtract(const Duration(days: 1)),
    ),
    OperationItem(
      id: 'pay-001',
      type: OperationType.payroll,
      title: 'April payroll exceptions',
      owner: 'Marc Thepault',
      status: 'Reviewed',
      priority: 'High',
      dueAt: base.add(const Duration(days: 2)),
      notes: 'Three overtime adjustments require final approval.',
      amount: 18420,
      partySize: 0,
      createdAt: base.subtract(const Duration(days: 5)),
    ),
    OperationItem(
      id: 'pay-002',
      type: OperationType.payroll,
      title: 'May hours summary',
      owner: 'Finance desk',
      status: 'Draft',
      priority: 'Normal',
      dueAt: base.add(const Duration(days: 7)),
      notes: 'Collect signed timesheets from field teams.',
      amount: 9700,
      partySize: 0,
      createdAt: base.subtract(const Duration(hours: 18)),
    ),
    OperationItem(
      id: 'res-001',
      type: OperationType.reservation,
      title: 'Saint-Malo conference room',
      owner: 'Breux client desk',
      status: 'Confirmed',
      priority: 'Normal',
      dueAt: base.add(const Duration(days: 3)),
      notes: 'Prepare projector, seating plan, and arrival contact.',
      amount: 0,
      partySize: 18,
      createdAt: base.subtract(const Duration(days: 3)),
    ),
    OperationItem(
      id: 'res-002',
      type: OperationType.reservation,
      title: 'Training space booking',
      owner: 'Operations desk',
      status: 'Requested',
      priority: 'Low',
      dueAt: base.add(const Duration(days: 8)),
      notes: 'Awaiting final headcount from the organizer.',
      amount: 0,
      partySize: 12,
      createdAt: base.subtract(const Duration(hours: 6)),
    ),
    OperationItem(
      id: 'inc-001',
      type: OperationType.incident,
      title: 'Loading bay access issue',
      owner: 'Security lead',
      status: 'Investigating',
      priority: 'Critical',
      dueAt: base.add(const Duration(hours: 2)),
      notes:
          'Entry badge fault logged. Temporary access controlled by supervisor.',
      amount: 0,
      partySize: 0,
      createdAt: base.subtract(const Duration(hours: 3)),
    ),
    OperationItem(
      id: 'inc-002',
      type: OperationType.incident,
      title: 'Late supplier arrival',
      owner: 'Front office',
      status: 'Open',
      priority: 'High',
      dueAt: base.add(const Duration(days: 1, hours: 3)),
      notes: 'Track impact on reservations and notify affected teams.',
      amount: 0,
      partySize: 0,
      createdAt: base.subtract(const Duration(hours: 9)),
    ),
  ];
}
