import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../data/models/miner_group.dart';

class GroupHeader extends StatelessWidget {
  final MinerGroup group;
  final int minerCount;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const GroupHeader({
    super.key,
    required this.group,
    required this.minerCount,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            group.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$minerCount',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          if (onRename != null || onDelete != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
              onSelected: (value) {
                if (value == 'rename') onRename?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onRename != null)
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete Group')),
              ],
            ),
        ],
      ),
    );
  }
}
