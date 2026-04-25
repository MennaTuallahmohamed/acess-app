import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void setAppLanguageEnglish(BuildContext context) {
  LanguageController.of(context).setLocale(const Locale('en', 'US'));
}

void setAppLanguageArabic(BuildContext context) {
  LanguageController.of(context).setLocale(const Locale('ar', 'EG'));
}

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback onPersonalData;
  final VoidCallback onNotifications;
  final VoidCallback onSecurity;
  final VoidCallback onMonthlyReports;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onPersonalData,
    required this.onNotifications,
    required this.onSecurity,
    required this.onMonthlyReports,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.substring(
                                  0,
                                  user.name.length >= 2 ? 2 : 1,
                                )
                              : '?',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: AppText.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.roleLabel(user.role),
                        style: AppText.small.copyWith(color: Colors.white60),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.region.isNotEmpty
                              ? user.region
                              : (l.isAr ? 'بدون منطقة' : 'No region'),
                          style: AppText.caption.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileActionCard(
                    icon: Icons.person_outline_rounded,
                    title: l.personalData,
                    subtitle: l.isAr
                        ? 'عرض وتعديل البيانات الأساسية'
                        : 'View and edit personal information',
                    onTap: onPersonalData,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06),
                  const SizedBox(height: 12),
                  _ProfileActionCard(
                    icon: Icons.notifications_none_rounded,
                    title: l.notifications,
                    subtitle: l.isAr
                        ? 'إدارة التنبيهات والإشعارات'
                        : 'Manage alerts and notifications',
                    onTap: onNotifications,
                  ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 12),
                  _ProfileActionCard(
                    icon: Icons.security_rounded,
                    title: l.security2,
                    subtitle: l.isAr
                        ? 'كلمات المرور والجلسات النشطة'
                        : 'Passwords and active sessions',
                    onTap: onSecurity,
                  ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 12),
                  _ProfileActionCard(
                    icon: Icons.bar_chart_rounded,
                    title: l.monthlyReports,
                    subtitle: l.isAr
                        ? 'تقارير الأداء الشهرية'
                        : 'Monthly performance reports',
                    onTap: onMonthlyReports,
                  ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 12),
                  _LanguageToggleCard(
                    onEnglishTap: () => setAppLanguageEnglish(context),
                    onArabicTap: () => setAppLanguageArabic(context),
                  ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 12),
                  _ProfileActionCard(
                    icon: Icons.logout_rounded,
                    title: l.logout,
                    subtitle: l.isAr
                        ? 'تسجيل الخروج من الحساب الحالي'
                        : 'Sign out of the current account',
                    danger: true,
                    onTap: onLogout,
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePreferenceRow extends StatelessWidget {
  final VoidCallback onEnglishTap;
  final VoidCallback onArabicTap;

  const _LanguagePreferenceRow({
    required this.onEnglishTap,
    required this.onArabicTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isAr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.translate_rounded,
            size: 18,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'لغة التطبيق' : 'App language',
                  style: AppText.bodyMed,
                ),
                const SizedBox(height: 2),
                Text(
                  isAr ? 'اختاري اللغة المطلوبة' : 'Choose app language',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _LanguageMiniButton(
            label: 'AR',
            selected: isAr,
            onTap: onArabicTap,
          ),
          const SizedBox(width: 8),
          _LanguageMiniButton(
            label: 'EN',
            selected: !isAr,
            onTap: onEnglishTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyMed),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggleCard extends StatelessWidget {
  final VoidCallback onEnglishTap;
  final VoidCallback onArabicTap;

  const _LanguageToggleCard({
    required this.onEnglishTap,
    required this.onArabicTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isAr;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.language, style: AppText.bodyMed),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'اللغة الحالية: العربية'
                      : 'Current language: English',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _LanguageMiniButton(
            label: 'AR',
            selected: isAr,
            onTap: onArabicTap,
          ),
          const SizedBox(width: 8),
          _LanguageMiniButton(
            label: 'EN',
            selected: !isAr,
            onTap: onEnglishTap,
          ),
        ],
      ),
    );
  }
}

class _LanguageMiniButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageMiniButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.20),
          ),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PERSONAL DATA SCREEN
