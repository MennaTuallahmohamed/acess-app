import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTechniciansScreen extends ConsumerStatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  ConsumerState<AdminTechniciansScreen> createState() =>
      _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState
    extends ConsumerState<AdminTechniciansScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(activeTechniciansProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(monthlyInspectionsProvider);
    ref.invalidate(adminStatsProvider);
    ref.invalidate(adminAnalyticsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final techniciansAsync = ref.watch(activeTechniciansProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final inspectionsAsync = ref.watch(monthlyInspectionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isAr: isAr,
              onBack: () => Navigator.maybePop(context),
              onRefresh: _refreshAll,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'بحث باسم الفني أو الإيميل...'
                      : 'Search technician name or email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: techniciansAsync.when(
                loading: () => const _LoadingList(),
                error: (e, _) =>
                    _ErrorState(message: e.toString(), onRetry: _refreshAll),
                data: (technicians) {
                  final q = _search.trim().toLowerCase();
                  final list = technicians.where((t) {
                    if (!(t.isActive || t.status.toUpperCase() == 'ACTIVE'))
                      return false;
                    if (q.isEmpty) return true;
                    return [
                      t.fullName,
                      t.username,
                      t.email,
                      t.phone ?? '',
                      t.jobTitle ?? '',
                      t.region ?? ''
                    ].join(' ').toLowerCase().contains(q);
                  }).toList()
                    ..sort((a, b) => (b.lastActivity ?? DateTime(2000))
                        .compareTo(a.lastActivity ?? DateTime(2000)));

                  if (list.isEmpty) {
                    return _EmptyState(isAr: isAr);
                  }

                  final tasks = tasksAsync.valueOrNull ?? [];
                  final inspections = inspectionsAsync.valueOrNull ?? [];

                  return RefreshIndicator(
                    onRefresh: () async => _refreshAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final tech = list[i];
                        final techTasks = tasks
                            .where((t) => t.assignedToId == tech.id)
                            .toList();
                        final techInspections = inspections
                            .where((x) =>
                                x.technicianName.trim().toLowerCase() ==
                                tech.fullName.trim().toLowerCase())
                            .toList();
                        return _TechnicianCard(
                          technician: tech,
                          tasks: techTasks,
                          inspections: techInspections,
                          index: i,
                          isAr: isAr,
                          onTap: () => _openDetails(context, tech),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, TechnicianModel tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TechnicianDetailsSheet(technician: tech),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAr;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header(
      {required this.isAr, required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _IconButtonLite(
              icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.engineering_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'الفنيين النشطين فقط' : 'Active Technicians Only',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 19),
                ),
                Text(
                  isAr
                      ? 'كل فني مع مهامه وفحوصاته وصوره'
                      : 'Each technician with tasks, inspections and photos',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontFamily: 'Cairo',
                      fontSize: 11),
                ),
              ],
            ),
          ),
          _IconButtonLite(icon: Icons.refresh_rounded, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;
  final List<TaskModel> tasks;
  final List<InspectionDetail> inspections;
  final int index;
  final bool isAr;
  final VoidCallback onTap;

  const _TechnicianCard({
    required this.technician,
    required this.tasks,
    required this.inspections,
    required this.index,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed =
        tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    final running =
        tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final pending = tasks
        .where((t) =>
            t.status.toUpperCase() == 'PENDING' ||
            t.status.toUpperCase() == 'OVERDUE')
        .length;
    final rate = tasks.isEmpty
        ? technician.completionRate
        : (completed / tasks.length * 100);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _Avatar(name: technician.fullName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                technician.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A)),
                              ),
                            ),
                            _Pill(
                                text: isAr ? 'نشط' : 'Active',
                                color: const Color(0xFF16A34A)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          technician.email.isEmpty
                              ? technician.username
                              : technician.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (technician.phone != null)
                              _SmallTag(
                                  icon: Icons.phone_rounded,
                                  text: technician.phone!),
                            if (technician.jobTitle != null)
                              _SmallTag(
                                  icon: Icons.badge_rounded,
                                  text: technician.jobTitle!),
                            if (technician.region != null)
                              _SmallTag(
                                  icon: Icons.place_rounded,
                                  text: technician.region!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _Metric(
                          label: isAr ? 'كل المهام' : 'Tasks',
                          value: tasks.length,
                          color: const Color(0xFF1A237E))),
                  Expanded(
                      child: _Metric(
                          label: isAr ? 'تمت' : 'Done',
                          value: completed,
                          color: const Color(0xFF16A34A))),
                  Expanded(
                      child: _Metric(
                          label: isAr ? 'جارية' : 'Running',
                          value: running,
                          color: const Color(0xFF0284C7))),
                  Expanded(
                      child: _Metric(
                          label: isAr ? 'معلقة' : 'Pending',
                          value: pending,
                          color: const Color(0xFFF59E0B))),
                  Expanded(
                      child: _Metric(
                          label: isAr ? 'فحوصات' : 'Checks',
                          value: inspections.length,
                          color: const Color(0xFF7C3AED))),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (rate.clamp(0, 100)) / 100,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                      '${rate.toStringAsFixed(0)}% ${isAr ? 'إنجاز' : 'completion'}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_timeAgo(technician.lastActivity, isAr),
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1)),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: (index * 30).clamp(0, 280)))
        .fadeIn(duration: 230.ms)
        .slideY(begin: 0.04);
  }
}

