import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTechniciansScreen extends ConsumerStatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  ConsumerState<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends ConsumerState<AdminTechniciansScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(activeTechniciansProvider);
    ref.invalidate(techniciansProvider);
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(isAr ? 'إضافة فني' : 'Add Technician'),
        onPressed: () => _openCreateTechnicianSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isAr: isAr,
              onBack: () => Navigator.maybePop(context),
              onRefresh: _refreshAll,
              onAdd: () => _openCreateTechnicianSheet(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: isAr ? 'بحث باسم الفني أو الإيميل أو الهاتف...' : 'Search name, email or phone...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: techniciansAsync.when(
                loading: () => const _LoadingList(),
                error: (e, _) => _ErrorState(message: e.toString(), onRetry: _refreshAll),
                data: (technicians) {
                  final q = _search.trim().toLowerCase();
                  final active = technicians.where((t) {
                    final active = t.isActive || t.status.toUpperCase() == 'ACTIVE';
                    if (!active) return false;
                    if (q.isEmpty) return true;
                    return [
                      t.fullName,
                      t.username,
                      t.email,
                      t.phone ?? '',
                      t.jobTitle ?? '',
                      t.region ?? '',
                      t.officeNumber ?? '',
                    ].join(' ').toLowerCase().contains(q);
                  }).toList()
                    ..sort((a, b) => (b.lastActivity ?? DateTime(2000)).compareTo(a.lastActivity ?? DateTime(2000)));

                  if (active.isEmpty) return _EmptyState(isAr: isAr);

                  final tasks = tasksAsync.valueOrNull ?? const <TaskModel>[];
                  final inspections = inspectionsAsync.valueOrNull ?? const <InspectionDetail>[];

                  return RefreshIndicator(
                    onRefresh: () async => _refreshAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                      itemCount: active.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final tech = active[i];
                        final techTasks = _tasksForTech(tasks, tech);
                        final techInspections = _inspectionsForTech(inspections, tech);

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

  void _openCreateTechnicianSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTechnicianSheet(
        onCreated: () {
          _refreshAll();
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAr;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _Header({
    required this.isAr,
    required this.onBack,
    required this.onRefresh,
    required this.onAdd,
  });

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
          _IconButtonLite(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.engineering_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'الفنيين النشطين فقط' : 'Active Technicians Only',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 19),
                ),
                Text(
                  isAr ? 'كل فني مع مهامه وفحوصاته وصوره' : 'Each technician with tasks, inspections and photos',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontFamily: 'Cairo', fontSize: 11),
                ),
              ],
            ),
          ),
          _IconButtonLite(icon: Icons.person_add_alt_1_rounded, onTap: onAdd),
          const SizedBox(width: 6),
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
    final completed = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    final running = tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final pending = tasks.where((t) {
      final s = t.status.toUpperCase();
      return s == 'PENDING' || s == 'OVERDUE';
    }).length;
    final rate = tasks.isEmpty ? technician.completionRate : (completed / tasks.length * 100);

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
            boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
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
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                            ),
                            _Pill(text: isAr ? 'نشط' : 'Active', color: const Color(0xFF16A34A)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          technician.email.trim().isEmpty ? technician.username : technician.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (technician.phone != null) _SmallTag(icon: Icons.phone_rounded, text: technician.phone!),
                            if (technician.jobTitle != null) _SmallTag(icon: Icons.badge_rounded, text: technician.jobTitle!),
                            if (technician.region != null) _SmallTag(icon: Icons.place_rounded, text: technician.region!),
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
                  Expanded(child: _Metric(label: isAr ? 'كل المهام' : 'Tasks', value: tasks.length, color: const Color(0xFF1A237E))),
                  Expanded(child: _Metric(label: isAr ? 'تمت' : 'Done', value: completed, color: const Color(0xFF16A34A))),
                  Expanded(child: _Metric(label: isAr ? 'جارية' : 'Running', value: running, color: const Color(0xFF0284C7))),
                  Expanded(child: _Metric(label: isAr ? 'معلقة' : 'Pending', value: pending, color: const Color(0xFFF59E0B))),
                  Expanded(child: _Metric(label: isAr ? 'فحوصات' : 'Checks', value: inspections.length, color: const Color(0xFF7C3AED))),
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
                  Text('${rate.toStringAsFixed(0)}% ${isAr ? 'إنجاز' : 'completion'}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_timeAgo(technician.lastActivity, isAr), style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 30).clamp(0, 280))).fadeIn(duration: 230.ms).slideY(begin: 0.04);
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
    final monthlyAsync = ref.watch(monthlyInspectionsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      minChildSize: 0.48,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999))),
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
                        Text(technician.fullName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text(technician.email.trim().isEmpty ? technician.username : technician.email, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  _Pill(text: isAr ? 'فني فقط' : 'Technician', color: const Color(0xFF16A34A)),
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
                  _SectionTitle(title: isAr ? 'كل مهام الفني المنسوبة له فقط' : 'Only tasks assigned to this technician', icon: Icons.task_alt_rounded),
                  const SizedBox(height: 8),
                  tasksAsync.when(
                    loading: () => const _InlineLoading(),
                    error: (e, _) => _InlineError(message: e.toString()),
                    data: (tasks) {
                      final sorted = [...tasks]..sort((a, b) => _taskDate(b).compareTo(_taskDate(a)));
                      if (sorted.isEmpty) return _InlineEmpty(text: isAr ? 'لا توجد مهام لهذا الفني' : 'No tasks for this technician');
                      return Column(children: sorted.map((t) => _TaskMiniTile(task: t, isAr: isAr)).toList());
                    },
                  ),
                  const SizedBox(height: 14),
                  _SectionTitle(title: isAr ? 'كل تفتيشات الفني والصور' : 'All inspections & photos', icon: Icons.fact_check_rounded),
                  const SizedBox(height: 8),
                  _TechnicianInspectionsBlock(
                    technician: technician,
                    activityAsync: activityAsync,
                    monthlyAsync: monthlyAsync,
                    isAr: isAr,
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

class _TechnicianInspectionsBlock extends StatelessWidget {
  final TechnicianModel technician;
  final AsyncValue<List<InspectionDetail>> activityAsync;
  final AsyncValue<List<InspectionDetail>> monthlyAsync;
  final bool isAr;

  const _TechnicianInspectionsBlock({
    required this.technician,
    required this.activityAsync,
    required this.monthlyAsync,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    if (activityAsync.isLoading && monthlyAsync.isLoading) return const _InlineLoading();

    final fromActivity = activityAsync.valueOrNull ?? const <InspectionDetail>[];
    final fromMonth = _inspectionsForTech(monthlyAsync.valueOrNull ?? const <InspectionDetail>[], technician);

    final byId = <String, InspectionDetail>{};
    for (final item in [...fromActivity, ...fromMonth]) {
      byId[item.id.isEmpty ? '${item.reportNumber}-${item.inspectedAt.toIso8601String()}' : item.id] = item;
    }

    final list = byId.values.toList()..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));

    if (list.isEmpty && activityAsync.hasError) {
      return _InlineError(message: activityAsync.error.toString());
    }

    if (list.isEmpty) {
      return _InlineEmpty(text: isAr ? 'لا توجد فحوصات لهذا الفني' : 'No inspections for this technician');
    }

    return Column(
      children: [
        _InlineSummary(
          isAr: isAr,
          total: list.length,
          withImages: list.where((x) => x.imageUrl != null && x.imageUrl!.trim().isNotEmpty).length,
          ok: list.where((x) => x.inspectionStatus.toUpperCase() == 'OK').length,
          notOk: list.where((x) => x.inspectionStatus.toUpperCase() != 'OK').length,
        ),
        const SizedBox(height: 8),
        ...list.map((x) => _InspectionMiniTile(item: x, isAr: isAr)),
      ],
    );
  }
}

class _InlineSummary extends StatelessWidget {
  final bool isAr;
  final int total;
  final int withImages;
  final int ok;
  final int notOk;

  const _InlineSummary({required this.isAr, required this.total, required this.withImages, required this.ok, required this.notOk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Metric(label: isAr ? 'التفتيشات' : 'Checks', value: total, color: const Color(0xFF7C3AED))),
        Expanded(child: _Metric(label: isAr ? 'صور' : 'Photos', value: withImages, color: const Color(0xFF0F766E))),
        Expanded(child: _Metric(label: isAr ? 'سليم' : 'OK', value: ok, color: const Color(0xFF16A34A))),
        Expanded(child: _Metric(label: isAr ? 'مشاكل' : 'Issues', value: notOk, color: const Color(0xFFDC2626))),
      ],
    );
  }
}

