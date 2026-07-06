import 'package:flutter/material.dart';

class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// A floating action button that expands into multiple mini-FABs when tapped.
class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialItem> items;
  final String heroTag;

  const SpeedDialFab({
    super.key,
    required this.items,
    this.heroTag = 'speed_dial',
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _open = !_open);
  }

  void _select(SpeedDialItem item) {
    _controller.reverse();
    setState(() => _open = false);
    item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs (shown above main FAB when open)
        ...items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return AnimatedBuilder(
            animation: _anim,
            builder: (ctx, child) {
              return Opacity(
                opacity: _anim.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _anim.value) * 16),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label bubble
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: '${widget.heroTag}_item_$idx',
                    onPressed: () => _select(item),
                    child: Icon(item.icon),
                  ),
                ],
              ),
            ),
          );
        }),

        // Main FAB
        FloatingActionButton(
          heroTag: '${widget.heroTag}_main',
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
