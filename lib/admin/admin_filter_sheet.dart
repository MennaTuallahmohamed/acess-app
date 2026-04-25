import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminFilterSheet extends ConsumerStatefulWidget {
  const AdminFilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminFilterSheet(),
    );
  }

  @override
  ConsumerState<AdminFilterSheet> createState() => _AdminFilterSheetState();
}

class _AdminFilterSheetState extends ConsumerState<AdminFilterSheet>
    with SingleTickerProviderStateMixin {
  late String _dateRange;
  late String _deviceStatus;
  late String _taskStatus;
  late String _cluster;
  late String _building;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(adminGlobalFilterProvider);
    _dateRange = filter.dateRange;
    _deviceStatus = filter.deviceStatus;
    _taskStatus = filter.taskStatus;
    _cluster = filter.cluster;
    _building = filter.building;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_dateRange != 'ALL') count++;
    if (_deviceStatus != 'ALL') count++;
    if (_taskStatus != 'ALL') count++;
    if (_cluster != 'ALL') count++;
    if (_building != 'ALL') count++;
    return count;
  }

  void _resetAll() {
    setState(() {
      _dateRange = 'ALL';
      _deviceStatus = 'ALL';
      _taskStatus = 'ALL';
      _cluster = 'ALL';
      _building = 'ALL';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E1420),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 24),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF4A90D9), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.isAr ? 'فلتر متقدم' : 'Advanced Filter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_activeFilterCount > 0)
                          Text(
                            l.isAr
                                ? '$_activeFilterCount فلتر نشط'
                                : '$_activeFilterCount active filter${_activeFilterCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF4A90D9),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    GestureDetector(
                      onTap: _resetAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                        ),
                        child: Text(
                          l.isAr ? 'مسح الكل' : 'Reset all',
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Date Range
              _FilterSection(
                title: l.isAr ? 'الفترة الزمنية' : 'Date Range',
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFF7B61FF),
                child: Row(
                  children: [
                    _DateChip(label: l.isAr ? 'الكل' : 'All', value: 'ALL', selected: _dateRange, icon: Icons.all_inclusive_rounded, onTap: (v) => setState(() => _dateRange = v)),
                    const SizedBox(width: 8),
                    _DateChip(label: l.isAr ? 'اليوم' : 'Today', value: 'TODAY', selected: _dateRange, icon: Icons.today_rounded, onTap: (v) => setState(() => _dateRange = v)),
                    const SizedBox(width: 8),
                    _DateChip(label: l.isAr ? 'الأسبوع' : 'Week', value: 'WEEK', selected: _dateRange, icon: Icons.date_range_rounded, onTap: (v) => setState(() => _dateRange = v)),
                    const SizedBox(width: 8),
                    _DateChip(label: l.isAr ? 'الشهر' : 'Month', value: 'MONTH', selected: _dateRange, icon: Icons.calendar_view_month_rounded, onTap: (v) => setState(() => _dateRange = v)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Device Status
              _FilterSection(
                title: l.isAr ? 'حالة الأجهزة' : 'Device Status',
                icon: Icons.devices_rounded,
                accentColor: const Color(0xFF00C9A7),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusChip(
                      label: l.isAr ? 'الكل' : 'All',
                      value: 'ALL',
                      selected: _deviceStatus,
                      color: Colors.white.withOpacity(0.4),
                      onTap: (v) => setState(() => _deviceStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'سليم' : 'Healthy',
                      value: 'OK',
                      selected: _deviceStatus,
                      color: const Color(0xFF00C9A7),
                      onTap: (v) => setState(() => _deviceStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'صيانة' : 'Maintenance',
                      value: 'NEEDS_MAINTENANCE',
                      selected: _deviceStatus,
                      color: const Color(0xFFFFB347),
                      onTap: (v) => setState(() => _deviceStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'خارج الخدمة' : 'Out of Service',
                      value: 'OUT_OF_SERVICE',
                      selected: _deviceStatus,
                      color: const Color(0xFFFF6B6B),
                      onTap: (v) => setState(() => _deviceStatus = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Task Status
              _FilterSection(
                title: l.isAr ? 'حالة المهام' : 'Task Status',
                icon: Icons.task_alt_rounded,
                accentColor: const Color(0xFF7B61FF),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusChip(
                      label: l.isAr ? 'الكل' : 'All',
                      value: 'ALL',
                      selected: _taskStatus,
                      color: Colors.white.withOpacity(0.4),
                      onTap: (v) => setState(() => _taskStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'معلقة' : 'Pending',
                      value: 'PENDING',
                      selected: _taskStatus,
                      color: const Color(0xFFFFB347),
                      onTap: (v) => setState(() => _taskStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'جارية' : 'In Progress',
                      value: 'IN_PROGRESS',
                      selected: _taskStatus,
                      color: const Color(0xFF4A90D9),
                      onTap: (v) => setState(() => _taskStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'مكتملة' : 'Completed',
                      value: 'COMPLETED',
                      selected: _taskStatus,
                      color: const Color(0xFF00C9A7),
                      onTap: (v) => setState(() => _taskStatus = v),
                    ),
                    _StatusChip(
                      label: l.isAr ? 'متأخرة' : 'Overdue',
                      value: 'OVERDUE',
                      selected: _taskStatus,
                      color: const Color(0xFFFF6B6B),
                      onTap: (v) => setState(() => _taskStatus = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Location Row
              Row(
                children: [
                  Expanded(
                    child: _FilterSection(
                      title: l.isAr ? 'المجموعة' : 'Cluster',
                      icon: Icons.hub_rounded,
                      accentColor: const Color(0xFF4A90D9),
                      child: _DarkDropdown(
                        value: _cluster,
                        items: [
                          _DropdownItem(value: 'ALL', label: l.isAr ? 'الكل' : 'All'),
                          const _DropdownItem(value: '17A/18A', label: 'Cluster 17A/18A'),
                          const _DropdownItem(value: '3A/4A', label: 'Cluster 3A/4A'),
                        ],
                        onChanged: (v) => setState(() => _cluster = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FilterSection(
                      title: l.isAr ? 'المبنى' : 'Building',
                      icon: Icons.domain_rounded,
                      accentColor: const Color(0xFF00C9A7),
                      child: _DarkDropdown(
                        value: _building,
                        items: [
                          _DropdownItem(value: 'ALL', label: l.isAr ? 'الكل' : 'All'),
                          _DropdownItem(value: 'وزارة الصحة', label: l.isAr ? 'وزارة الصحة' : 'MOH'),
                          _DropdownItem(value: 'وزارة التربية والتعليم', label: l.isAr ? 'وزارة التعليم' : 'MOE'),
                        ],
                        onChanged: (v) => setState(() => _building = v),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Active filters preview
              if (_activeFilterCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_dateRange != 'ALL') _ActiveTag(label: _dateRange),
                      if (_deviceStatus != 'ALL') _ActiveTag(label: _deviceStatus),
                      if (_taskStatus != 'ALL') _ActiveTag(label: _taskStatus),
                      if (_cluster != 'ALL') _ActiveTag(label: _cluster),
                      if (_building != 'ALL') _ActiveTag(label: _building),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Apply button
              GestureDetector(
                onTap: () {
                  ref.read(adminGlobalFilterProvider.notifier).state =
                      GlobalAdminFilter(
                    dateRange: _dateRange,
                    deviceStatus: _deviceStatus,
                    taskStatus: _taskStatus,
                    cluster: _cluster,
                    building: _building,
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90D9), Color(0xFF7B61FF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90D9).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        l.isAr
                            ? 'تطبيق الفلاتر${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}'
                            : 'Apply Filters${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

// ── Active Tag ─────────────────────────────────────────────
class _ActiveTag extends StatelessWidget {
  final String label;
  const _ActiveTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90D9).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A90D9),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Filter Section ─────────────────────────────────────────
class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111826),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Date Chip ──────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final IconData icon;
  final ValueChanged<String> onTap;
  const _DateChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7B61FF).withOpacity(0.2)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7B61FF).withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF7B61FF) : Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status Chip ────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final ValueChanged<String> onTap;
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withOpacity(0.4),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dark Dropdown ──────────────────────────────────────────
class _DropdownItem {
  final String value;
  final String label;
  const _DropdownItem({required this.value, required this.label});
}

class _DarkDropdown extends StatelessWidget {
  final String value;
  final List<_DropdownItem> items;
  final ValueChanged<String> onChanged;
  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF1A2035),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 18,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item.value,
            child: Text(item.label),
          )).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}