class _CreateTechnicianSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const _CreateTechnicianSheet({required this.onCreated});

  @override
  ConsumerState<_CreateTechnicianSheet> createState() => _CreateTechnicianSheetState();
}

class _CreateTechnicianSheetState extends ConsumerState<_CreateTechnicianSheet> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController(text: '12345678');
  final _phone = TextEditingController();
  final _job = TextEditingController(text: 'Technician');
  final _region = TextEditingController();
  final _office = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _phone.dispose();
    _job.dispose();
    _region.dispose();
    _office.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.96,
      minChildSize: 0.55,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 16),
            Text(isAr ? 'إضافة فني جديد' : 'Add New Technician', style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Input(ctrl: _first, label: isAr ? 'الاسم الأول *' : 'First name *', icon: Icons.person_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _Input(ctrl: _last, label: isAr ? 'اسم العائلة *' : 'Last name *', icon: Icons.person_outline_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            _Input(ctrl: _username, label: isAr ? 'اسم المستخدم *' : 'Username *', icon: Icons.account_circle_rounded),
            const SizedBox(height: 10),
            _Input(ctrl: _email, label: isAr ? 'الإيميل *' : 'Email *', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _Input(ctrl: _password, label: isAr ? 'كلمة المرور *' : 'Password *', icon: Icons.lock_rounded, obscure: true),
            const SizedBox(height: 10),
            _Input(ctrl: _phone, label: isAr ? 'الهاتف' : 'Phone', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _Input(ctrl: _job, label: isAr ? 'الوظيفة' : 'Job title', icon: Icons.badge_rounded),
            const SizedBox(height: 10),
            _Input(ctrl: _region, label: isAr ? 'المنطقة' : 'Region', icon: Icons.map_rounded),
            const SizedBox(height: 10),
            _Input(ctrl: _office, label: isAr ? 'رقم المكتب' : 'Office number', icon: Icons.apartment_rounded),
            const SizedBox(height: 10),
            _Input(ctrl: _notes, label: isAr ? 'ملاحظات' : 'Notes', icon: Icons.notes_rounded, maxLines: 2),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: Text(isAr ? 'إلغاء' : 'Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(isAr ? 'إضافة الفني' : 'Add Technician'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty || _username.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(adminRepoProvider).createTechnician(
            CreateTechnicianRequest(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              email: _email.text.trim(),
              username: _username.text.trim(),
              password: _password.text.trim(),
              phone: _optional(_phone.text),
              jobTitle: _optional(_job.text) ?? 'Technician',
              region: _optional(_region.text),
              officeNumber: _optional(_office.text),
              notes: _optional(_notes.text),
            ),
          );
      ref.invalidate(activeTechniciansProvider);
      ref.invalidate(techniciansProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminAnalyticsProvider);
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Input({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
      _InfoRow(label: isAr ? 'اسم المستخدم' : 'Username', value: technician.username),
      _InfoRow(label: isAr ? 'الهاتف' : 'Phone', value: technician.phone ?? '-'),
      _InfoRow(label: isAr ? 'الوظيفة' : 'Job title', value: technician.jobTitle ?? '-'),
      _InfoRow(label: isAr ? 'المنطقة' : 'Region', value: technician.region ?? '-'),
      _InfoRow(label: isAr ? 'المكتب' : 'Office', value: technician.officeNumber ?? '-'),
      _InfoRow(label: isAr ? 'ملاحظات' : 'Notes', value: technician.notes ?? '-'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 58, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(task.deviceName ?? (isAr ? 'بدون جهاز' : 'No device'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B))),
                Text(_dateTime(_taskDate(task)), style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFF94A3B8))),
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
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.deviceName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
              _Pill(text: item.statusAr, color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text('${item.deviceCode} — ${item.locationText}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B))),
          if ((item.notes ?? '').isNotEmpty || (item.issueReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.issueReason ?? item.notes ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF334155))),
          ],
          if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl!,
                height: 155,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 95,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: Icon(Icons.image_not_supported_rounded, color: Color(0xFF94A3B8))),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(_dateTime(item.inspectedAt), style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15))),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$value', style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 9.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.w900)),
      );
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, this.size = 50});

  @override
  Widget build(BuildContext context) {
    final clean = name.trim();
    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();
    final initials = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : (clean.isEmpty ? '?' : clean[0]);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF1A237E)])),
      alignment: Alignment.center,
      child: Text(initials.toUpperCase(), style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: size * 0.34)),
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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.12))),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 900.ms),
      );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator()));
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: const TextStyle(color: Color(0xFFDC2626))),
      );
}

