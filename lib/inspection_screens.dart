import 'dart:io';

import 'package:access_track/app_constants.dart';
import 'package:access_track/core/api/technician_repository.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class InspectionFormScreen extends ConsumerStatefulWidget {
  final DeviceModel device;
  final Future<String?> Function(InspectionDraft draft) onSubmit;
  final VoidCallback onBack;
  final String currentUserId;

  const InspectionFormScreen({
    super.key,
    required this.device,
    required this.onSubmit,
    required this.onBack,
    this.currentUserId = '1',
  });

  @override
  ConsumerState<InspectionFormScreen> createState() =>
      _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  int _step = 2;

  bool? _deviceIsGoodAtStart;
  bool? _deviceIsGoodAfterSolutions;

  final TextEditingController _notesCtrl = TextEditingController();

  File? _photo;
  bool _submitting = false;
  bool _loadingIssues = false;
  bool _loadingSolutions = false;

  String? _error;
  double? _lat;
  double? _lng;

  List<InspectionIssueOption> _issues = const [];
  InspectionIssueOption? _selectedIssue;

  List<IssueSolutionModel> _solutions = const [];
  final Set<int> _doneSolutionIds = <int>{};

  static const List<String> _stepLabels = [
    'المسح',
    'التفاصيل',
    'التفتيش',
    'الإرسال',
  ];

  bool get _isGoodSelected => _deviceIsGoodAtStart == true;

  bool get _isFaultSelected => _deviceIsGoodAtStart == false;

  bool get _hasAnyDoneSolution => _doneSolutionIds.isNotEmpty;

  String get _deviceTypeDisplay {
    if ((widget.device.backendDeviceTypeName ?? '').trim().isNotEmpty) {
      return widget.device.backendDeviceTypeName!.trim();
    }

    return widget.device.typeAr;
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _lat = 30.04;
      _lng = 31.23;
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 45,
      maxWidth: 1280,
    );

    if (xfile != null) {
      setState(() {
        _photo = File(xfile.path);
        _error = null;
      });
    }
  }

  Future<void> _selectInitialCondition(bool isGood) async {
    setState(() {
      _deviceIsGoodAtStart = isGood;
      _deviceIsGoodAfterSolutions = isGood ? true : null;

      _error = null;
      _issues = const [];
      _selectedIssue = null;
      _solutions = const [];
      _doneSolutionIds.clear();
    });

    if (!isGood) {
      await _loadIssuesForDevice();
    }
  }

  Future<void> _loadIssuesForDevice() async {
    setState(() {
      _loadingIssues = true;
      _error = null;
    });

    try {
      final repo = ref.read(technicianRepositoryProvider);
      final result = await repo.getIssuesForDevice(widget.device);

      if (!mounted) return;

      setState(() {
        _issues = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingIssues = false;
        });
      }
    }
  }

  Future<void> _selectIssue(InspectionIssueOption issue) async {
    setState(() {
      _selectedIssue = issue;
      _solutions = const [];
      _doneSolutionIds.clear();
      _deviceIsGoodAfterSolutions = null;
      _loadingSolutions = true;
      _error = null;
    });

    try {
      final repo = ref.read(technicianRepositoryProvider);
      final result = await repo.getIssueSolutions(issue.id);

      if (!mounted) return;

      setState(() {
        _solutions = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSolutions = false;
        });
      }
    }
  }

  void _toggleSolutionDone(int solutionId) {
    setState(() {
      if (_doneSolutionIds.contains(solutionId)) {
        _doneSolutionIds.remove(solutionId);
      } else {
        _doneSolutionIds.add(solutionId);
      }

      if (_doneSolutionIds.isEmpty) {
        _deviceIsGoodAfterSolutions = null;
      }

      _error = null;
    });
  }

  String _buildSelectedIssueNotes() {
    final issue = _selectedIssue;

    if (issue == null) return '';

    final buffer = StringBuffer();

    buffer.writeln('المشكلة المختارة:');
    buffer.writeln('Issue ID: ${issue.id}');
    buffer.writeln('Issue Code: ${issue.issueCode}');
    buffer.writeln('Issue Title: ${issue.title}');

    if (issue.description.trim().isNotEmpty) {
      buffer.writeln('Issue Description: ${issue.description}');
    }

    buffer.writeln('حلول المشكلة المختارة:');

    for (final solution in _solutions) {
      final isDone = _doneSolutionIds.contains(solution.id);

      buffer.writeln(
        'Solution ${solution.id}: ${solution.stepOrder}. ${solution.title} - ${isDone ? "DONE" : "NOT_DONE"}',
      );

      if (solution.description.trim().isNotEmpty) {
        buffer.writeln('Solution Description: ${solution.description}');
      }
    }

    return buffer.toString().trim();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_deviceIsGoodAtStart == null) {
      setState(() => _error = 'يرجى تحديد هل الجهاز سليم أم غير سليم');
      return;
    }

    if (_photo == null) {
      setState(() => _error = 'لازم ترفعي صورة الجهاز قبل الإرسال');
      return;
    }

    if (_isFaultSelected && _loadingIssues) {
      setState(() => _error = 'استني تحميل المشاكل أولاً');
      return;
    }

    if (_isFaultSelected && _issues.isEmpty) {
      setState(() => _error = 'لا توجد مشاكل لهذا النوع من الأجهزة');
      return;
    }

    if (_isFaultSelected && _selectedIssue == null) {
      setState(() => _error = 'اختاري المشكلة أولاً');
      return;
    }

    if (_isFaultSelected && _loadingSolutions) {
      setState(() => _error = 'استني تحميل حلول المشكلة أولاً');
      return;
    }

    if (_isFaultSelected && _solutions.isEmpty) {
      setState(() => _error = 'لا توجد حلول لهذه المشكلة');
      return;
    }

    if (_isFaultSelected && !_hasAnyDoneSolution) {
      setState(() => _error = 'لازم تعملي Done لخطوة حل واحدة على الأقل');
      return;
    }

    if (_isFaultSelected && _deviceIsGoodAfterSolutions == null) {
      setState(
        () => _error = 'بعد تنفيذ الحلول اختاري هل الجهاز بقى سليم أم ما زال فيه عطل',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final finalIsGood = _isGoodSelected || _deviceIsGoodAfterSolutions == true;

      final resultForApi =
          finalIsGood ? InspectionResult.good : InspectionResult.faulty;

      final List<String> notesLines = [
        'نوع الجهاز: $_deviceTypeDisplay',
        'حالة الجهاز في البداية: ${_deviceIsGoodAtStart == true ? "سليم" : "غير سليم"}',
        'حالة الجهاز بعد الحل: ${finalIsGood ? "سليم" : "ما زال فيه عطل"}',
        if (_selectedIssue != null)
          'المشكلة المختارة: ${_selectedIssue!.title}',
        if (_selectedIssue != null)
          'كود المشكلة المختارة: ${_selectedIssue!.issueCode}',
        if (_doneSolutionIds.isNotEmpty)
          'Completed Steps IDs: ${(_doneSolutionIds.toList()..sort()).join(",")}',
        if (_doneSolutionIds.isNotEmpty)
          'عدد الخطوات المنفذة: ${_doneSolutionIds.length}',
        if (_notesCtrl.text.trim().isNotEmpty)
          'ملاحظات الفني: ${_notesCtrl.text.trim()}',
        if (_isFaultSelected) _buildSelectedIssueNotes(),
      ];

      final draft = InspectionDraft(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: widget.device.id,
        deviceCode: widget.device.code,
        result: resultForApi.apiValue,
        notes: notesLines.where((e) => e.trim().isNotEmpty).join('\n'),
        imagePath: _photo?.path,
        latitude: _lat ?? 0,
        longitude: _lng ?? 0,
        createdAt: DateTime.now(),
        inspectorId: widget.currentUserId,
        isGood: finalIsGood,
        issueId: _isFaultSelected ? _selectedIssue?.id : null,
        issueCode: _isFaultSelected ? _selectedIssue?.issueCode : null,
        issueTitle: _isFaultSelected ? _selectedIssue?.title : null,
        completedSolutionIds: _doneSolutionIds.toList()..sort(),
        deviceTypeId: widget.device.backendDeviceTypeId,
      );

      final error = await widget.onSubmit(draft);

      if (!mounted) return;

      if (error != null && error.trim().isNotEmpty) {
        setState(() => _error = error);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ وإرسال التفتيش بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: GradientAppBar(
        title: AppStrings.inspectionForm,
        subtitle: '${widget.device.code} • $_deviceTypeDisplay',
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: StepIndicator(
                currentStep: _step,
                totalSteps: 4,
                labels: _stepLabels,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

            const SizedBox(height: 20),

            _FormSection(
              title: 'بيانات الجهاز',
              child: Column(
                children: [
                  _InfoLine(label: 'اسم الجهاز', value: widget.device.name),
                  const SizedBox(height: 10),
                  _InfoLine(label: 'نوع الجهاز', value: _deviceTypeDisplay),
                  const SizedBox(height: 10),
                  _InfoLine(
                    label: AppStrings.location,
                    value: widget.device.location.isEmpty
                        ? '${widget.device.room} - ${widget.device.building}'
                        : widget.device.location,
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 16),

            _FormSection(
              title: 'هل الجهاز سليم؟',
              child: Row(
                children: [
                  Expanded(
                    child: _ConditionButton(
                      title: 'سليم',
                      subtitle: 'لا توجد مشكلة',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      selected: _deviceIsGoodAtStart == true,
                      onTap: () => _selectInitialCondition(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ConditionButton(
                      title: 'غير سليم',
                      subtitle: 'توجد مشكلة',
                      icon: Icons.error_rounded,
                      color: AppColors.error,
                      selected: _deviceIsGoodAtStart == false,
                      onTap: () => _selectInitialCondition(false),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(),

            if (_isFaultSelected) ...[
              const SizedBox(height: 16),

              _FormSection(
                title: 'اختاري المشكلة حسب نوع الجهاز',
                child: _loadingIssues
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _issues.isEmpty
                        ? Text(
                            'لا توجد مشاكل مسجلة لهذا النوع من الأجهزة حالياً',
                            style: AppText.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Column(
                            children: _issues.map((issue) {
                              final isSelected =
                                  _selectedIssue?.id == issue.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _IssueOptionCard(
                                  issue: issue,
                                  selected: isSelected,
                                  onTap: () => _selectIssue(issue),
                                ),
                              );
                            }).toList(),
                          ),
              ).animate(delay: 220.ms).fadeIn(),

              if (_selectedIssue != null) ...[
                const SizedBox(height: 16),

                _FormSection(
                  title: 'حلول المشكلة المختارة',
                  child: _loadingSolutions
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _solutions.isEmpty
                          ? Text(
                              'لا توجد حلول لهذه المشكلة حالياً',
                              style: AppText.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    '${_selectedIssue!.issueCode} - ${_selectedIssue!.title}',
                                    style: AppText.bodyMed.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                ),
                                ..._solutions.map((solution) {
                                  final isDone =
                                      _doneSolutionIds.contains(solution.id);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _SolutionStepCard(
                                      solution: solution,
                                      isDone: isDone,
                                      onToggleDone: () =>
                                          _toggleSolutionDone(solution.id),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                ).animate(delay: 250.ms).fadeIn(),
              ],

              const SizedBox(height: 16),

              if (_hasAnyDoneSolution)
                _FormSection(
                  title: 'بعد تنفيذ الحلول، حالة الجهاز الآن؟',
                  child: Row(
                    children: [
                      Expanded(
                        child: _ConditionButton(
                          title: 'بقى سليم',
                          subtitle: 'تم حل المشكلة',
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                          selected: _deviceIsGoodAfterSolutions == true,
                          onTap: () {
                            setState(() {
                              _deviceIsGoodAfterSolutions = true;
                              _error = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ConditionButton(
                          title: 'ما زال فيه عطل',
                          subtitle: 'لم يتم الحل بالكامل',
                          icon: Icons.report_problem_rounded,
                          color: AppColors.error,
                          selected: _deviceIsGoodAfterSolutions == false,
                          onTap: () {
                            setState(() {
                              _deviceIsGoodAfterSolutions = false;
                              _error = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 280.ms).fadeIn(),
            ],

            const SizedBox(height: 16),

            _FormSection(
              title: AppStrings.notes,
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                style: AppText.body,
                decoration: const InputDecoration(
                  hintText: 'أضف أي ملاحظات إضافية هنا...',
                  alignLabelWithHint: true,
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormSection(
                    title: '${AppStrings.devicePhoto} *',
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _photo != null
                                ? AppColors.accent
                                : AppColors.error,
                            width: _photo != null ? 1.5 : 1,
                          ),
                        ),
                        child: _photo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _photo!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: AppColors.textHint,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'التقاط صورة إجباري',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormSection(
                    title: 'الموقع',
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.info,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          if (_lat != null) ...[
                            Text(
                              '${_lat!.toStringAsFixed(3)}°N',
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_lng!.toStringAsFixed(3)}°E',
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ] else
                            Text('جاري التحديد...', style: AppText.caption),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(delay: 350.ms).fadeIn(),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppText.small.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(AppStrings.sendReport),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ConditionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.10) : AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : AppColors.textHint,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppText.bodyMed.copyWith(
                fontWeight: FontWeight.w900,
                color: selected ? color : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppText.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueOptionCard extends StatelessWidget {
  final InspectionIssueOption issue;
  final bool selected;
  final VoidCallback onTap;

  const _IssueOptionCard({
    required this.issue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.08)
              : AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.accent : AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${issue.issueCode} - ${issue.title}',
                    style: AppText.bodyMed.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          selected ? AppColors.accentDark : AppColors.textPrimary,
                    ),
                  ),
                  if (issue.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      issue.description,
                      style: AppText.small.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionStepCard extends StatelessWidget {
  final IssueSolutionModel solution;
  final bool isDone;
  final VoidCallback onToggleDone;

  const _SolutionStepCard({
    required this.solution,
    required this.isDone,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withOpacity(0.08)
            : AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone
                    ? AppColors.success
                    : AppColors.primary.withOpacity(0.12),
                child: Text(
                  '${solution.stepOrder}',
                  style: AppText.caption.copyWith(
                    color: isDone ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  solution.title,
                  style: AppText.bodyMed.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onToggleDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDone ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(84, 38),
                ),
                child: Text(isDone ? 'تم' : 'Done'),
              ),
            ],
          ),
          if (solution.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              solution.description,
              style: AppText.small.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            solution.isRequired ? 'خطوة مطلوبة' : 'خطوة اختيارية',
            style: AppText.caption.copyWith(
              color:
                  solution.isRequired ? AppColors.warning : AppColors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Text(
            label,
            style: AppText.small.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? 'لا يوجد' : value,
            textAlign: TextAlign.end,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: AppText.bodyMed.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class InspectionSuccessScreen extends StatelessWidget {
  final String reportNumber;
  final String deviceName;
  final String result;
  final String inspectorName;
  final double lat;
  final double lng;
  final VoidCallback onScanAnother;
  final VoidCallback onGoHome;

  const InspectionSuccessScreen({
    super.key,
    required this.reportNumber,
    required this.deviceName,
    required this.result,
    required this.inspectorName,
    required this.lat,
    required this.lng,
    required this.onScanAnother,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                  size: 80,
                ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.reportSent,
                  style: AppText.h2.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.deep,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: AppColors.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.reportSummary,
                            style: AppText.h3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SummaryRow(
                        AppStrings.reportNumber,
                        reportNumber,
                        isCode: true,
                      ),
                      _SummaryRow(AppStrings.device, deviceName),
                      _SummaryRow(
                        AppStrings.status,
                        _resultAr,
                        isStatus: true,
                        statusValue: result,
                      ),
                      _SummaryRow(AppStrings.inspector, inspectorName),
                      _SummaryRow(
                        AppStrings.coordinates,
                        '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E',
                        isCode: true,
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onScanAnother,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(AppStrings.scanAnother),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ).animate(delay: 500.ms).fadeIn(),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onGoHome,
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text(AppStrings.backHome),
                ).animate(delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _resultAr {
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
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;
  final bool isStatus;
  final String? statusValue;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isCode = false,
    this.isStatus = false,
    this.statusValue,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 3,
              child: Text(
                label,
                style: AppText.small.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            if (isStatus && statusValue != null)
              StatusBadge(
                label: value,
                type: statusFromString(statusValue!),
                isSmall: true,
              )
            else
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: AppText.bodyMed.copyWith(
                    fontFamily: isCode ? 'monospace' : 'Cairo',
                    color: isCode
                        ? AppColors.accentDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      );
}