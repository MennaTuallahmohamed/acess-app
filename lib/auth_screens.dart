import 'package:access_track/app_constants.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';


// ═══════════════════════════════════════════════════════
//  SCREEN 0: ROLE SELECTION
// ═══════════════════════════════════════════════════════
class RoleSelectionScreen extends StatefulWidget {
  final Function(String) onRoleSelected;
  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onRoleSelected(role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // Title
              Text(
                'اختر دورك',
                style: AppText.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              )
              .animate(delay: 400.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text(
                'حدد الدور الذي تريد الدخول به',
                style: AppText.body.copyWith(color: Colors.white54),
                textAlign: TextAlign.center,
              )
              .animate(delay: 500.ms)
              .fadeIn(duration: 500.ms),

              const SizedBox(height: 48),

              // Roles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _RoleCard(
                      title: 'مدير النظام',
                      subtitle: 'إدارة المستخدمين والأجهزة',
                      icon: Icons.admin_panel_settings,
                      role: 'admin',
                      isSelected: _selectedRole == 'admin',
                      onTap: () => _selectRole('admin'),
                    )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2),

                    const SizedBox(height: 16),

                    _RoleCard(
                      title: 'مشاهد',
                      subtitle: 'عرض التقارير والإحصائيات',
                      icon: Icons.visibility,
                      role: 'viewer',
                      isSelected: _selectedRole == 'viewer',
                      onTap: () => _selectRole('viewer'),
                    )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    _RoleCard(
                      title: 'فني',
                      subtitle: 'إجراء التفتيش والصيانة',
                      icon: Icons.build,
                      role: 'technician',
                      isSelected: _selectedRole == 'technician',
                      onTap: () => _selectRole('technician'),
                    )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.2),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Version
              Text(
                AppStrings.version,
                style: AppText.caption.copyWith(color: Colors.white38),
              )
              .animate(delay: 1000.ms)
              .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h4.copyWith(color: isSelected ? AppColors.accent : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.small.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.accent, size: 24)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════
//  SCREEN 1: SPLASH
// ═══════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _ctrl.addListener(() => setState(() => _progress = _ctrl.value));
    _ctrl.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // Ministry name
              Text(
                AppStrings.ministry,
                style: AppText.h2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              )
              .animate(delay: 400.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text(
                AppStrings.republic,
                style: AppText.body.copyWith(color: Colors.white54),
              )
              .animate(delay: 500.ms)
              .fadeIn(duration: 500.ms),

              const SizedBox(height: 20),

              // Egypt flag colors bar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FlagStripe(color: const Color(0xFFCE1126), width: 40),
                  _FlagStripe(color: Colors.white.withOpacity(0.8), width: 40),
                  _FlagStripe(color: const Color(0xFF1A1A1A), width: 40),
                ],
              )
              .animate(delay: 600.ms)
              .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              Text(
                AppStrings.appName,
                style: AppText.body.copyWith(color: Colors.white70),
              )
              .animate(delay: 700.ms)
              .fadeIn(duration: 500.ms),

              const Spacer(flex: 2),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.version,
                      style: AppText.caption.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              )
              .animate(delay: 800.ms)
              .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagStripe extends StatelessWidget {
  final Color color;
  final double width;
  const _FlagStripe({required this.color, required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 2),
  );
}

// ═══════════════════════════════════════════════════════
//  SCREEN 2: LOGIN
// ═══════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  final String selectedRole;
  final Future<bool> Function(String email, String password, String role) onLogin;

  const LoginScreen({super.key, required this.selectedRole, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl  = TextEditingController(text: '');
  final _formKey   = GlobalKey<FormState>();

  bool _obscure    = true;
  bool _remember   = false;
  bool _loading    = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final ok = await widget.onLogin(_emailCtrl.text.trim(), _passCtrl.text, widget.selectedRole);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) setState(() => _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // White card bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.68,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.account_balance_rounded, size: 36, color: AppColors.primary),
                  )
                  .animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 16),

                  Text(AppStrings.appName, style: AppText.h3.copyWith(color: Colors.white))
                  .animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),

                  Text(AppStrings.forAuth, style: AppText.small.copyWith(color: Colors.white60))
                  .animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          _FieldLabel('البريد الإلكتروني'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'user@example.com',
                              prefixIcon: const Icon(Icons.email_rounded, color: AppColors.textHint, size: 20),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'أدخل البريد الإلكتروني' : null,
                          ),

                          const SizedBox(height: 20),

                          // Password
                          _FieldLabel(AppStrings.password),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textHint, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور قصيرة جداً' : null,
                          ),

                          const SizedBox(height: 16),

                          // Remember + Forgot
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _remember = !_remember),
                                child: Row(
                                  children: [
                                    Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v!)),
                                    Text(AppStrings.rememberMe, style: AppText.small),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(AppStrings.forgotPass, style: AppText.small.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_error!, style: AppText.small.copyWith(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Login button
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  )
                                : Text(AppStrings.login),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // SSL note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(AppStrings.sslNote, style: AppText.caption.copyWith(color: Colors.white54)),
                    ],
                  )
                  .animate(delay: 500.ms).fadeIn(),

                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.version} — ${AppStrings.ministry}',
                    style: AppText.caption.copyWith(color: Colors.white38),
                  )
                  .animate(delay: 550.ms).fadeIn(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.bodyMed,
    textAlign: TextAlign.right,
  );
}