class _TechnicianDetailsSheet extends ConsumerWidget {
  final TechnicianModel technician;
  const _TechnicianDetailsSheet({required this.technician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;
    final tasksAsync = ref.watch(tasksByTechnicianProvider(technician.id));
    final activityAsync = ref.watch(techActivityProvider(technician.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.96,
      minChildSize: 0.48,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _Avatar(name: technician.fullName, size: 58),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(technician.fullName,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A))),
                        Text(
                            technician.email.isEmpty
                                ? technician.username
                                : technician.email,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  _Pill(
                      text: isAr ? 'فني فقط' : 'Technician',
                      color: const Color(0xFF16A34A)),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                children: [
                  _InfoPanel(technician: technician, isAr: isAr),
                  const SizedBox(height: 14),
                  _SectionTitle(
                      title: isAr ? 'كل مهام الفني' : 'All Technician Tasks',
                      icon: Icons.task_alt_rounded),
                  const SizedBox(height: 8),
                  tasksAsync.when(
                    loading: () => const _InlineLoading(),
                    error: (e, _) => _InlineError(message: e.toString()),
                    data: (tasks) {
                      final sorted = [...tasks]..sort((a, b) =>
                          (b.completedAt ?? b.createdAt)
                              .compareTo(a.completedAt ?? a.createdAt));
                      if (sorted.isEmpty)
                        return _InlineEmpty(
                            text: isAr
                                ? 'لا توجد مهام لهذا الفني'
                                : 'No tasks for this technician');
                      return Column(
                          children: sorted
                              .map((t) => _TaskMiniTile(task: t, isAr: isAr))
                              .toList());
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionTitle(
                      title: isAr ? 'الفحوصات والصور' : 'Inspections & Photos',
                      icon: Icons.fact_check_rounded),
                  const SizedBox(height: 8),
                  activityAsync.when(
                    loading: () => const _InlineLoading(),
                    error: (e, _) => _InlineError(message: e.toString()),
                    data: (items) {
                      final sorted = [
                        ...items
                      ]..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));
                      if (sorted.isEmpty)
                        return _InlineEmpty(
                            text: isAr
                                ? 'لا توجد فحوصات لهذا الفني'
                                : 'No inspections for this technician');
                      return Column(
                          children: sorted
                              .map((x) =>
                                  _InspectionMiniTile(item: x, isAr: isAr))
                              .toList());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final TechnicianModel technician;
  final bool isAr;
  const _InfoPanel({required this.technician, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow(
          label: isAr ? 'اسم المستخدم' : 'Username',
          value: technician.username),
      _InfoRow(
          label: isAr ? 'الهاتف' : 'Phone', value: technician.phone ?? '-'),
      _InfoRow(
          label: isAr ? 'الوظيفة' : 'Job title',
          value: technician.jobTitle ?? '-'),
      _InfoRow(
          label: isAr ? 'المنطقة' : 'Region', value: technician.region ?? '-'),
      _InfoRow(
          label: isAr ? 'المكتب' : 'Office',
          value: technician.officeNumber ?? '-'),
      _InfoRow(
          label: isAr ? 'ملاحظات' : 'Notes', value: technician.notes ?? '-'),
    ];
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: rows),
    );
  }
}

class _TaskMiniTile extends StatelessWidget {
  final TaskModel task;
  final bool isAr;
  const _TaskMiniTile({required this.task, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(task);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16))),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(999))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(task.deviceName ?? (isAr ? 'بدون جهاز' : 'No device'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Color(0xFF64748B))),
              ],
            ),
          ),
          _Pill(text: isAr ? task.statusAr : task.statusEn, color: color),
        ],
      ),
    );
  }
}