class _InlineEmpty extends StatelessWidget {
  final String text;

  const _InlineEmpty({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isAr;

  const _EmptyState({required this.isAr});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(isAr ? 'لا يوجد فنيين نشطين' : 'No active technicians', style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B), fontWeight: FontWeight.w900)),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 44),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626))),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

List<TaskModel> _tasksForTech(List<TaskModel> tasks, TechnicianModel tech) {
  return tasks.where((t) {
    if (t.assignedToId != null && t.assignedToId == tech.id) return true;
    final assigned = (t.assignedToName ?? '').trim().toLowerCase();
    final full = tech.fullName.trim().toLowerCase();
    final username = tech.username.trim().toLowerCase();
    return assigned.isNotEmpty && (assigned == full || assigned == username);
  }).toList();
}

List<InspectionDetail> _inspectionsForTech(List<InspectionDetail> inspections, TechnicianModel tech) {
  final full = tech.fullName.trim().toLowerCase();
  final username = tech.username.trim().toLowerCase();
  final email = tech.email.trim().toLowerCase();

  return inspections.where((i) {
    final name = i.technicianName.trim().toLowerCase();
    return name == full || name == username || name == email || (name.isNotEmpty && full.isNotEmpty && name.contains(full));
  }).toList();
}

DateTime _taskDate(TaskModel task) => task.completedAt ?? task.dueDate ?? task.createdAt;

Color _taskColor(TaskModel task) {
  final s = task.status.toUpperCase();
  if (task.isUrgent || task.isEmergency || task.priority.toUpperCase() == 'URGENT') return const Color(0xFFDC2626);
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

String _dateTime(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _timeAgo(DateTime? d, bool isAr) {
  if (d == null) return isAr ? 'لا يوجد نشاط' : 'No activity';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Now';
  if (diff.inMinutes < 60) return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
  return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
}

String? _optional(String value) {
  final v = value.trim();
  return v.isEmpty ? null : v;
}
