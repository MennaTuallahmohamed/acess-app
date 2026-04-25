import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();
  bool get isAr => locale.languageCode == 'ar';

  // App
  String get appName      => isAr ? 'نظام التفتيش الميداني'    : 'Field Inspection System';
  String get ministry     => isAr ? 'وزارة التنمية المحلية'     : 'Ministry of Local Development';
  String get republic     => isAr ? 'جمهورية مصر العربية'       : 'Arab Republic of Egypt';
  String get version      => isAr ? 'الإصدار 3.0.0'             : 'Version 3.0.0';
  String get forAuth      => isAr ? 'للمفتشين المعتمدين فقط'    : 'Authorized Inspectors Only';
  String get sslNote      => isAr ? 'اتصال مشفر SSL/TLS'        : 'Encrypted SSL/TLS Connection';

  // Auth
  String get employeeId   => isAr ? 'الرقم الوظيفي'   : 'Employee ID';
  String get password     => isAr ? 'كلمة المرور'     : 'Password';
  String get login        => isAr ? 'تسجيل الدخول'    : 'Sign In';
  String get logout       => isAr ? 'تسجيل الخروج'    : 'Sign Out';
  String get rememberMe   => isAr ? 'تذكرني'           : 'Remember me';
  String get forgotPass   => isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get loginError   => isAr ? 'الرقم الوظيفي أو كلمة المرور غير صحيحة' : 'Incorrect employee ID or password';

  // Navigation
  String get navHome      => isAr ? 'الرئيسية'  : 'Home';
  String get navReports   => isAr ? 'التقارير'   : 'Reports';
  String get navSync      => isAr ? 'مزامنة'     : 'Sync';
  String get navProfile   => isAr ? 'حسابي'      : 'Profile';

  // Home
  String get todayStats   => isAr ? 'إحصائيات اليوم'         : "Today's Stats";
  String get recentInsp   => isAr ? 'آخر التفتيشات'           : 'Recent Inspections';
  String get viewAll      => isAr ? 'عرض الكل'               : 'View All';
  String get scanDevice   => isAr ? 'مسح جهاز'               : 'Scan Device';
  String get noInspToday  => isAr ? 'لا توجد تفتيشات اليوم'  : 'No inspections today';
  String get startScan    => isAr ? 'اضغط "مسح جهاز" لبدء التفتيش' : 'Tap "Scan Device" to start';
  String greeting() {
    final h = DateTime.now().hour;
    if (isAr) { if (h < 12) return 'صباح الخير'; if (h < 17) return 'مساء الخير'; return 'مساء النور'; }
    else       { if (h < 12) return 'Good Morning'; if (h < 17) return 'Good Afternoon'; return 'Good Evening'; }
  }

  // Status labels
  String get statusGood    => isAr ? 'سليم'         : 'Good';
  String get statusMaint   => isAr ? 'صيانة'        : 'Maintenance';
  String get statusReview  => isAr ? 'قيد المراجعة' : 'Under Review';
  String get statusFaulty  => isAr ? 'عطل'          : 'Faulty';
  String get statusMinor   => isAr ? 'صيانة طفيفة'  : 'Minor Issue';
  String get statusPending => isAr ? 'معلق'          : 'Pending';
  String statusLabel(String s) {
    switch (s) {
      case 'good':        return statusGood;
      case 'maintenance': return statusMaint;
      case 'review':      return statusReview;
      case 'faulty':      return statusFaulty;
      case 'minor':       return statusMinor;
      default:            return statusPending;
    }
  }

  // Scan
  String get scanTitle    => isAr ? 'مسح الباركود'                    : 'Scan Barcode';
  String get pointCamera  => isAr ? 'وجّه الكاميرا نحو باركود الجهاز' : 'Point camera at device barcode';
  String get orManual     => isAr ? 'أو'                              : 'or';
  String get manualInput  => isAr ? 'إدخال رقم الجهاز يدوياً'         : 'Enter device number manually';
  String get searchDB     => isAr ? 'بحث في قاعدة البيانات'           : 'Search Database';

  // Device
  String get deviceDetails => isAr ? 'تفاصيل الجهاز'     : 'Device Details';
  String get deviceData    => isAr ? 'بيانات الجهاز'      : 'Device Info';
  String get deviceType    => isAr ? 'النوع'              : 'Type';
  String get location      => isAr ? 'الموقع'             : 'Location';
  String get lastInspDate  => isAr ? 'آخر تفتيش'          : 'Last Inspection';
  String get inspector     => isAr ? 'المفتش'             : 'Inspector';
  String get startInsp     => isAr ? 'بدء التفتيش الآن'   : 'Start Inspection Now';

  // Inspection Form
  String get inspForm     => isAr ? 'نموذج التفتيش'                   : 'Inspection Form';
  String get deviceCond   => isAr ? 'حالة الجهاز'                     : 'Device Condition';
  String get notes        => isAr ? 'الملاحظات'                       : 'Notes';
  String get devicePhoto  => isAr ? 'صورة الجهاز'                     : 'Device Photo';
  String get locationTime => isAr ? 'الموقع والوقت — تسجيل تلقائي'   : 'Location & Time — Auto Recorded';
  String get sendReport   => isAr ? 'إرسال تقرير التفتيش'             : 'Submit Inspection Report';
  String get condGood     => isAr ? 'سليم ويعمل بكفاءة'               : 'Good & Working Efficiently';
  String get condMinor    => isAr ? 'يحتاج صيانة طفيفة'               : 'Needs Minor Maintenance';
  String get condMaint    => isAr ? 'يحتاج صيانة عاجلة'               : 'Needs Urgent Maintenance';
  String get condFaulty   => isAr ? 'عطل كامل'                        : 'Complete Failure';
  String get selectStatus => isAr ? 'يرجى تحديد حالة الجهاز'         : 'Please select device condition';
  String get tapPhoto     => isAr ? 'اضغط لالتقاط صورة'              : 'Tap to take photo';
  String get gpsActive    => isAr ? 'GPS نشط'                         : 'GPS Active';
  String get locating     => isAr ? 'جاري تحديد الموقع...'            : 'Locating...';

  // Inspection Steps
  String get stepScan     => isAr ? 'المسح'    : 'Scan';
  String get stepDetails  => isAr ? 'التفاصيل' : 'Details';
  String get stepInspect  => isAr ? 'التفتيش'  : 'Inspect';
  String get stepSend     => isAr ? 'الإرسال'  : 'Submit';
  List<String> get stepLabels => [stepScan, stepDetails, stepInspect, stepSend];

  // Success
  String get reportSent   => isAr ? '!تم إرسال التقرير بنجاح'        : 'Report Submitted!';
  String get reportNote   => isAr
      ? 'تم حفظ تقرير التفتيش وتحديث حالة الجهاز في قاعدة البيانات الوزارية'
      : 'Inspection report saved and device status updated in the ministry database';
  String get reportSummary => isAr ? 'ملخص التقرير'     : 'Report Summary';
  String get scanAnother   => isAr ? 'مسح جهاز آخر'     : 'Scan Another Device';
  String get backHome      => isAr ? 'العودة للرئيسية'   : 'Back to Home';
  String get reportNum     => isAr ? 'رقم التقرير'       : 'Report Number';
  String get device        => isAr ? 'الجهاز'            : 'Device';
  String get status        => isAr ? 'الحالة'            : 'Status';
  String get coordinates   => isAr ? 'الإحداثيات'        : 'Coordinates';

  // Reports
  String get reportsLog   => isAr ? 'سجل التقارير'        : 'Reports Log';
  String get searchRpts   => isAr ? 'بحث في التقارير...'  : 'Search reports...';
  String get filterAll    => isAr ? 'الكل'    : 'All';
  String get filterGood   => isAr ? 'سليم'    : 'Good';
  String get filterFaulty => isAr ? 'عطل'     : 'Faulty';
  String get filterMaint  => isAr ? 'صيانة'   : 'Maint.';
  String get filterToday  => isAr ? 'اليوم'   : 'Today';
  String get filterWeek   => isAr ? 'الأسبوع' : 'Week';
  String get filterMonth  => isAr ? 'الشهر'   : 'Month';
  String get filterYear   => isAr ? 'السنة'   : 'Year';
  String get noResults    => isAr ? 'لا توجد نتائج'                  : 'No results found';
  String get tryFilter    => isAr ? 'جرب تغيير الفلتر أو البحث'     : 'Try changing filter or search';
  String get todayLbl     => isAr ? 'اليوم'   : 'Today';
  String get yesterdayLbl => isAr ? 'أمس'     : 'Yesterday';

  // Monthly Reports
  String get monthlyReports  => isAr ? 'تقاريري الشهرية'              : 'My Monthly Reports';
  String get monthlyOverview => isAr ? 'نظرة عامة'                    : 'Overview';
  String get inspByStatus    => isAr ? 'التفتيشات حسب الحالة'         : 'Inspections by Status';
  String get inspByType      => isAr ? 'التفتيشات حسب نوع الجهاز'    : 'Inspections by Device Type';
  String get allTasks        => isAr ? 'جميع المهام'                   : 'All Tasks';
  String get taskDetails     => isAr ? 'تفاصيل المهمة'                : 'Task Details';
  String get totalInspected  => isAr ? 'إجمالي الفحوصات'              : 'Total Inspections';
  String get completionRate  => isAr ? 'معدل الإنجاز'                  : 'Completion Rate';
  String get avgPerDay       => isAr ? 'متوسط يومي'                   : 'Daily Average';
  String get reportId        => isAr ? 'رقم التقرير'                   : 'Report ID';
  String get deviceName      => isAr ? 'اسم الجهاز'                   : 'Device Name';
  String get deviceCode      => isAr ? 'كود الجهاز'                    : 'Device Code';
  String get inspDate        => isAr ? 'تاريخ التفتيش'                : 'Inspection Date';
  String get inspTime        => isAr ? 'وقت التفتيش'                   : 'Inspection Time';
  String get inspLocation    => isAr ? 'موقع التفتيش'                 : 'Inspection Location';
  String get inspResult      => isAr ? 'نتيجة التفتيش'                : 'Inspection Result';
  String get notesLbl        => isAr ? 'الملاحظات'                     : 'Notes';
  String get noNotes         => isAr ? 'لا توجد ملاحظات'              : 'No notes';
  String get gpsCoords       => isAr ? 'إحداثيات GPS'                  : 'GPS Coordinates';
  String get submittedAt     => isAr ? 'وقت الإرسال'                  : 'Submitted At';
  // FIX: regular method, not getter with param
  String monthLabel(int m) {
    const ar = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    const en = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return isAr ? ar[m - 1] : en[m - 1];
  }
  String get exportPdf       => isAr ? 'تصدير PDF' : 'Export PDF';
  String get shareReport     => isAr ? 'مشاركة'    : 'Share';
  String get back            => isAr ? 'رجوع'      : 'Back';

  // Profile
  String get myProfile       => isAr ? 'حسابي'                        : 'My Account';
  String get personalData    => isAr ? 'بياناتي الشخصية'              : 'Personal Info';
  String get notifSettings   => isAr ? 'إعدادات الإشعارات'            : 'Notification Settings';
  String get security        => isAr ? 'الأمان وكلمة المرور'          : 'Security & Password';
  String get thisMonth       => isAr ? 'هذا الشهر'                    : 'This Month';
  String get totalInsp       => isAr ? 'إجمالي الفحوصات'              : 'Total Inspections';
  String get language        => isAr ? 'اللغة'                        : 'Language';
  String get arabic          => isAr ? 'العربية'                      : 'Arabic';
  String get english         => isAr ? 'الإنجليزية'                   : 'English';
  String get employeeIdLbl   => isAr ? 'رقم وظيفي'                   : 'Employee ID';
  String get settings        => isAr ? 'الإعدادات'                    : 'Settings';

  // Personal Data page
  String get fullName        => isAr ? 'الاسم الكامل'                 : 'Full Name';
  String get nationalId      => isAr ? 'الرقم القومي'                 : 'National ID';
  String get phone           => isAr ? 'رقم الهاتف'                   : 'Phone Number';
  String get email           => isAr ? 'البريد الإلكتروني'            : 'Email';
  String get regionLbl       => isAr ? 'المنطقة'                      : 'Region';
  String get departmentLbl   => isAr ? 'الإدارة'                      : 'Department';
  String get jobTitle        => isAr ? 'المسمى الوظيفي'               : 'Job Title';
  String get hireDate        => isAr ? 'تاريخ التعيين'                : 'Hire Date';
  String get editProfile     => isAr ? 'تعديل البيانات'               : 'Edit Profile';
  String get saveChanges     => isAr ? 'حفظ التغييرات'                : 'Save Changes';

  // Settings page
  String get appSettings     => isAr ? 'إعدادات التطبيق'              : 'App Settings';
  String get notifPush       => isAr ? 'إشعارات الدفع'                : 'Push Notifications';
  String get notifTasks      => isAr ? 'إشعارات المهام'               : 'Task Notifications';
  String get notifAlerts     => isAr ? 'إشعارات التنبيهات'            : 'Alert Notifications';
  String get notifSync       => isAr ? 'إشعارات المزامنة'             : 'Sync Notifications';
  String get autoSync        => isAr ? 'مزامنة تلقائية'               : 'Auto Sync';
  String get autoSyncNote    => isAr ? 'رفع التقارير تلقائياً عند الاتصال' : 'Auto-upload reports when connected';
  String get darkMode        => isAr ? 'الوضع الداكن'                 : 'Dark Mode';
  String get fontSize        => isAr ? 'حجم الخط'                     : 'Font Size';
  String get clearCache      => isAr ? 'مسح ذاكرة التخزين المؤقت'    : 'Clear Cache';
  String get cacheSize       => isAr ? 'حجم الكاش'                   : 'Cache Size';
  String get appVersion      => isAr ? 'إصدار التطبيق'                : 'App Version';
  String get privacyPolicy   => isAr ? 'سياسة الخصوصية'               : 'Privacy Policy';
  String get termsOfUse      => isAr ? 'شروط الاستخدام'               : 'Terms of Use';
  String get changePassword  => isAr ? 'تغيير كلمة المرور'            : 'Change Password';
  String get currentPass     => isAr ? 'كلمة المرور الحالية'          : 'Current Password';
  String get newPass         => isAr ? 'كلمة المرور الجديدة'           : 'New Password';
  String get confirmPass     => isAr ? 'تأكيد كلمة المرور'            : 'Confirm Password';
  String get enabled         => isAr ? 'مفعّل'    : 'Enabled';
  String get disabled        => isAr ? 'معطّل'    : 'Disabled';
  String get general         => isAr ? 'عام'       : 'General';
  String get security2       => isAr ? 'الأمان'    : 'Security';
  String get about           => isAr ? 'حول التطبيق' : 'About';

  // Notifications
  String get notifications   => isAr ? 'الإشعارات'         : 'Notifications';
  String get markAllRead     => isAr ? 'تعيين الكل كمقروء' : 'Mark All Read';
  String get noNotifs        => isAr ? 'لا توجد إشعارات'   : 'No notifications';
  String get notifNew        => isAr ? 'جديد'    : 'New';
  String get notifSystem     => isAr ? 'النظام'  : 'System';
  String get notifTask       => isAr ? 'مهام'    : 'Tasks';
  String get notifAlert      => isAr ? 'تنبيهات' : 'Alerts';
  String get justNow         => isAr ? 'الآن'    : 'Just now';
  // FIX: regular methods, not getters with params
  String minAgo(int m)       => isAr ? 'منذ $m دقيقة' : '${m}m ago';
  String hourAgo(int h)      => isAr ? 'منذ $h ساعة'  : '${h}h ago';

  // Sync
  String get syncTitle       => isAr ? 'المزامنة مع الخادم'    : 'Server Sync';
  String get connected       => isAr ? 'متصل بالخادم الوزاري'  : 'Connected to Ministry Server';
  String get syncNow         => isAr ? 'مزامنة الآن'           : 'Sync Now';
  String get offlineMode     => isAr ? 'وضع عدم الاتصال'       : 'Offline Mode';
  String get offlineNote     => isAr
      ? 'يمكنك متابعة التفتيش بدون إنترنت، سيتم رفع التقارير تلقائياً عند الاتصال بالشبكة'
      : 'You can continue inspection without internet. Reports will upload automatically when connected.';
  String get synced          => isAr ? 'تم رفعها' : 'Synced';
  String get waiting         => isAr ? 'انتظار'   : 'Waiting';
  String get failed          => isAr ? 'فشل'      : 'Failed';
  String get pending         => isAr ? 'في قائمة الانتظار' : 'Pending Queue';
  // FIX: regular method, not getter with param
  String lastSyncFmt(DateTime t) {
    final hm = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
    final ap = t.hour < 12 ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    return isAr ? 'آخر مزامنة: اليوم $hm $ap' : 'Last sync: Today $hm $ap';
  }

  // Common
  String get loading         => isAr ? 'جاري التحميل...' : 'Loading...';
  String get error           => isAr ? 'حدث خطأ'         : 'An error occurred';
  String get retry           => isAr ? 'إعادة المحاولة'  : 'Retry';
  String get cancel          => isAr ? 'إلغاء'           : 'Cancel';
  String get confirm         => isAr ? 'تأكيد'           : 'Confirm';
  String get save            => isAr ? 'حفظ'             : 'Save';
  String get supervisor      => isAr ? 'مفتش أول'        : 'Chief Inspector';
  String get technicianRole  => isAr ? 'مفتش'            : 'Inspector';
  String get adminRole       => isAr ? 'مدير النظام'     : 'System Admin';
  String get militaryRole    => isAr ? 'ضابط مراجعة'     : 'Review Officer';

  String get tasksDone => isAr ? 'المهام المنجزة' : 'Tasks Done';

  String get generalSummary => isAr ? 'ملخص عام' : 'General Summary';

  String get technicians => isAr ? 'المهندسين' : 'Technicians';

  String get tasksPending => isAr ? 'المهام المعلقة' : 'Pending Tasks';
  String get adminPanel => isAr ? 'لوحة الإدارة' : 'Admin Panel';
  String roleLabel(String r) {
    switch (r) {
      case 'supervisor': return supervisor;
      case 'admin':      return adminRole;
      case 'military':   return militaryRole;
      default:           return technicianRole;
    }
  }
  String deviceTypeLabel(String t) {
    if (isAr) {
      switch (t) {
        case 'computer':       return 'حاسب آلي مكتبي';
        case 'laptop':         return 'حاسب آلي محمول';
        case 'printer':        return 'طابعة';
        case 'camera':         return 'كاميرا مراقبة';
        case 'access_control': return 'جهاز تحكم دخول';
        case 'projector':      return 'بروجيكتور';
        default:               return 'جهاز آخر';
      }
    } else {
      switch (t) {
        case 'computer':       return 'Desktop PC';
        case 'laptop':         return 'Laptop';
        case 'printer':        return 'Printer';
        case 'camera':         return 'Surveillance Camera';
        case 'access_control': return 'Access Control Device';
        case 'projector':      return 'Projector';
        default:               return 'Other Device';
      }
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale l)   => ['ar','en'].contains(l.languageCode);
  @override Future<AppLocalizations> load(Locale l) async => AppLocalizations(l);
  @override bool shouldReload(_)         => false;
}

// Language controller
class LanguageController extends StatefulWidget {
  final Widget child;
  const LanguageController({super.key, required this.child});

  @override
  State<LanguageController> createState() => LanguageControllerState();

  static LanguageControllerState of(BuildContext context) =>
      context.findAncestorStateOfType<LanguageControllerState>()!;
}

class LanguageControllerState extends State<LanguageController> {
  Locale _locale = const Locale('ar', 'EG');
  Locale get locale => _locale;

  void setLocale(Locale l) => setState(() => _locale = l);
  void toggleLanguage() => setLocale(
    _locale.languageCode == 'ar' ? const Locale('en','US') : const Locale('ar','EG'),
  );

  @override
  Widget build(BuildContext context) => widget.child;
}