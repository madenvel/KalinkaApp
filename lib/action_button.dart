import 'package:flutter/material.dart';
import 'package:kalinka/constants.dart';

const double kIconSize = 32.0;
const EdgeInsets kButtonPadding = EdgeInsets.all(8.0);

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final double fixedButtonSize;

  const ActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = kIconSize,
    this.fixedButtonSize = KalinkaConstants.kButtonSize,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return IconButton.filled(
      icon: Icon(icon, size: iconSize),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        foregroundColor: colorScheme.onSecondaryContainer,
        fixedSize: Size(fixedButtonSize, fixedButtonSize),
        padding: kButtonPadding,
      ),
    );
  }
}
