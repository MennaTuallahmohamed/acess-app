import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_shared.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/api/api_client.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart' hide SectionHeader;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemManagementScreen extends ConsumerWidget {
  final String adminName;
  final VoidCallback onLogout;

  const SystemManagementScreen({
    super.key,
    required this.adminName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    final stats = ref.watch(adminStatsProvider);
    final technicians = ref.watch(techniciansProvider);
    final locations = ref.watch(locationsProvider);
    final devices = ref.watch(adminDevicesProvider(null));

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: GradientAppBar(
        title: l.isAr ? 'إدارة النظام' : 'System Control',
        subtitle: l.isAr
            ? 'إدارة الحسابات ومراقبة بيانات الباك إند'
            : 'Manage accounts and backend data',
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(techniciansProvider);
          ref.invalidate(activeTechniciansProvider);
          ref.invalidate(locationsProvider);
          ref.invalidate(adminDevicesProvider(null));
          ref.invalidate(adminAnalyticsProvider);
          ref.invalidate(allTasksProvider);
          ref.invalidate(monthlyInspectionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            _AdminProfileCard(
              adminName: adminName,
              onLogout: onLogout,
            ),
            const SizedBox(height: 22),
            stats.when(
              loading: () => const AdminShimmerList(count: 2),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (s) => _SystemNumbers(
                isAr: l.isAr,
                stats: s,
                techniciansCount: technicians.valueOrNull?.length,
                devicesCount: devices.valueOrNull?.length,
                locationsCount: locations.valueOrNull?.length,
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: l.isAr ? 'إنشاء حسابات' : 'Account Provisioning',
              icon: Icons.person_add_rounded,
            ),
            const SizedBox(height: 14),
            _RoleActionCard(
              title: l.isAr ? 'إنشاء حساب مدير' : 'Create Admin Account',
              desc: l.isAr
                  ? 'صلاحيات كاملة لإدارة النظام'
                  : 'Full system administrative access',
              icon: Icons.admin_panel_settings_rounded,
              color: AppColors.accent,
              onTap: () => _openCreateUserSheet(context, 'ADMIN'),
            ),
            const SizedBox(height: 12),
            _RoleActionCard(
              title: l.isAr ? 'إنشاء حساب مشاهد' : 'Create Viewer Account',
              desc: l.isAr
                  ? 'صلاحيات مشاهدة وقراءة التقارير فقط'
                  : 'Read-only access to reports and operations',
              icon: Icons.visibility_rounded,
              color: AppColors.info,
              onTap: () => _openCreateUserSheet(context, 'VIEWER'),
            ),
            const SizedBox(height: 12),
            _RoleActionCard(
              title: l.isAr ? 'إنشاء حساب فني' : 'Create Technician Account',
              desc: l.isAr
                  ? 'حساب للفنيين لتنفيذ المهام والتفتيشات'
                  : 'Technician account for tasks and inspections',
              icon: Icons.engineering_rounded,
              color: AppColors.success,
              onTap: () => _openCreateUserSheet(context, 'TECHNICIAN'),
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: l.isAr ? 'بيانات الباك إند' : 'Backend Data',
              icon: Icons.storage_rounded,
            ),
            const SizedBox(height: 14),
            _BackendDataCard(
              isAr: l.isAr,
              technicians: technicians,
              locations: locations,
              devices: devices,
              onRefresh: () {
                ref.invalidate(techniciansProvider);
                ref.invalidate(locationsProvider);
                ref.invalidate(adminDevicesProvider(null));
              },
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: l.isAr ? 'تفضيلات النظام' : 'System Preferences',
              icon: Icons.settings_rounded,
            ),
            const SizedBox(height: 12),
            _SettingToggleRow(
              label: l.isAr ? 'تفعيل الإشعارات الذكية' : 'Smart Notifications',
              value: true,
            ),
            _SettingToggleRow(
              label: l.isAr ? 'الوضع المظلم التلقائي' : 'Automatic Dark Mode',
              value: false,
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateUserSheet(BuildContext context, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateUserSheet(role: role),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final String adminName;
  final VoidCallback onLogout;

  const _AdminProfileCard({
    required this.adminName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AppColors.primary,
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adminName, style: AppText.h4),
                const SizedBox(height: 3),
                Text(
                  l.isAr ? 'مدير النظام' : 'System Administrator',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemNumbers extends StatelessWidget {
  final bool isAr;
  final AdminStats stats;
  final int? techniciansCount;
  final int? devicesCount;
  final int? locationsCount;

  const _SystemNumbers({
    required this.isAr,
    required this.stats,
    required this.techniciansCount,
    required this.devicesCount,
    required this.locationsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniSystemCard(
            label: isAr ? 'الأجهزة' : 'Devices',
            value: (devicesCount ?? stats.totalDevices).toString(),
            icon: Icons.devices_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniSystemCard(
            label: isAr ? 'الفنيون' : 'Techs',
            value: (techniciansCount ?? stats.totalTechnicians).toString(),
            icon: Icons.engineering_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniSystemCard(
            label: isAr ? 'المواقع' : 'Locations',
            value: (locationsCount ?? 0).toString(),
            icon: Icons.place_rounded,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _MiniSystemCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniSystemCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppText.h3.copyWith(color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class _RoleActionCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleActionCard({
    required this.title,
    required this.desc,
    required this.icon,
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyMed.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(desc, style: AppText.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackendDataCard extends StatelessWidget {
  final bool isAr;
  final AsyncValue<List<TechnicianModel>> technicians;
  final AsyncValue<List<LocationModel>> locations;
  final AsyncValue<List<AdminDeviceModel>> devices;
  final VoidCallback onRefresh;

  const _BackendDataCard({
    required this.isAr,
    required this.technicians,
    required this.locations,
    required this.devices,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final loading = technicians.isLoading || locations.isLoading || devices.isLoading;
    final error = technicians.hasError || locations.hasError || devices.hasError;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: AppColors.success),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  isAr ? 'حالة الاتصال بالباك إند' : 'Backend Connection State',
                  style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const LinearProgressIndicator()
          else if (error)
            Text(
              isAr
                  ? 'في مشكلة في تحميل بعض بيانات النظام من الباك إند.'
                  : 'Some backend data failed to load.',
              style: AppText.caption.copyWith(color: AppColors.error),
            )
          else
            Text(
              isAr
                  ? 'البيانات متصلة وتُقرأ مباشرة من الباك إند.'
                  : 'Data is connected and read directly from backend.',
              style: AppText.caption.copyWith(color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

class _SettingToggleRow extends StatefulWidget {
  final String label;
  final bool value;

  const _SettingToggleRow({
    required this.label,
    required this.value,
  });

  @override
  State<_SettingToggleRow> createState() => _SettingToggleRowState();
}

class _SettingToggleRowState extends State<_SettingToggleRow> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(widget.label, style: AppText.body)),
          Switch(
            value: value,
            onChanged: (v) => setState(() => value = v),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  final String role;

  const _CreateUserSheet({required this.role});

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final fullName = _name.text.trim();
    final email = _email.text.trim();
    final username = _username.text.trim().isEmpty ? email : _username.text.trim();
    final password = _password.text.trim();
    final phone = _phone.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.length < 6) {
      _showSnack(
        l.isAr
            ? 'اكتبي الاسم والإيميل وكلمة مرور ٦ أحرف على الأقل'
            : 'Enter name, email and a password of at least 6 characters',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = ref.read(apiDioProvider);

      final payload = <String, dynamic>{
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
        'role': widget.role,
        'roleName': widget.role,
        'phone': phone.isEmpty ? null : phone,
        'isActive': true,
        'status': 'ACTIVE',
      };

      await _postWithFallback(dio, payload);

      ref.invalidate(techniciansProvider);
      ref.invalidate(activeTechniciansProvider);
      ref.invalidate(adminStatsProvider);

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        l.isAr ? 'تم إنشاء الحساب بنجاح' : 'Account created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        '${l.isAr ? 'فشل إنشاء الحساب' : 'Failed to create account'}: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postWithFallback(Dio dio, Map<String, dynamic> payload) async {
    final endpoints = <String>[
      '/users',
      '/users/create',
      '/auth/register',
      '/auth/create-user',
    ];

    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        await dio.post(endpoint, data: payload);
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Unknown backend error';
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceGrey,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminSheetHandle(),
              Text(
                l.isAr
                    ? 'إنشاء حساب ${widget.role}'
                    : 'Create ${widget.role} User',
                style: AppText.h4,
              ),
              const SizedBox(height: 22),
              AdminFormField(
                ctrl: _name,
                label: l.isAr ? 'الاسم بالكامل' : 'Full Name',
              ),
              const SizedBox(height: 12),
              AdminFormField(
                ctrl: _email,
                label: l.isAr ? 'البريد الإلكتروني' : 'Email Address',
              ),
              const SizedBox(height: 12),
              AdminFormField(
                ctrl: _username,
                label: l.isAr ? 'اسم المستخدم اختياري' : 'Username Optional',
              ),
              const SizedBox(height: 12),
              AdminFormField(
                ctrl: _phone,
                label: l.isAr ? 'رقم الهاتف اختياري' : 'Phone Optional',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.isAr ? 'كلمة المرور' : 'Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_rounded),
                  label: Text(
                    l.isAr ? 'تأكيد إنشاء الحساب' : 'Provision Account',
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: AppText.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
