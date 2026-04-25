import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';


// ═══════════════════════════════════════════════════════
//  STATUS BADGE
// ═══════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 14,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: type.bgColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: type.textColor.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 8,
            height: isSmall ? 6 : 8,
            decoration: BoxDecoration(color: type.textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: type.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { good, maintenance, review, faulty, pending }

extension StatusTypeExt on StatusType {
  Color get bgColor {
    switch (this) {
      case StatusType.good:        return AppColors.success;
      case StatusType.maintenance: return AppColors.maintenance;
      case StatusType.review:      return AppColors.warning;
      case StatusType.faulty:      return AppColors.error;
      case StatusType.pending:     return AppColors.info;
    }
  }
  Color get textColor {
    switch (this) {
      case StatusType.good:        return AppColors.success;
      case StatusType.maintenance: return AppColors.maintenance;
      case StatusType.review:      return AppColors.warning;
      case StatusType.faulty:      return AppColors.error;
      case StatusType.pending:     return AppColors.info;
    }
  }
}

StatusType statusFromString(String s) {
  switch (s) {
    case 'good':        return StatusType.good;
    case 'maintenance': return StatusType.maintenance;
    case 'review':      return StatusType.review;
    case 'faulty':      return StatusType.faulty;
    default:            return StatusType.pending;
  }
}

// ═══════════════════════════════════════════════════════
//  STAT CARD
// ═══════════════════════════════════════════════════════
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.h2.copyWith(fontSize: 24, height: 1),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  RESPONSIVE STAT GRID
// ═══════════════════════════════════════════════════════
class ResponsiveStatGrid extends StatelessWidget {
  final List<StatCard> cards;
  const ResponsiveStatGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: cards,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(title, style: AppText.h3.copyWith(fontSize: 18))),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  GRADIENT APP BAR
// ═══════════════════════════════════════════════════════
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final double height;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        title: subtitle != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.h4.copyWith(color: Colors.white)),
                  Text(subtitle!, style: AppText.caption.copyWith(color: Colors.white70)),
                ],
              )
            : Text(title, style: AppText.h4.copyWith(color: Colors.white)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  MINISTRY HEADER CARD
// ═══════════════════════════════════════════════════════
class MinistryGreetingCard extends StatelessWidget {
  final String inspectorName;
  final String role;
  final String region;

  const MinistryGreetingCard({
    super.key,
    required this.inspectorName,
    required this.role,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.medium,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.shield_moon_outlined, size: 120, color: Colors.white.withOpacity(0.05)),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.greeting(),
                      style: AppText.small.copyWith(color: Colors.white60, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      inspectorName,
                      style: AppText.h2.copyWith(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _Badge(label: role, icon: Icons.verified_user_rounded),
                        _Badge(label: region, icon: Icons.map_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.home_work_rounded, color: AppColors.accent, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label; final IconData icon;
  const _Badge({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.accentLight),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════
//  BOTTOM NAV BAR
// ═══════════════════════════════════════════════════════
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded,  label: 'الرئيسية', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.fact_check_rounded, label: 'التقارير', index: 1, current: currentIndex, onTap: onTap),
              _ScanFab(onTap: () => onTap(2)),
              _NavItem(icon: Icons.sync_rounded,       label: 'مزامنة',   index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_rounded,     label: 'حسابي',    index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int index; final int current; final Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: selected ? AppColors.accent : AppColors.textHint, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo', fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.accent : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.glow,
      ),
      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
    ),
  );
}

// ═══════════════════════════════════════════════════════
//  DEVICE TYPE ICON
// ═══════════════════════════════════════════════════════
class DeviceTypeIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color? bgColor;

  const DeviceTypeIcon({super.key, required this.type, this.size = 40, this.bgColor});

  IconData get _icon {
    switch (type) {
      case 'computer':       return Icons.computer_rounded;
      case 'laptop':         return Icons.laptop_rounded;
      case 'printer':        return Icons.print_rounded;
      case 'camera':         return Icons.videocam_rounded;
      case 'access_control': return Icons.sensor_door_rounded;
      case 'projector':      return Icons.cast_rounded;
      case 'scanner':        return Icons.document_scanner_rounded;
      default:               return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(_icon, color: AppColors.primary, size: size * 0.5),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STEP INDICATOR
// ═══════════════════════════════════════════════════════
class StepIndicator extends StatelessWidget {
  final int currentStep; final int totalSteps; final List<String> labels;
  const StepIndicator({super.key, required this.currentStep, required this.totalSteps, required this.labels});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(totalSteps, (i) {
      final isDone    = i < currentStep;
      final isCurrent = i == currentStep;
      return Expanded(
        child: Row(children: [
          if (i > 0) Expanded(child: Container(height: 2, color: isDone || isCurrent ? AppColors.accent : AppColors.border)),
          Column(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : isCurrent ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: AppColors.accent, width: 2) : null,
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : Center(child: Text('${i + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: isCurrent ? Colors.white : AppColors.textHint))),
            ),
            const SizedBox(height: 6),
            Text(labels[i], style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400, color: isCurrent ? AppColors.primary : AppColors.textHint)),
          ]),
          if (i < totalSteps - 1) Expanded(child: Container(height: 2, color: isDone ? AppColors.accent : AppColors.border)),
        ]),
      );
    }),
  );
}

// ═══════════════════════════════════════════════════════
//  SHIMMER LOADER
// ═══════════════════════════════════════════════════════
class ShimmerCard extends StatelessWidget {
  final double height; final double? width; final double radius;
  const ShimmerCard({super.key, this.height = 80, this.width, this.radius = 20});
  @override
  Widget build(BuildContext context) => Container(
    height: height, width: width ?? double.infinity,
    decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(radius)),
  );
}