// ═══════════════════════════════════════════════════════

class PersonalDataScreen extends StatefulWidget {
  final UserModel user;

  const PersonalDataScreen({
    super.key,
    required this.user,
  });

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  bool _editing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: '01012345678');
    _emailCtrl = TextEditingController(text: 'ahmed.hussein@ministry.gov.eg');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(
                  _editing ? l.saveChanges : l.editProfile,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: AppColors.accent,
                            child: Text(
                              widget.user.name.length >= 2
                                  ? widget.user.name.substring(0, 2)
                                  : widget.user.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (_editing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.user.name,
                        style: AppText.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.roleLabel(widget.user.role),
                        style: AppText.small.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoBadge(
                    icon: Icons.email_rounded,
                    label: l.email,
                    value: widget.user.email,
                    color: AppColors.primary,
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.personalData,
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        _Field(
                          label: l.fullName,
                          ctrl: _nameCtrl,
                          icon: Icons.person_rounded,
                          editing: _editing,
                          keyboard: TextInputType.name,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _Field(
                          label: l.phone,
                          ctrl: _phoneCtrl,
                          icon: Icons.phone_rounded,
                          editing: _editing,
                          keyboard: TextInputType.phone,
                          isLtr: true,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _Field(
                          label: l.email,
                          ctrl: _emailCtrl,
                          icon: Icons.email_rounded,
                          editing: _editing,
                          keyboard: TextInputType.emailAddress,
                          isLtr: true,
                        ),
                      ],
                    ),
                  ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.language,
                    icon: Icons.language_rounded,
                    child: _LanguagePreferenceRow(
                      onEnglishTap: () => setAppLanguageEnglish(context),
                      onArabicTap: () => setAppLanguageArabic(context),
                    ),
                  ).animate(delay: 110.ms).fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.isAr ? 'بيانات العمل' : 'Work Info',
                    icon: Icons.work_outline_rounded,
                    child: Column(
                      children: [
                        _ReadRow(
                          label: l.jobTitle,
                          value: l.roleLabel(widget.user.role),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _ReadRow(
                          label: l.regionLbl,
                          value: widget.user.region,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _ReadRow(
                          label: l.departmentLbl,
                          value: l.isAr
                              ? 'إدارة التفتيش الميداني'
                              : 'Field Inspection Dept.',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _ReadRow(
                          label: l.hireDate,
                          value: l.isAr ? '١ مارس ٢٠١٩' : 'March 1, 2019',
                        ),
                      ],
                    ),
                  ).animate(delay: 130.ms).fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.isAr ? 'إحصائياتي' : 'My Statistics',
                    icon: Icons.bar_chart_rounded,
                    child: Row(
                      children: [
                        _StatCol(
                          widget.user.totalInspections.toString(),
                          l.totalInsp,
                          AppColors.info,
                        ),
                        _VDiv(),
                        _StatCol(
                          widget.user.monthInspections.toString(),
                          l.thisMonth,
                          AppColors.primary,
                        ),
                        _VDiv(),
                        _StatCol(
                          '${widget.user.completionRate.toStringAsFixed(0)}%',
                          l.completionRate,
                          AppColors.success,
                        ),
                      ],
                    ),
                  ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppText.h4.copyWith(
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context).isAr ? 'رسمي' : 'Official',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(title, style: AppText.h4),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            child,
          ],
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool editing;
  final bool isLtr;
  final TextInputType keyboard;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.icon,
    required this.editing,
    this.isLtr = false,
    required this.keyboard,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: editing
                  ? TextField(
                      controller: ctrl,
                      keyboardType: keyboard,
                      textDirection: isLtr ? TextDirection.ltr : null,
                      style: AppText.body,
                      decoration: InputDecoration(
                        labelText: label,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppText.caption),
                          const SizedBox(height: 2),
                          Text(
                            ctrl.text,
                            style: AppText.bodyMed,
                            textDirection: isLtr ? TextDirection.ltr : null,
                          ),
                        ],
                      ),
                    ),
            ),
            if (editing)
              const Icon(
                Icons.edit_rounded,
                size: 14,
                color: AppColors.accent,
              ),
          ],
        ),
      );
}

