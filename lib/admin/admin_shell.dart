import 'dart:ui';

import 'package:access_track/admin/admin_analytics_screen.dart';
import 'package:access_track/admin/admin_dashboard.dart';
import 'package:access_track/admin/admin_devices_screen.dart';
import 'package:access_track/admin/admin_inspections_screen.dart' as inspections;
import 'package:access_track/admin/admin_location_screen.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_screens.dart';
import 'package:access_track/admin/admin_system_management_screen.dart';
import 'package:access_track/admin/admin_tasks_screen.dart';
import 'package:access_track/admin/admin_technicians_screen.dart' as technicians;
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminMainShell extends ConsumerWidget {
  final String adminName;
  final VoidCallback onLogout;

  const AdminMainShell({
    super.key,
    required this.adminName,
    required this.onLogout,
  });

  static const int dashboardIndex = 0;
  static const int analyticsIndex = 1;
  static const int scanIndex = 2;
  static const int tasksIndex = 3;
  static const int devicesIndex = 4;
  static const int techniciansIndex = 5;
  static const int inspectionsIndex = 6;
  static const int systemIndex = 7;
  static const int locationsIndex = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final index = ref.watch(adminPageIndexProvider);
    final safeIndex = index.clamp(0, 8);

    if (safeIndex != index) {
      Future.microtask(() {
        ref.read(adminPageIndexProvider.notifier).state = dashboardIndex;
      });
    }

    final pages = <Widget>[
      AdminDashboardScreen(adminName: adminName, onLogout: onLogout),
      const AdminAnalyticsScreen(),
      const AdminScanScreen(),
      const AdminTasksScreen(),
      const AdminDevicesScreen(),
      const technicians.AdminTechniciansScreen(),
      const inspections.AdminInspectionsScreen(),
      SystemManagementScreen(adminName: adminName, onLogout: onLogout),
      const AdminLocationScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (safeIndex != dashboardIndex) {
          ref.read(adminPageIndexProvider.notifier).state = dashboardIndex;
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: safeIndex,
          children: pages,
        ),
        bottomNavigationBar: _AdminBottomBar(
          currentIndex: safeIndex,
          onTap: (newIndex) {
            if (newIndex == -1) {
              _showHubMenu(context, ref, l);
            } else {
              ref.read(adminPageIndexProvider.notifier).state = newIndex;
            }
          },
        ),
      ),
    );
  }

  void _showHubMenu(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey.withOpacity(0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.isAr ? 'مركز العمليات المتقدم' : 'Advanced Operations Hub',
                        style: AppText.h3,
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: -0.10),
                const SizedBox(height: 22),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _HubItem(
                      icon: Icons.devices_rounded,
                      label: l.isAr ? 'الأجهزة' : 'Devices',
                      color: AppColors.info,
                      onTap: () => _go(ctx, ref, devicesIndex),
                    ),
                    _HubItem(
                      icon: Icons.people_rounded,
                      label: l.isAr ? 'الفنيين' : 'Techs',
                      color: AppColors.success,
                      onTap: () => _go(ctx, ref, techniciansIndex),
                    ),
                    _HubItem(
                      icon: Icons.assignment_rounded,
                      label: l.isAr ? 'التقارير' : 'Reports',
                      color: AppColors.warning,
                      onTap: () => _go(ctx, ref, inspectionsIndex),
                    ),
                    _HubItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: l.isAr ? 'النظام' : 'System',
                      color: AppColors.error,
                      onTap: () => _go(ctx, ref, systemIndex),
                    ),
                    _HubItem(
                      icon: Icons.place_rounded,
                      label: l.isAr ? 'المواقع' : 'Locations',
                      color: AppColors.accent,
                      onTap: () => _go(ctx, ref, locationsIndex),
                    ),
                    _HubItem(
                      icon: Icons.refresh_rounded,
                      label: l.isAr ? 'تحديث' : 'Refresh',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _refreshBackend(ref);
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
              ],
            ),
          ),
        );
      },
    );
  }

  void _go(BuildContext ctx, WidgetRef ref, int index) {
    Navigator.pop(ctx);
    ref.read(adminPageIndexProvider.notifier).state = index;
  }

  void _refreshBackend(WidgetRef ref) {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(adminAnalyticsProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(techniciansProvider);
    ref.invalidate(activeTechniciansProvider);
    ref.invalidate(adminDevicesProvider(null));
    ref.invalidate(monthlyInspectionsProvider);
    ref.invalidate(locationsProvider);
  }
}

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: l.isAr ? 'الرئيسية' : 'Main',
                    selected: currentIndex == AdminMainShell.dashboardIndex,
                    onTap: () => onTap(AdminMainShell.dashboardIndex),
                  ),
                  _NavItem(
                    icon: Icons.analytics_rounded,
                    label: l.isAr ? 'التحليلات' : 'Analytics',
                    selected: currentIndex == AdminMainShell.analyticsIndex,
                    onTap: () => onTap(AdminMainShell.analyticsIndex),
                  ),
                  _ScanButton(
                    selected: currentIndex == AdminMainShell.scanIndex,
                    onTap: () => onTap(AdminMainShell.scanIndex),
                  ),
                  _NavItem(
                    icon: Icons.task_alt_rounded,
                    label: l.isAr ? 'المهام' : 'Tasks',
                    selected: currentIndex == AdminMainShell.tasksIndex,
                    onTap: () => onTap(AdminMainShell.tasksIndex),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: l.isAr ? 'المزيد' : 'Hub',
                    selected: currentIndex >= AdminMainShell.devicesIndex,
                    onTap: () => onTap(-1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ScanButton({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 240.ms,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, Color(0xFF00B4D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(selected ? 0.55 : 0.35),
              blurRadius: selected ? 20 : 14,
              spreadRadius: selected ? 3 : 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ).animate(target: selected ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.12, 1.12),
          ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 260.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accent : Colors.white60,
              size: 22,
            ).animate(target: selected ? 1 : 0).scale(
                  begin: const Offset(0.90, 0.90),
                  end: const Offset(1.10, 1.10),
                ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.accent : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HubItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.26)),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppText.smallBold.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
