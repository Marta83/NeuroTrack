import 'package:flutter/material.dart';

const double gapSection = 32.0;
const double gapCard = 24.0;
const double gapField = 16.0;
const double gapSmall = 8.0;

class SoftConstrainedBody extends StatelessWidget {
  const SoftConstrainedBody({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}

class SoftSectionHeader extends StatelessWidget {
  const SoftSectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    (theme.textTheme.titleLarge ?? theme.textTheme.titleMedium)
                        ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

InputDecoration softDecoration(
  BuildContext context, {
  required String label,
  String? helper,
  String? hint,
  Widget? suffix,
  Widget? prefix,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return InputDecoration(
    labelText: label,
    helperText: helper,
    hintText: hint,
    suffixIcon: suffix,
    prefixIcon: prefix,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.6)),
    ),
    helperStyle: theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    hintStyle: theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    counterStyle: theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
  );
}

class SoftExpansionSection extends StatefulWidget {
  const SoftExpansionSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.selectedCount,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final int? selectedCount;
  final bool initiallyExpanded;

  @override
  State<SoftExpansionSection> createState() => _SoftExpansionSectionState();
}

class _SoftExpansionSectionState extends State<SoftExpansionSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCount = widget.selectedCount;
    final countLabel = selectedCount == null
        ? ''
        : selectedCount == 1
            ? ' (1 seleccionado)'
            : ' ($selectedCount seleccionados)';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (bool value) {
          setState(() => _expanded = value);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text('${widget.title}$countLabel'),
        subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
        children: <Widget>[widget.child],
      ),
    );
  }
}

class SoftChipsWrap extends StatelessWidget {
  const SoftChipsWrap({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

FilterChip softFilterChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    selectedColor: colorScheme.primary.withValues(alpha: 0.18),
    checkmarkColor: colorScheme.primary,
    side: BorderSide(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.45)
          : colorScheme.outlineVariant,
    ),
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: selected ? colorScheme.primary : colorScheme.onSurface,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    ),
  );
}