class _ReadRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: AppText.small),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: AppText.bodyMed,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCol(
    this.value,
    this.label,
    this.color,
  );

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value, style: AppText.h3.copyWith(color: color)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _VDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

// ═══════════════════════════════════════════════════════
//  SETTINGS SCREEN
// ═══════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  bool _notifPush = true;
  bool _notifTasks = true;
  bool _notifAlert = true;
  bool _notifSync = false;
  bool _autoSync = true;
  bool _darkMode = false;
  String _fontSize = 'medium';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
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
        title: Text(
          l.settings,
          style: AppText.h4.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: l.general),
            Tab(text: l.security2),
            Tab(text: l.about),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GeneralTab(
            notifPush: _notifPush,
            onNotifPush: (v) => setState(() => _notifPush = v),
            notifTasks: _notifTasks,
            onNotifTasks: (v) => setState(() => _notifTasks = v),
            notifAlert: _notifAlert,
            onNotifAlert: (v) => setState(() => _notifAlert = v),
            notifSync: _notifSync,
            onNotifSync: (v) => setState(() => _notifSync = v),
            autoSync: _autoSync,
            onAutoSync: (v) => setState(() => _autoSync = v),
            darkMode: _darkMode,
            onDarkMode: (v) => setState(() => _darkMode = v),
            fontSize: _fontSize,
            onFontSize: (v) => setState(() => _fontSize = v),
            l: l,
          ),
          _SecurityTab(l: l),
          _AboutTab(l: l),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  final bool notifPush;
  final bool notifTasks;
  final bool notifAlert;
  final bool notifSync;
  final bool autoSync;
  final bool darkMode;

  final Function(bool) onNotifPush;
  final Function(bool) onNotifTasks;
  final Function(bool) onNotifAlert;
  final Function(bool) onNotifSync;
  final Function(bool) onAutoSync;
  final Function(bool) onDarkMode;

  final String fontSize;
  final Function(String) onFontSize;

  final AppLocalizations l;

  const _GeneralTab({
    required this.notifPush,
    required this.onNotifPush,
    required this.notifTasks,
    required this.onNotifTasks,
    required this.notifAlert,
    required this.onNotifAlert,
    required this.notifSync,
    required this.onNotifSync,
    required this.autoSync,
    required this.onAutoSync,
    required this.darkMode,
    required this.onDarkMode,
    required this.fontSize,
    required this.onFontSize,
    required this.l,
  });

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettSection(
            title: l.notifSettings,
            icon: Icons.notifications_outlined,
            items: [
              _SettSwitch(
                label: l.notifPush,
                subtitle: l.isAr ? 'جميع الإشعارات' : 'All notifications',
                value: notifPush,
                color: AppColors.info,
                onChanged: onNotifPush,
              ),
              _SettSwitch(
                label: l.notifTasks,
                subtitle: l.isAr ? 'المهام الجديدة' : 'New tasks assigned',
                value: notifTasks,
                color: AppColors.success,
                onChanged: onNotifTasks,
              ),
              _SettSwitch(
                label: l.notifAlert,
                subtitle: l.isAr ? 'أجهزة لم تُفتَّش' : 'Uninspected devices',
                value: notifAlert,
                color: AppColors.error,
                onChanged: onNotifAlert,
              ),
              _SettSwitch(
                label: l.notifSync,
                subtitle: l.isAr ? 'نتائج المزامنة' : 'Sync results',
                value: notifSync,
                color: AppColors.maintenance,
                onChanged: onNotifSync,
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 12),
          _SettSection(
            title: l.appSettings,
            icon: Icons.settings_outlined,
            items: [
              _SettSwitch(
                label: l.autoSync,
                subtitle: l.autoSyncNote,
                value: autoSync,
                color: AppColors.accent,
                onChanged: onAutoSync,
              ),
              _SettSwitch(
                label: l.darkMode,
                subtitle: l.isAr ? 'قريباً' : 'Coming soon',
                value: darkMode,
                color: AppColors.primary,
                onChanged: (_) {},
              ),
              _SettItem(
                label: l.clearCache,
                subtitle: l.isAr ? '2.4 MB مستخدمة' : '2.4 MB used',
                trailing: _Badge(l.isAr ? 'مسح' : 'Clear', AppColors.error),
                onTap: () {},
              ),
            ],
          ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.06),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.text_fields_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(l.fontSize, style: AppText.h4),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: ['small', 'medium', 'large'].map((s) {
                    final labels = l.isAr
                        ? ['صغير', 'متوسط', 'كبير']
                        : ['Small', 'Medium', 'Large'];
                    final idx = ['small', 'medium', 'large'].indexOf(s);
                    final sel = fontSize == s;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onFontSize(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate(delay: 130.ms).fadeIn(),
          const SizedBox(height: 80),
        ],
      );
}

class _SecurityTab extends StatelessWidget {
  final AppLocalizations l;

  const _SecurityTab({
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final currCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettSection(
          title: l.changePassword,
          icon: Icons.lock_outline_rounded,
          items: [
            _PassField(label: l.currentPass, ctrl: currCtrl),
            _PassField(label: l.newPass, ctrl: newCtrl),
            _PassField(label: l.confirmPass, ctrl: confCtrl),
          ],
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          child: Text(l.changePassword),
        ).animate(delay: 80.ms).fadeIn(),
        const SizedBox(height: 12),
        _SettSection(
          title: l.isAr ? 'جلسات الدخول' : 'Active Sessions',
          icon: Icons.devices_rounded,
          items: [
            _SettItem(
              label: l.isAr ? 'هذا الجهاز — Android' : 'This Device — Android',
              subtitle: l.isAr ? 'القاهرة — نشط الآن' : 'Cairo — Active Now',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.isAr ? 'نشط' : 'Active',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {},
            ),
          ],
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _PassField extends StatefulWidget {
  final String label;
  final TextEditingController ctrl;

  const _PassField({
    required this.label,
    required this.ctrl,
  });

  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _obs = true;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: widget.ctrl,
          obscureText: _obs,
          textDirection: TextDirection.ltr,
          style: AppText.body,
          decoration: InputDecoration(
            labelText: widget.label,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.accent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                _obs
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
              onPressed: () => setState(() => _obs = !_obs),
            ),
          ),
        ),
      );
}

class _AboutTab extends StatelessWidget {
  final AppLocalizations l;

  const _AboutTab({
    required this.l,
  });

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
              ),
          Center(child: Text(l.appName, style: AppText.h3))
              .animate(delay: 100.ms)
              .fadeIn(),
          const SizedBox(height: 4),
          Center(child: Text(l.ministry, style: AppText.small))
              .animate(delay: 120.ms)
              .fadeIn(),
          const SizedBox(height: 24),
          _SettSection(
            title: l.about,
            icon: Icons.info_outline_rounded,
            items: [
              _SettItem(
                label: l.appVersion,
                subtitle: '3.0.0 (Build 47)',
                trailing: null,
                onTap: () {},
              ),
              _SettItem(
                label: l.isAr ? 'تاريخ الإصدار' : 'Release Date',
                subtitle: l.isAr ? 'مارس ٢٠٢٥' : 'March 2025',
                trailing: null,
                onTap: () {},
              ),
              _SettItem(
                label: l.privacyPolicy,
                subtitle: null,
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
                onTap: () {},
              ),
              _SettItem(
                label: l.termsOfUse,
                subtitle: null,
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
                onTap: () {},
              ),
            ],
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.08),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l.isAr
                  ? '© ٢٠٢٥ وزارة التنمية المحلية'
                  : '© 2025 Ministry of Local Development',
              style: AppText.caption,
            ),
          ).animate(delay: 250.ms).fadeIn(),
          const SizedBox(height: 80),
        ],
      );
}

class _SettSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> items;

  const _SettSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(title, style: AppText.h4),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            ...items.asMap().entries.map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 16,
                      color: AppColors.border,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SettSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SettSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.circle, color: color, size: 10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.bodyMed),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accent,
              activeTrackColor: AppColors.accent.withOpacity(0.3),
            ),
          ],
        ),
      );
}

class _SettItem extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettItem({
    required this.label,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.bodyMed),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.caption),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
            ],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(
    this.text,
    this.color,
  );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
