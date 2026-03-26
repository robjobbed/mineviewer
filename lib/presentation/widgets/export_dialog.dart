import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../presentation/providers/miners_provider.dart';
import '../../providers/miners/snapshot_history_provider.dart';
import '../../services/export/csv_exporter.dart';
import '../../services/export/json_exporter.dart';
import '../../services/export/pdf_exporter.dart';

enum ExportFormat { csv, json, pdf }

enum ExportTimeRange { last24h, last7d, last30d, allTime }

extension ExportTimeRangeExt on ExportTimeRange {
  String get label => switch (this) {
        ExportTimeRange.last24h => 'Last 24 hours',
        ExportTimeRange.last7d => 'Last 7 days',
        ExportTimeRange.last30d => 'Last 30 days',
        ExportTimeRange.allTime => 'All time',
      };

  Duration? get duration => switch (this) {
        ExportTimeRange.last24h => const Duration(hours: 24),
        ExportTimeRange.last7d => const Duration(days: 7),
        ExportTimeRange.last30d => const Duration(days: 30),
        ExportTimeRange.allTime => null,
      };
}

extension ExportFormatExt on ExportFormat {
  String get label => switch (this) {
        ExportFormat.csv => 'CSV',
        ExportFormat.json => 'JSON',
        ExportFormat.pdf => 'PDF Report',
      };

  IconData get icon => switch (this) {
        ExportFormat.csv => Icons.table_chart_outlined,
        ExportFormat.json => Icons.data_object_outlined,
        ExportFormat.pdf => Icons.picture_as_pdf_outlined,
      };
}

/// Show the export bottom sheet.
void showExportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.cardRadius),
      ),
    ),
    builder: (_) => const _ExportDialogContent(),
  );
}

class _ExportDialogContent extends ConsumerStatefulWidget {
  const _ExportDialogContent();

  @override
  ConsumerState<_ExportDialogContent> createState() =>
      _ExportDialogContentState();
}

class _ExportDialogContentState extends ConsumerState<_ExportDialogContent> {
  String? _selectedMinerId; // null = all miners
  ExportTimeRange _timeRange = ExportTimeRange.last24h;
  ExportFormat _format = ExportFormat.csv;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final miners = ref.watch(minersProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          const Text(
            'Export Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Miner selector
          _buildLabel('Miner'),
          const SizedBox(height: AppSpacing.sm),
          _buildDropdown<String?>(
            value: _selectedMinerId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Miners'),
              ),
              ...miners.map(
                (m) => DropdownMenuItem<String?>(
                  value: m.id,
                  child: Text(m.name),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedMinerId = v),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time range
          _buildLabel('Time Range'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: ExportTimeRange.values.map((tr) {
              final selected = tr == _timeRange;
              return ChoiceChip(
                label: Text(
                  tr.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppColors.backgroundDark
                        : AppColors.textSecondary,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.cardDark,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (_) => setState(() => _timeRange = tr),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Format
          _buildLabel('Format'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: ExportFormat.values.map((f) {
              final selected = f == _format;
              return ChoiceChip(
                avatar: Icon(
                  f.icon,
                  size: 16,
                  color: selected
                      ? AppColors.backgroundDark
                      : AppColors.textSecondary,
                ),
                label: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppColors.backgroundDark
                        : AppColors.textSecondary,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.cardDark,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (_) => setState(() => _format = f),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Export button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _exporting ? null : _doExport,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
              ),
              child: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundDark,
                      ),
                    )
                  : const Text(
                      'Export',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        iconEnabledColor: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);

    try {
      final miners = ref.read(minersProvider);
      final historyNotifier = ref.read(snapshotHistoryProvider.notifier);

      // Determine which miners to export
      final targetMiners = _selectedMinerId == null
          ? miners
          : miners.where((m) => m.id == _selectedMinerId).toList();

      if (targetMiners.isEmpty) {
        _showError('No miners found');
        return;
      }

      final paths = <String>[];

      for (final miner in targetMiners) {
        final snapshots = _timeRange.duration != null
            ? historyNotifier.getHistory(miner.id,
                range: _timeRange.duration!)
            : historyNotifier.getHistory(miner.id);

        if (snapshots.isEmpty) continue;

        final path = switch (_format) {
          ExportFormat.csv =>
            await CsvExporter.exportToFile(miner.name, snapshots),
          ExportFormat.json =>
            await JsonExporter.exportToFile(miner, snapshots),
          ExportFormat.pdf =>
            await PdfExporter.exportToFile(miner, snapshots),
        };

        paths.add(path);
      }

      if (paths.isEmpty) {
        _showError('No snapshot data available for the selected range');
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      // Share via share_plus
      await Share.shareXFiles(
        paths.map((p) => XFile(p)).toList(),
        subject: 'MineViewer Export',
      );
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }
}
