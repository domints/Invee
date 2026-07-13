import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'category_detail_screen.dart';
import 'item_detail_screen.dart';

/// Body-only widget (no Scaffold) listing top-level categories.
/// Embedded inside [MainShell] via an IndexedStack.
class CategoryBrowserBody extends StatefulWidget {
  final ApiService apiService;

  const CategoryBrowserBody({super.key, required this.apiService});

  @override
  State<CategoryBrowserBody> createState() => CategoryBrowserBodyState();
}

class CategoryBrowserBodyState extends State<CategoryBrowserBody> {
  List<CategoryTreeResponse>? _tree;
  List<ItemListEntry> _expiringItems = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.apiService.getCategoryTree(),
        widget.apiService.getExpiringItems(),
      ]);
      if (mounted) {
        setState(() {
          _tree = results[0] as List<CategoryTreeResponse>;
          _expiringItems = (results[1] as List<ItemListEntry>)
              .where((i) => !_isZeroAmount(i))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  bool _isZeroAmount(ItemListEntry item) {
    if (item.quantityType == '2') return (item.quantity ?? 0) <= 0;
    if (item.quantityType == '1') return item.level == '0';
    return false;
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now).inDays;
    if (diff < 0) return 'Expired ${diff.abs()}d ago';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return 'Expires in ${diff}d';
  }

  bool _isExpired(DateTime expiresAt) => expiresAt.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if ((_tree == null || _tree!.isEmpty) && _expiringItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_special_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No categories yet.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Tap + to create the first one.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final categories = _tree ?? [];
    final expiring = _expiringItems;
    // Total items: optional expiring header + expiring cards + optional category header + category tiles
    final hasExpiring = expiring.isNotEmpty;
    final expiringHeaderCount = hasExpiring ? 1 : 0;
    final expiringCount = expiring.length;
    final categoryHeaderCount = categories.isNotEmpty ? 1 : 0;
    final totalCount = expiringHeaderCount + expiringCount + categoryHeaderCount + categories.length;

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        itemCount: totalCount,
        itemBuilder: (ctx, i) {
          var idx = i;

          if (hasExpiring) {
            if (idx == 0) {
              return _ExpiringSectionHeader();
            }
            idx -= 1;
            if (idx < expiringCount) {
              final item = expiring[idx];
              return _ExpiringItemTile(
                item: item,
                label: _formatExpiry(item.expiresAt!),
                expired: _isExpired(item.expiresAt!),
                onTap: () async {
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(
                        itemId: item.id,
                        apiService: widget.apiService,
                      ),
                    ),
                  );
                  reload();
                },
              );
            }
            idx -= expiringCount;
          }

          if (categories.isNotEmpty) {
            if (idx == 0) {
              return const _SectionHeader(label: 'Categories');
            }
            idx -= 1;
          }

          final cat = categories[idx];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CategoryRootTile(
                category: cat,
                apiService: widget.apiService,
                onChanged: reload,
              ),
              if (idx < categories.length - 1) const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

class _ExpiringSectionHeader extends StatelessWidget {
  const _ExpiringSectionHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: colorScheme.error),
          const SizedBox(width: 8),
          Text(
            'Expiring Soon',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ExpiringItemTile extends StatelessWidget {
  final ItemListEntry item;
  final String label;
  final bool expired;
  final VoidCallback onTap;

  const _ExpiringItemTile({
    required this.item,
    required this.label,
    required this.expired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = expired
        ? colorScheme.errorContainer.withValues(alpha: 0.35)
        : colorScheme.tertiaryContainer.withValues(alpha: 0.35);
    final dateColor = expired ? colorScheme.error : colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: dateColor,
                    fontWeight: expired ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRootTile extends StatelessWidget {
  final CategoryTreeResponse category;
  final ApiService apiService;
  final VoidCallback onChanged;

  const _CategoryRootTile({
    required this.category,
    required this.apiService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.folder_special_outlined,
          color: theme.colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(category.name),
      subtitle: category.children.isNotEmpty
          ? Text(
              '${category.children.length} subcategor${category.children.length == 1 ? 'y' : 'ies'}',
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(
              categoryId: category.id,
              categoryName: category.name,
              preloadedChildren: category.children,
              apiService: apiService,
            ),
          ),
        );
        if (changed == true) onChanged();
      },
    );
  }
}
