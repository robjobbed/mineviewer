import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// Widget that can blur/redact text (for IP addresses and wallet addresses).
/// Tap to toggle visibility.
class PrivacyText extends StatefulWidget {
  final String value;
  final bool isBlurred;
  final TextStyle? style;
  final String? redactedPlaceholder;

  /// If [onToggle] is provided, tapping calls it instead of
  /// using internal state. Use this for externally-managed blur state.
  final VoidCallback? onToggle;

  const PrivacyText({
    super.key,
    required this.value,
    required this.isBlurred,
    this.style,
    this.redactedPlaceholder,
    this.onToggle,
  });

  @override
  State<PrivacyText> createState() => _PrivacyTextState();
}

class _PrivacyTextState extends State<PrivacyText> {
  late bool _localBlurred;

  @override
  void initState() {
    super.initState();
    _localBlurred = widget.isBlurred;
  }

  @override
  void didUpdateWidget(covariant PrivacyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBlurred != widget.isBlurred) {
      _localBlurred = widget.isBlurred;
    }
  }

  bool get _effectiveBlurred =>
      widget.onToggle != null ? widget.isBlurred : _localBlurred;

  void _handleTap() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() => _localBlurred = !_localBlurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ??
        const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        );

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _effectiveBlurred
            ? _buildRedacted(effectiveStyle)
            : Text(
                widget.value,
                key: const ValueKey('visible'),
                style: effectiveStyle,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  Widget _buildRedacted(TextStyle style) {
    final placeholder =
        widget.redactedPlaceholder ?? _generateMask(widget.value);

    return Row(
      key: const ValueKey('blurred'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          placeholder,
          style: style.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.visibility_off_outlined,
          size: 14,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  /// Generate a mask appropriate for the text length.
  static String _generateMask(String value) {
    if (value.length <= 6) return '***';
    // Show first 2 and last 2 characters with dots in between
    return '${value.substring(0, 2)}${'*' * 4}${value.substring(value.length - 2)}';
  }
}
