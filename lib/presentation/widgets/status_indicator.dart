import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../data/models/miner_status.dart';

class StatusIndicator extends StatelessWidget {
  final MinerStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 10,
  });

  Color get _color => switch (status) {
        MinerStatus.online => AppColors.online,
        MinerStatus.offline => AppColors.offline,
        MinerStatus.warning => AppColors.warning,
        MinerStatus.error => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
