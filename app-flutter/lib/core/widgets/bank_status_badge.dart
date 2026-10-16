import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

class BankStatusBadge extends StatefulWidget {
  final String status;
  final bool isAnimated;

  const BankStatusBadge({
    super.key,
    required this.status,
    this.isAnimated = true,
  });

  @override
  State<BankStatusBadge> createState() => _BankStatusBadgeState();
}

class _BankStatusBadgeState extends State<BankStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status.toUpperCase() == 'PENDING') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BankStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.toUpperCase() == 'PENDING') {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusUpper = widget.status.toUpperCase();

    Color bgColor;
    Color textColor;
    IconData iconData;
    String displayLabel;

    switch (statusUpper) {
      case 'PENDING':
        bgColor = AppColors.warningOrangeLight;
        textColor = const Color(0xFFB45309);
        iconData = Icons.access_time_rounded;
        displayLabel = 'Pendente';
        break;
      case 'PROCESSED':
      case 'ACTIVE':
        bgColor = AppColors.accentGreenLight;
        textColor = const Color(0xFF047857);
        iconData = Icons.check_circle_rounded;
        displayLabel = statusUpper == 'ACTIVE' ? 'Ativa' : 'Processada';
        break;
      case 'FAILED':
      case 'BLOCKED':
        bgColor = AppColors.errorRedLight;
        textColor = AppColors.errorRed;
        iconData = Icons.error_rounded;
        displayLabel = statusUpper == 'BLOCKED' ? 'Bloqueada' : 'Falhou';
        break;
      case 'REVERSED':
      case 'CLOSED':
        bgColor = const Color(0xFFF3F4F6);
        textColor = AppColors.textSecondaryLight;
        iconData = Icons.replay_rounded;
        displayLabel = statusUpper == 'CLOSED' ? 'Encerrada' : 'Estornada';
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = AppColors.textSecondaryLight;
        iconData = Icons.info_outline_rounded;
        displayLabel = widget.status;
    }

    Widget badgeContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimensions.borderRadiusPill,
        border: Border.all(color: textColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (statusUpper == 'PENDING' && widget.isAnimated) {
      return FadeTransition(
        opacity: _pulseAnimation,
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
