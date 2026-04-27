import 'package:flutter/foundation.dart';

class ApiConstants {
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 60);

static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  return 'http://192.168.1.28:3000';
}

  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';
  static const logout = '/auth/logout';

  static const deviceByBarcode = '/devices/barcode';
  static const deviceById = '/devices';
  static const deviceSearch = '/devices/search';

  static const inspections = '/inspections';
  static const submitInspection = '/inspections';
  static const myInspections = '/inspections/my';

  static const reports = '/reports';
  static const reportById = '/reports';

  static const syncPush = '/sync/push';
  static const syncPull = '/sync/pull';

  static const profile = '/profile';
  static const monthlyStats = '/profile/stats/monthly';

  static const myTasks = '/inspection-tasks/my-tasks';
  static const myTaskHistory = '/inspection-tasks/my-history';

  // Admin endpoints
  static const adminUsers = '/users';
  static const adminTechnicians = '/users/technicians';
  static const activeTechnicians = '/users/technicians/active';

  static const adminTasks = '/inspection-tasks';
  static const adminTaskById = '/inspection-tasks';
  static const tasksByTechnician = '/inspection-tasks/technician';

  static const adminDevices = '/devices';
  static const adminLocations = '/locations';

  static const adminInspections = '/inspections';
  static const inspectionsByTechnician = '/inspections/technician';

  static const dashboardStats = '/dashboard/stats';
  static const dashboardAnalytics = '/dashboard/analytics';
}

class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const userData = 'user_data';
  static const rememberMe = 'remember_me';
  static const savedUsername = 'saved_username';
  static const lastSyncTime = 'last_sync_time';
  static const pendingReports = 'pending_reports';
  static const deviceCache = 'device_cache';
}

class HiveBoxes {
  static const pendingInspections = 'pending_inspections';
  static const cachedDevices = 'cached_devices';
  static const cachedReports = 'cached_reports';
  static const appSettings = 'app_settings';
}

enum DeviceStatus {
  good,
  needsMaintenance,
  underReview,
  faulty,
  maintenance,
}

enum DeviceType {
  computer,
  printer,
  camera,
  accessControl,
  projector,
  scanner,
  other,
}

enum InspectionResult {
  good,
  minorIssue,
  maintenance,
  faulty,
}

enum SyncStatus {
  synced,
  pending,
  failed,
}

enum UserRole {
  technician,
  supervisor,
  admin,
  military,
}

extension DeviceStatusExt on DeviceStatus {
  String get labelAr {
    switch (this) {
      case DeviceStatus.good:
        return 'سليم';
      case DeviceStatus.needsMaintenance:
        return 'يحتاج صيانة';
      case DeviceStatus.underReview:
        return 'قيد المراجعة';
      case DeviceStatus.faulty:
        return 'عطل';
      case DeviceStatus.maintenance:
        return 'تحت الصيانة';
    }
  }

  String get apiValue {
    switch (this) {
      case DeviceStatus.good:
        return 'good';
      case DeviceStatus.needsMaintenance:
        return 'maintenance';
      case DeviceStatus.underReview:
        return 'review';
      case DeviceStatus.faulty:
        return 'faulty';
      case DeviceStatus.maintenance:
        return 'under_maintenance';
    }
  }
}

extension DeviceTypeExt on DeviceType {
  String get labelAr {
    switch (this) {
      case DeviceType.computer:
        return 'حاسب آلي';
      case DeviceType.printer:
        return 'طابعة';
      case DeviceType.camera:
        return 'كاميرا مراقبة';
      case DeviceType.accessControl:
        return 'جهاز تحكم دخول';
      case DeviceType.projector:
        return 'بروجيكتور';
      case DeviceType.scanner:
        return 'ماسح ضوئي';
      case DeviceType.other:
        return 'أخرى';
    }
  }

  String get iconAsset {
    switch (this) {
      case DeviceType.computer:
        return 'assets/icons/computer.svg';
      case DeviceType.printer:
        return 'assets/icons/printer.svg';
      case DeviceType.camera:
        return 'assets/icons/camera.svg';
      case DeviceType.accessControl:
        return 'assets/icons/access.svg';
      case DeviceType.projector:
        return 'assets/icons/projector.svg';
      case DeviceType.scanner:
        return 'assets/icons/scanner.svg';
      case DeviceType.other:
        return 'assets/icons/device.svg';
    }
  }
}

