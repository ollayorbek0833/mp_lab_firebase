import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressedAsync;
  final VoidCallback? onPressed;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? leadingIcon;

  const CustomButton({
    Key? key,
    required this.label,
    this.onPressedAsync,
    this.onPressed,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.leadingIcon,
  })  : assert(onPressedAsync == null || onPressed == null,
  'Provide either onPressedAsync or onPressed, not both.'),
        super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  bool _loading = false;
  double _scale = 1.0;

  Future<void> _handleTap() async {
    if (!widget.enabled || _loading) return;
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    if (widget.onPressedAsync != null) {
      setState(() => _loading = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _onTapDown(_) {
    if (!widget.enabled || _loading) return;
    setState(() => _scale = 0.98);
  }

  void _onTapUp(_) {
    if (!widget.enabled || _loading) return;
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onPrimary;
    final disabledColor = theme.disabledColor;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: _handleTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _scale,
        child: Material(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: widget.enabled ? primary : disabledColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: _handleTap,
            child: Container(
              padding: widget.padding,
              alignment: Alignment.center,
              child: _loading
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Please wait...'),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.leadingIcon != null) ...[
                    widget.leadingIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label, style: theme.textTheme.labelLarge?.copyWith(color: textColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
