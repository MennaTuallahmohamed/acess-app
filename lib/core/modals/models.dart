import 'package:hive/hive.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String region;
  final String? avatarUrl;
  final int totalInspections;
  final int monthInspections;
  final double completionRate;
  final String token;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.region,
    this.avatarUrl,
    this.totalInspections = 0,
    this.monthInspections = 0,
    this.completionRate = 0.0,
    required this.token,
  });

  String get displayRole {
    switch (role) {
      case 'supervisor':
        return 'مفتش أول';
      case 'technician':
        return 'فني';
      case 'admin':
        return 'مدير النظام';
      case 'viewer':
        return 'مشاهد';
      case 'military':
        return 'ضابط مراجعة';
      default:
        return 'مفتش';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['fullName']?.toString() ??
            json['name']?.toString() ??
            '',
        role: json['role']?.toString() ?? '',
        region: json['region']?.toString() ?? '',
        avatarUrl: json['avatar_url']?.toString(),
        totalInspections: json['total_inspections'] as int? ?? 0,
        monthInspections: json['month_inspections'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
        token: json['token']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'region': region,
        'avatar_url': avatarUrl,
        'total_inspections': totalInspections,
        'month_inspections': monthInspections,
        'completion_rate': completionRate,
        'token': token,
      };
}

class DeviceModel {
  final String id;
  final String code;
  final String name;
  final String type;
  final String brand;
  final String barcode;
  final String serialNumber;
  final String ipAddress;
  final String firmware;
  final String modelNumber;
  final String notes;
  final String location;
  final String building;
  final String floor;
  final String room;
  final String status;
  final String? lastInspectorName;
  final DateTime? lastInspectionDate;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  final int? backendDeviceTypeId;
  final String? backendDeviceTypeName;
  final String? backendCategoryName;

  const DeviceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.brand,
    this.barcode = '',
    this.serialNumber = '',
    this.ipAddress = '',
    this.firmware = '',
    this.modelNumber = '',
    this.notes = '',
    required this.location,
    required this.building,
    this.floor = '',
    this.room = '',
    required this.status,
    this.lastInspectorName,
    this.lastInspectionDate,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.backendDeviceTypeId,
    this.backendDeviceTypeName,
    this.backendCategoryName,
  });

  String get typeAr {
    final normalizedBackendType = (backendDeviceTypeName ?? '').toLowerCase();

    if (normalizedBackendType.contains('reader')) return 'قارئ دخول';
    if (normalizedBackendType.contains('controller')) return 'وحدة تحكم';
    if (normalizedBackendType.contains('morpho')) return 'جهاز مورفو';
    if (normalizedBackendType.contains('argus')) return 'بوابة Argus 60';

    switch (type) {
      case 'computer':
        return 'حاسب آلي مكتبي';
      case 'laptop':
        return 'حاسب آلي محمول';
      case 'printer':
        return 'طابعة';
      case 'camera':
        return 'كاميرا مراقبة';
      case 'access_control':
        return 'جهاز تحكم دخول';
      case 'projector':
        return 'بروجكتور';
      case 'scanner':
        return 'ماسح ضوئي';
      default:
        return 'جهاز آخر';
    }
  }

  String get statusAr {
    switch (status) {
      case 'good':
        return 'سليم';
      case 'maintenance':
        return 'صيانة';
      case 'review':
        return 'قيد المراجعة';
      case 'faulty':
        return 'عطل';
      default:
        return 'غير محدد';
    }
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        brand: json['brand']?.toString() ?? '',
        barcode: json['barcode']?.toString() ?? '',
        serialNumber: json['serial_number']?.toString() ?? '',
        ipAddress: json['ip_address']?.toString() ?? '',
        firmware: json['firmware']?.toString() ?? '',
        modelNumber: json['model_number']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        building: json['building']?.toString() ?? '',
        floor: json['floor']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        lastInspectorName: json['last_inspector_name']?.toString(),
        lastInspectionDate: json['last_inspection_date'] != null
            ? DateTime.tryParse(json['last_inspection_date'].toString())
            : null,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        imageUrl: json['image_url']?.toString(),
        backendDeviceTypeId: (json['backend_device_type_id'] as num?)?.toInt(),
        backendDeviceTypeName: json['backend_device_type_name']?.toString(),
        backendCategoryName: json['backend_category_name']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'type': type,
        'brand': brand,
        'barcode': barcode,
        'serial_number': serialNumber,
        'ip_address': ipAddress,
        'firmware': firmware,
        'model_number': modelNumber,
        'notes': notes,
        'location': location,
        'building': building,
        'floor': floor,
        'room': room,
        'status': status,
        'last_inspector_name': lastInspectorName,
        'last_inspection_date': lastInspectionDate?.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'backend_device_type_id': backendDeviceTypeId,
        'backend_device_type_name': backendDeviceTypeName,
        'backend_category_name': backendCategoryName,
      };
}

class InspectionIssueOption {
  final int id;
  final String issueCode;
  final String title;
  final String description;
  final String severity;
  final String status;
  final int categoryId;
  final int deviceTypeId;
  final String categoryName;
  final String deviceTypeName;
  final List<IssueSolutionModel> solutions;

  const InspectionIssueOption({
    required this.id,
    required this.issueCode,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.categoryId,
    required this.deviceTypeId,
    required this.categoryName,
    required this.deviceTypeName,
    this.solutions = const [],
  });

  factory InspectionIssueOption.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? {};
    final deviceType = json['deviceType'] as Map<String, dynamic>? ?? {};