extension InspectionResultExt on InspectionResult {
  String get labelAr {
    switch (this) {
      case InspectionResult.good:
        return 'سليم ويعمل بكفاءة';
      case InspectionResult.minorIssue:
        return 'يحتاج صيانة طفيفة';
      case InspectionResult.maintenance:
        return 'يحتاج صيانة عاجلة';
      case InspectionResult.faulty:
        return 'عطل كامل';
    }
  }

  String get apiValue {
    switch (this) {
      case InspectionResult.good:
        return 'good';
      case InspectionResult.minorIssue:
        return 'minor';
      case InspectionResult.maintenance:
        return 'maintenance';
      case InspectionResult.faulty:
        return 'faulty';
    }
  }
}

class AppStrings {
  static const appName = 'نظام التفتيش الميداني';
  static const ministry = 'وزارة التنمية المحلية';
  static const republic = 'جمهورية مصر العربية';
  static const version = 'الإصدار 3.0.0';

  static const employeeId = 'الرقم الوظيفي';
  static const password = 'كلمة المرور';
  static const login = 'تسجيل الدخول';
  static const logout = 'تسجيل الخروج';
  static const rememberMe = 'تذكرني';
  static const forgotPass = 'نسيت كلمة المرور؟';
  static const forAuth = 'للمفتشين المعتمدين فقط';
  static const sslNote = 'اتصال مشفر SSL/TLS';

  static const scanBarcode = 'مسح الباركود';
  static const pointCamera = 'وجّه الكاميرا نحو باركود الجهاز';
  static const orManual = 'أو';
  static const manualInput = 'إدخال رقم الجهاز يدوياً';
  static const searchDB = 'بحث في قاعدة البيانات';
  static const devicePlaceholder = 'EGY-CAI-XXXX';

  static const deviceDetails = 'تفاصيل الجهاز';
  static const deviceData = 'بيانات الجهاز';
  static const deviceType = 'النوع';
  static const location = 'الموقع';
  static const maintenanceStatus = 'حالة الصيانة';
  static const lastInspection = 'آخر تفتيش';
  static const inspector = 'المفتش';
  static const deviceLocation = 'موقع الجهاز';
  static const startInspection = 'بدء التفتيش الآن';

  static const inspectionForm = 'نموذج التفتيش';
  static const deviceCondition = 'حالة الجهاز';
  static const notes = 'الملاحظات';
  static const devicePhoto = 'صورة الجهاز';
  static const locationTime = 'الموقع والوقت — تسجيل تلقائي';
  static const sendReport = 'إرسال تقرير التفتيش';

  static const reportSent = 'تم إرسال التقرير بنجاح!';
  static const reportSavedNote =
      'تم حفظ تقرير التفتيش وتحديث حالة الجهاز في قاعدة البيانات الوزارية';
  static const reportSummary = 'ملخص التقرير';
  static const scanAnother = 'مسح جهاز آخر';
  static const backHome = 'العودة للرئيسية';

  static const reportsLog = 'سجل التقارير';
  static const searchReports = 'بحث في التقارير...';

  static const myProfile = 'حسابي';
  static const personalData = 'بياناتي الشخصية';
  static const notifications = 'إعدادات الإشعارات';
  static const security = 'الأمان وكلمة المرور';
  static const monthlyReports = 'تقاريري الشهرية';
  static const totalInspections = 'إجمالي الفحوصات';
  static const thisMonth = 'هذا الشهر';
  static const completionRate = 'معدل الإنجاز';

  static const syncTitle = 'المزامنة مع الخادم';
  static const connected = 'متصل بالخادم الوزاري';
  static const syncNow = 'مزامنة الآن';
  static const offlineMode = 'وضع عدم الاتصال';
  static const offlineNote =
      'يمكنك متابعة التفتيش بدون إنترنت، سيتم رفع التقارير تلقائياً عند الاتصال بالشبكة';

  static const navHome = 'الرئيسية';
  static const navReports = 'التقارير';
  static const navSync = 'مزامنة';
  static const navProfile = 'حسابي';

  static const today = 'اليوم';
  static const yesterday = 'أمس';
  static const reportNumber = 'رقم التقرير';
  static const device = 'الجهاز';
  static const status = 'الحالة';
  static const coordinates = 'الإحداثيات';
  static const loading = 'جاري التحميل...';
  static const error = 'حدث خطأ';
  static const retry = 'إعادة المحاولة';
  static const cancel = 'إلغاء';
  static const confirm = 'تأكيد';
  static const save = 'حفظ';
}