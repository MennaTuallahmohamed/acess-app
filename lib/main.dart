import 'package:access_track/admin/admin_dashboard.dart';
import 'package:access_track/admin/admin_shell.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/auth_screens.dart';
import 'package:access_track/core/api/app_providers.dart';
import 'package:access_track/core/api/technician_repository.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:access_track/home_screen.dart';
import 'package:access_track/inspection_screens.dart';
import 'package:access_track/monthly_reports_screen.dart';
import 'package:access_track/notifications_screen.dart';
import 'package:access_track/profile_pages.dart';
import 'package:access_track/remaining_screens.dart'
    show ReportsScreen, SyncScreen;
import 'package:access_track/scan_screens.dart';
import 'package:access_track/viewer/viewer_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('device_cache');
  await Hive.openBox('pending_inspections');
  await Hive.openBox('app_settings');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: _RootApp()));
}

class _RootApp extends StatefulWidget {
  const _RootApp();

  @override
  State<_RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<_RootApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return LanguageController(
      child: Builder(
        builder: (context) {
          final locale = LanguageController.of(context).locale;
          final isAr = locale.languageCode == 'ar';

          return MaterialApp(
            title: 'Field Inspection System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            navigatorKey: navigatorKey,
            locale: locale,
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _AppShell(),
          );
        },
      ),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _splashDone = false;
  int _navIndex = 0;
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onFinished: () {
          if (!mounted) return;
          setState(() => _splashDone = true);
        },
      );
    }

    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = authState.valueOrNull;

    if (currentUser == null) {
      if (_selectedRole == null) {
        return RoleSelectionScreen(
          onRoleSelected: (role) {
            if (!mounted) return;
            setState(() => _selectedRole = role);
          },
        );
      }

      return LoginScreen(
        selectedRole: _selectedRole!,
        onLogin: _handleLogin,
      );
    }

    return _routeByRole(
      currentUser,
      selectedRole: _selectedRole,
    );
  }

  Future<bool> _handleLogin(
    String email,
    String password,
    String role,
  ) async {
    final ok = await ref.read(authProvider.notifier).login(
          email,
          password,
          role,
        );

    if (ok && mounted) {
      setState(() {
        _selectedRole = role;
        _navIndex = 0;
      });
    }

    return ok;
  }

  void _logout() {
    setState(() {
      _selectedRole = null;
      _navIndex = 0;
    });

    ref.read(authProvider.notifier).logout();
  }

  Widget _routeByRole(
    UserModel user, {
    String? selectedRole,
  }) {
    final backendRole = user.role.trim().toLowerCase();
    final uiSelectedRole = selectedRole?.trim().toLowerCase() ?? '';

    final effectiveRole =
        uiSelectedRole.isNotEmpty ? uiSelectedRole : backendRole;

    if (effectiveRole == 'admin' || effectiveRole == 'supervisor') {
      return AdminMainShell(
        adminName: user.name,
        onLogout: _logout,
      );
    }

    if (effectiveRole == 'viewer') {
      return ViewerDashboardScreen(
        viewerName: user.name,
        onLogout: _logout,
      );
    }

    return _TechnicianShell(
      user: user,
      navIndex: _navIndex,
      onLogout: _logout,
      onNavChange: (index) {
        if (index == 2) {
          _openScan();
          return;
        }

        if (!mounted) return;

        setState(() => _navIndex = index);
      },
      onScan: _openScan,
    );
  }

  void _openScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ScanBarcodeScreen(
            recentScans: const [],

            /*
              QR Scan:
              لازم QR يكون شايل secretCode فقط.
              هنا بنضرب:
              GET /devices/scan/:secretCode
            */
            onBarcodeScanned: (secretCode) async {
              try {
                final device = await ref
                    .read(technicianRepositoryProvider)
                    .getDeviceBySecretCode(secretCode);

                if (!mounted) return false;

                Navigator.pop(context);

                _openDeviceDetails(device);

                return true;
              } catch (error) {
                debugPrint('QR SECRET CODE SCAN ERROR: $error');
                return false;
              }
            },

            /*
              Manual Search:
              ده مش هيفتح غير بعد 3 محاولات QR فاشلة.
              بيدعم:
              IP / Device Code / Serial Number / Barcode
            */
            onManualSearch: (code) async {
              final device = await ref
                  .read(technicianRepositoryProvider)
                  .searchDeviceManual(code);

              if (!mounted) return;

              Navigator.pop(context);

              _openDeviceDetails(device);
            },

            /*
              Audit:
              تسجيل محاولات QR في الباك إند.
            */
            onQrAttemptLogged: ({
              required scannedCode,
              required success,
              required attemptNumber,
              reason,
            }) async {
              await ref.read(technicianRepositoryProvider).logQrScanAttempt(
                    scannedCode: scannedCode,
                    success: success,
                    attemptNumber: attemptNumber,
                    reason: reason,
                  );
            },
          );
        },
      ),
    );
  }

  void _openDeviceDetails(DeviceModel device) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return DeviceDetailsScreen(
            device: device,
            onBack: () => Navigator.pop(context),
            onStartInspection: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => _buildInspectionForm(device),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openDeviceFromCode(String code) async {
    try {
      final device = await ref
          .read(technicianRepositoryProvider)
          .searchDeviceManual(code);

      if (!mounted) return;

      _openDeviceDetails(device);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على الجهاز'),
        ),
      );
    }
  }

  Widget _buildInspectionForm(DeviceModel device) {
    final user = ref.read(currentUserProvider);

    return InspectionFormScreen(
      device: device,
      currentUserId: user?.id ?? '1',
      onBack: () => Navigator.pop(context),
      onSubmit: (draft) async {
        final currentUser = ref.read(currentUserProvider);

        if (currentUser == null) {
          return 'يجب تسجيل الدخول أولاً';
        }

        try {
          final result = await ref
              .read(inspectionSubmitProvider.notifier)
              .submit(draft);

          if (!mounted) return null;

          ref.invalidate(technicianReportsProvider);
          ref.invalidate(allReportsProvider);
          ref.invalidate(todayStatsProvider);
          ref.invalidate(recentInspectionsProvider);

          Future.microtask(() {
            ref.read(syncProvider.notifier).syncNow();
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                return InspectionSuccessScreen(
                  reportNumber: result.reportNumber,
                  deviceName: device.name,
                  result: draft.result,
                  inspectorName: currentUser.name,
                  lat: draft.latitude,
                  lng: draft.longitude,
                  onScanAnother: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    _openScan();
                  },
                  onGoHome: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    if (!mounted) return;
                    setState(() => _navIndex = 0);
                  },
                );
              },
            ),
          );

          return null;
        } catch (error) {
          return error.toString().replaceFirst('Exception: ', '');
        }
      },
    );
  }
}

