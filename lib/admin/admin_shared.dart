import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/admin/admin_screens.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:access_track/core/widgets/widgets.dart' hide SectionHeader, ResponsiveStatGrid, StatCard;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shared.dart';
class AdminEmptyCard extends StatelessWidget {
  final String label;
  const AdminEmptyCard({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_rounded, size: 36, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(label, style: AppText.small),
          ]),
        ),
      );
}

class AdminErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AdminErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppText.small.copyWith(color: AppColors.error))),
          TextButton(onPressed: onRetry, child: const Text('retry', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        ]),
      );
}

class AdminStatsShimmer extends StatelessWidget {
  const AdminStatsShimmer();

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [Expanded(child: AdminShimmerCard()), const SizedBox(width: 12), Expanded(child: AdminShimmerCard())]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: AdminShimmerCard()), const SizedBox(width: 12), Expanded(child: AdminShimmerCard())]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: AdminShimmerCard()), const SizedBox(width: 12), Expanded(child: AdminShimmerCard())]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: AdminShimmerCard()), const SizedBox(width: 12), Expanded(child: AdminShimmerCard())]),
      ]);
}

// ════════════════════════════════════════════════════════
//  ADMIN TASKS SCREEN
// ════════════════════════════════════════════════════════
class AdminSheetHandle extends StatelessWidget {
  const AdminSheetHandle();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class AdminDetailCard extends StatelessWidget {
  final List<Widget> children;
  const AdminDetailCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: children.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < children.length - 1)
              const Divider(height: 1, indent: 16, color: AppColors.border),
          ])).toList(),
        ),
      );
}

class AdminDetailRow extends StatelessWidget {
  final String label, value;
  const AdminDetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(label, style: AppText.small),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: AppText.bodyMed, textAlign: TextAlign.end)),
        ]),
      );
}

// ── Field & Dropdown helpers inside forms ──────────────────
class AdminFormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final int maxLines;
  const AdminFormField({required this.ctrl, required this.label, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: AppText.body,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

class AdminDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) display;
  final void Function(T?) onChanged;
  const AdminDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value,
        style: AppText.body,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: [
          DropdownMenuItem<T>(value: null, child: Text('— $label —', style: AppText.small)),
          ...items.map((t) => DropdownMenuItem<T>(
                value: t,
                child: Text(display(t), style: AppText.body, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      );
}