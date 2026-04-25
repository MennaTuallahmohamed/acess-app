import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/api/technician_repository.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NCategory { task, system, alert, update }

class NItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final NCategory cat;
  final DateTime time;
  bool read;
  final String? code;
  final String? actionAr;
  final String? actionEn;
  final int? taskId;
  final String? status;

  NItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.cat,
    required this.time,
    this.read = false,
    this.code,
    this.actionAr,
    this.actionEn,
    this.taskId,
    this.status,
  });

  String title(bool ar) => ar ? titleAr : titleEn;
  String body(bool ar) => ar ? bodyAr : bodyEn;
  String? action(bool ar) => ar ? actionAr : actionEn;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all';
  late Future<List<NItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTasks();
  }

  Future<List<NItem>> _loadTasks() async {
    final repo = ref.read(technicianRepositoryProvider);
    final tasks = await repo.getMyTasks();
    return tasks.map(_mapTaskToNotification).toList();
  }

  NItem _mapTaskToNotification(TaskNotificationModel task) {
    final location = [
      task.cluster,
      task.building,
      task.zone,
      task.lane,
      task.direction,
    ].where((e) => e.trim().isNotEmpty).join(' - ');

    final bodyAr = location.isEmpty
        ? 'تم تعيين الجهاز ${task.deviceName} لك للتفتيش'
        : 'تم تعيين الجهاز ${task.deviceName} لك للتفتيش — $location';

    final bodyEn = location.isEmpty
        ? 'Device ${task.deviceName} assigned to you for inspection'
        : 'Device ${task.deviceName} assigned to you for inspection — $location';

    final isPending = task.status.toUpperCase() == 'PENDING';
    final isInProgress = task.status.toUpperCase() == 'IN_PROGRESS';

    return NItem(
      id: task.id,
      taskId: int.tryParse(task.id),
      titleAr: isInProgress ? 'مهمة قيد التنفيذ' : 'مهمة تفتيش جديدة',
      titleEn: isInProgress ? 'Inspection Task In Progress' : 'New Inspection Task Assigned',
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      cat: NCategory.task,
      time: task.scheduledDate ?? DateTime.now(),
      code: task.deviceCode.isNotEmpty ? task.deviceCode : task.deviceName,
      actionAr: isPending ? 'ابدأ التفتيش' : 'متابعة',
      actionEn: isPending ? 'Start Inspection' : 'Continue',
      read: false,
      status: task.status,
    );
  }

  Future<void> _refresh() async {
    final next = _loadTasks();
    setState(() {
      _future = next;
    });
    await next;
  }

  List<NItem> _applyFilter(List<NItem> items) {
    if (_filter == 'all') return items;
    final map = {
      'task': NCategory.task,
      'system': NCategory.system,
      'alert': NCategory.alert,
    };
    return items.where((n) => n.cat == map[_filter]).toList();
  }

  Map<String, List<NItem>> _grouped(List<NItem> items, AppLocalizations l) {
    final now = DateTime.now();
    final m = <String, List<NItem>>{};
    for (final n in items) {
      final diff = now.difference(n.time).inDays;
      String key;
      if (diff == 0) {
        key = l.todayLbl;
      } else if (diff == 1) {
        key = l.yesterdayLbl;
      } else {
        key = l.isAr ? 'منذ $diff أيام' : '$diff days ago';
      }
      m.putIfAbsent(key, () => []).add(n);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: FutureBuilder<List<NItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.error,
                      style: AppText.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: Text(l.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = _applyFilter(snapshot.data ?? []);
          final unread = items.where((n) => !n.read).length;
          final grouped = _grouped(items, l);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    children: [
                      Text(
                        l.notifications,
                        style: AppText.h4.copyWith(color: Colors.white),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: _FilterRow(
                        current: _filter,
                        onSelect: (f) => setState(() => _filter = f),
                        l: l,
                      ),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.noNotifs,
                            style: AppText.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...grouped.entries.map(
                  (group) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                margin: const EdgeInsets.only(left: 8, right: 8),
                                color: AppColors.accent,
                              ),
                              Text(
                                group.key,
                                style: AppText.smallBold.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...group.value.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _NCard(
                                item: e.value,
                                l: l,
                                onTap: () {},
                                onDelete: () {},
                              )
                                  .animate(delay: Duration(milliseconds: e.key * 50))
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: l.isAr ? 0.04 : -0.04),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String current;
  final Function(String) onSelect;
  final AppLocalizations l;

  const _FilterRow({
    required this.current,
    required this.onSelect,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', l.filterAll, null),
      ('task', l.notifTask, Icons.assignment_rounded),
      ('alert', l.notifAlert, Icons.warning_amber_rounded),
      ('system', l.notifSystem, Icons.settings_rounded),
    ];

    return Row(
      children: items.map((f) {
        final sel = current == f.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.accent : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f.$3 != null)
                    Icon(
                      f.$3!,
                      size: 14,
                      color: sel ? AppColors.primary : Colors.white60,
                    ),
                  if (f.$3 != null) const SizedBox(height: 2),
                  Text(
                    f.$2,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? AppColors.primary : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NCard extends StatelessWidget {
  final NItem item;
  final AppLocalizations l;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NCard({
    required this.item,
    required this.l,
    required this.onTap,
    required this.onDelete,
  });

  Color get _cc {
    switch (item.cat) {
      case NCategory.task:
        return AppColors.info;
      case NCategory.system:
        return AppColors.success;
      case NCategory.alert:
        return AppColors.error;
      case NCategory.update:
        return AppColors.accent;
    }
  }

  IconData get _ci {
    switch (item.cat) {
      case NCategory.task:
        return Icons.assignment_rounded;
      case NCategory.system:
        return Icons.settings_rounded;
      case NCategory.alert:
        return Icons.warning_amber_rounded;
      case NCategory.update:
        return Icons.system_update_rounded;
    }
  }

  String get _statusTextAr {
    switch ((item.status ?? '').toUpperCase()) {
      case 'PENDING':
        return 'معلقة';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'مكتملة';
      case 'CANCELLED':
        return 'ملغية';
      default:
        return item.status ?? '';
    }
  }

  Object get _tLabel {
    final diff = DateTime.now().difference(item.time);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minAgo;
    if (diff.inHours < 24) return l.hourAgo;
    return l.isAr ? 'منذ ${diff.inDays} أيام' : '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: item.read ? AppColors.surfaceCard : _cc.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.read ? AppColors.border : _cc.withOpacity(0.25),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (!item.read)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _cc,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(item.read ? 14 : 10, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _cc.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(_ci, color: _cc, size: 19),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title(l.isAr),
                                        style: AppText.bodyMed.copyWith(
                                          fontWeight: item.read
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('$_tLabel', style: AppText.caption),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item.body(l.isAr),
                                  style: AppText.small.copyWith(
                                    height: 1.55,
                                    color: item.read
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (item.code != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceGrey,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                item.code!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          const Spacer(),
                          if ((item.status ?? '').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _cc.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l.isAr ? _statusTextAr : (item.status ?? ''),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _cc,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}