class _InspectionMiniTile extends StatelessWidget {
  final InspectionDetail item;
  final bool isAr;
  const _InspectionMiniTile({required this.item, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = _inspectionColor(item.inspectionStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(item.deviceName,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A)))),
              _Pill(text: item.statusAr, color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text('${item.deviceCode} — ${item.locationText}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B))),
          if ((item.notes ?? '').isNotEmpty ||
              (item.issueReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.issueReason ?? item.notes ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF334155))),
          ],
          if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl!,
                height: 145,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: Color(0xFF94A3B8))),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(_dateTime(item.inspectedAt),
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15))
      ]);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))))
        ]),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Metric(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700))
        ]),
      );
}

class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallTag({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700))
        ]),
      );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontFamily: 'Cairo',
              fontSize: 10.5,
              fontWeight: FontWeight.w900)));
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, this.size = 50});
  @override
  Widget build(BuildContext context) {
    final clean = name.trim();
    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : (clean.isEmpty ? '?' : clean[0]);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF1A237E)])),
      alignment: Alignment.center,
      child: Text(initials.toUpperCase(),
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: size * 0.34)),
    );
  }
}

class _IconButtonLite extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButtonLite({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12))),
          child: Icon(icon, color: Colors.white, size: 20)));
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
              height: 145,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 900.ms));
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.all(18),
      child: Center(child: CircularProgressIndicator()));
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: const TextStyle(color: Color(0xFFDC2626))));
}

class _InlineEmpty extends StatelessWidget {
  final String text;
  const _InlineEmpty({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700)));
}

class _EmptyState extends StatelessWidget {
  final bool isAr;
  const _EmptyState({required this.isAr});
  @override
  Widget build(BuildContext context) => Center(
      child: Text(isAr ? 'لا يوجد فنيين نشطين' : 'No active technicians',
          style: const TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w900)));
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 44),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry'))
          ])));
}

Color _taskColor(TaskModel task) {
  final s = task.status.toUpperCase();
  if (task.isUrgent ||
      task.isEmergency ||
      task.priority.toUpperCase() == 'URGENT') return const Color(0xFFDC2626);
  if (s == 'COMPLETED') return const Color(0xFF16A34A);
  if (s == 'IN_PROGRESS') return const Color(0xFF0284C7);
  if (s == 'OVERDUE') return const Color(0xFFEA580C);
  return const Color(0xFF1A237E);
}

Color _inspectionColor(String status) {
  switch (status.toUpperCase()) {
    case 'OK':
      return const Color(0xFF16A34A);
    case 'NOT_OK':
      return const Color(0xFFDC2626);
    case 'PARTIAL':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF64748B);
  }
}

String _dateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _timeAgo(DateTime? d, bool isAr) {
  if (d == null) return isAr ? 'لا يوجد نشاط' : 'No activity';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Now';
  if (diff.inMinutes < 60)
    return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
  if (diff.inHours < 24)
    return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
  return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
}