class _TechnicianShell extends ConsumerWidget {
  final UserModel user;
  final int navIndex;
  final VoidCallback onLogout;
  final ValueChanged<int> onNavChange;
  final VoidCallback onScan;

  const _TechnicianShell({
    required this.user,
    required this.navIndex,
    required this.onLogout,
    required this.onNavChange,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todayStatsProvider).valueOrNull ??
        const TodayStats(
          totalInspected: 0,
          good: 0,
          needsMaintenance: 0,
          underReview: 0,
        );

    final reports = ref.watch(allReportsProvider).valueOrNull ?? [];

    final recentReports =
        ref.watch(recentInspectionsProvider).valueOrNull ??
            reports.take(5).toList();

    final syncStatus = ref.watch(syncProvider);

    late final Widget screen;

    switch (navIndex) {
      case 0:
        screen = HomeScreen(
          user: user,
          stats: stats,
          recentReports: recentReports,
          onScan: onScan,
          onReportTap: (_) {},
          onSeeAllReports: () => onNavChange(1),
          onNotifications: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        );
        break;

      case 1:
        screen = ReportsScreen(
          reports: reports,
          onReportTap: (_) {},
        );
        break;

      case 3:
        screen = SyncScreen(
          status: syncStatus,
          onSync: () => ref.read(syncProvider.notifier).syncNow(),
        );
        break;

      case 4:
        screen = ProfileScreen(
          user: user,
          onLogout: onLogout,
          onPersonalData: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalDataScreen(user: user),
              ),
            );
          },
          onNotifications: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          onSecurity: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
          onMonthlyReports: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthlyReportsScreen(
                  reports: reports,
                  inspectorName: user.name,
                  region: user.region,
                ),
              ),
            );
          },
        );
        break;

      default:
        screen = HomeScreen(
          user: user,
          stats: stats,
          recentReports: recentReports,
          onScan: onScan,
          onReportTap: (_) {},
          onSeeAllReports: () => onNavChange(1),
          onNotifications: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        );
    }

    return Scaffold(
      body: screen,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navIndex == 2 ? 0 : navIndex,
        onTap: onNavChange,
      ),
    );
  }
}