    final rawSolutions = json['solutions'];
    final parsedSolutions = <IssueSolutionModel>[];

    if (rawSolutions is List) {
      for (final item in rawSolutions) {
        if (item is Map) {
          final solution = IssueSolutionModel.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (solution.id > 0) {
            parsedSolutions.add(solution);
          }
        }
      }
    }

    parsedSolutions.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return InspectionIssueOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      issueCode: json['issueCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'ACTIVE',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      deviceTypeId: (json['deviceTypeId'] as num?)?.toInt() ?? 0,
      categoryName: category['name']?.toString() ?? '',
      deviceTypeName: deviceType['name']?.toString() ?? '',
      solutions: parsedSolutions,
    );
  }
}

class IssueSolutionModel {
  final int id;
  final String solutionCode;
  final int issueId;
  final String title;
  final String description;
  final int stepOrder;
  final bool isRequired;
  final String status;

  const IssueSolutionModel({
    required this.id,
    required this.solutionCode,
    required this.issueId,
    required this.title,
    required this.description,
    required this.stepOrder,
    required this.isRequired,
    required this.status,
  });

  factory IssueSolutionModel.fromJson(Map<String, dynamic> json) {
    return IssueSolutionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      solutionCode: json['solutionCode']?.toString() ?? '',
      issueId: (json['issueId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      stepOrder: (json['stepOrder'] as num?)?.toInt() ?? 0,
      isRequired: json['isRequired'] as bool? ?? false,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

@HiveType(typeId: 1)
class InspectionDraft extends HiveObject {
  @HiveField(0)
  String localId;

  @HiveField(1)
  String deviceId;

  @HiveField(2)
  String deviceCode;

  @HiveField(3)
  String result;

  @HiveField(4)
  String notes;

  @HiveField(5)
  String? imagePath;

  @HiveField(6)
  double latitude;

  @HiveField(7)
  double longitude;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  String inspectorId;

  @HiveField(11)
  bool isGood;

  @HiveField(12)
  int? issueId;

  @HiveField(13)
  String? issueCode;

  @HiveField(14)
  String? issueTitle;

  @HiveField(15)
  List<int> completedSolutionIds;

  @HiveField(16)
  int? deviceTypeId;

  InspectionDraft({
    required this.localId,
    required this.deviceId,
    required this.deviceCode,
    required this.result,
    required this.notes,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isSynced = false,
    required this.inspectorId,
    this.isGood = false,
    this.issueId,
    this.issueCode,
    this.issueTitle,
    this.completedSolutionIds = const [],
    this.deviceTypeId,
  });

  Map<String, dynamic> toApiJson() => {
        'device_id': deviceId,
        'result': result,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
        'inspected_at': createdAt.toIso8601String(),
        'issue_id': issueId,
        'issue_code': issueCode,
        'issue_title': issueTitle,
        'completed_solution_ids': completedSolutionIds,
        'device_type_id': deviceTypeId,
      };
}

class ReportModel {
  final String id;
  final String reportNumber;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String deviceCode;
  final String locationText;
  final String building;
  final String floor;
  final String result;
  final String notes;
  final String inspectorName;
  final String inspectorId;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? imageUrl;

  const ReportModel({
    required this.id,
    required this.reportNumber,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.deviceCode = '',
    this.locationText = '',
    this.building = '',
    this.floor = '',
    required this.result,
    required this.notes,
    required this.inspectorName,
    required this.inspectorId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.imageUrl,
  });

  String get resultAr {
    switch (result) {
      case 'good':
        return 'سليم';
      case 'minor':
        return 'صيانة طفيفة';
      case 'maintenance':
        return 'صيانة';
      case 'faulty':
        return 'عطل';
      default:
        return result;
    }
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id']?.toString() ?? '',
        reportNumber: json['report_number']?.toString() ?? '',
        deviceId: json['device_id']?.toString() ?? '',
        deviceName: json['device_name']?.toString() ?? '',
        deviceType: json['device_type']?.toString() ?? '',
        deviceCode: json['device_code']?.toString() ?? '',
        locationText: json['location_text']?.toString() ?? '',
        building: json['building']?.toString() ?? '',
        floor: json['floor']?.toString() ?? '',
        result: json['result']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        inspectorName: json['inspector_name']?.toString() ?? '',
        inspectorId: json['inspector_id']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        imageUrl: json['image_url']?.toString(),
      );
}

class TodayStats {
  final int totalInspected;
  final int good;
  final int needsMaintenance;
  final int underReview;

  const TodayStats({
    required this.totalInspected,
    required this.good,
    required this.needsMaintenance,
    required this.underReview,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) => TodayStats(
        totalInspected: json['total'] as int? ?? 0,
        good: json['good'] as int? ?? 0,
        needsMaintenance: json['maintenance'] as int? ?? 0,
        underReview: json['review'] as int? ?? 0,
      );
}

class SyncStatusModel {
  final bool isConnected;
  final int synced;
  final int pending;
  final int failed;
  final DateTime? lastSyncTime;
  final List<PendingSyncItem> pendingItems;

  const SyncStatusModel({
    required this.isConnected,
    required this.synced,
    required this.pending,
    required this.failed,
    this.lastSyncTime,
    this.pendingItems = const [],
  });
}

class PendingSyncItem {
  final String localId;
  final String deviceName;
  final String location;
  final double sizeMb;
  final DateTime queuedAt;
  final bool isFailed;

  const PendingSyncItem({
    required this.localId,
    required this.deviceName,
    required this.location,
    required this.sizeMb,
    required this.queuedAt,
    this.isFailed = false,
  });
}