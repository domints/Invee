import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../utils/quantity_utils.dart';
import '../widgets/speed_dial_fab.dart';
import 'add_category_screen.dart';
import 'create_item_screen.dart';
import 'item_detail_screen.dart';

/// Drill-down screen for a single category. Shows subcategories and items.
/// Returns `true` via pop when the tree has been mutated (delete/rename/add).
class CategoryDetailScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  /// Children pre-loaded by the caller to avoid an extra tree fetch on first
  /// build. The screen will still reload on refresh.
  final List<CategoryTreeResponse>? preloadedChildren;
  final ApiService apiService;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.preloadedChildren,
    required this.apiService,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late String _currentName;
  List<CategoryTreeResponse>? _subcategories;
  List<ItemListEntry>? _items;
  bool _loading = true;
  String? _error;
  bool _anyChanged = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.categoryName;
    if (widget.preloadedChildren != null) {
      _subcategories = widget.preloadedChildren;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.apiService.getCategoryTree(),
        widget.apiService.getCategoryItems(widget.categoryId),
      ]);

      final tree = results[0] as List<CategoryTreeResponse>;
      final items = results[1] as List<ItemListEntry>;

      CategoryTreeResponse? findNode(List<CategoryTreeResponse> nodes) {
        for (final node in nodes) {
          if (node.id == widget.categoryId) return node;
          final found = findNode(node.children);
          if (found != null) return found;
        }
        return null;
      }

      final node = findNode(tree);
      if (!mounted) return;
      setState(() {
        _subcategories = node?.children ?? [];
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _renameCategory() async {
    final controller = TextEditingController(text: _currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await widget.apiService.renameCategory(widget.categoryId, name);
      setState(() {
        _currentName = name;
        _anyChanged = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "$_currentName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.apiService.deleteCategory(widget.categoryId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAddSubcategory() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(
          apiService: widget.apiService,
          parentId: widget.categoryId,
          parentName: _currentName,
        ),
      ),
    );
    if (created == true) {
      _anyChanged = true;
      _load();
    }
  }

  void _openAddItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateItemScreen(
          apiService: widget.apiService,
          prefillCategoryId: widget.categoryId,
          prefillCategoryName: _currentName,
        ),
      ),
    ).then((_) => _load());
  }

  void _openItem(int itemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ItemDetailScreen(itemId: itemId, apiService: widget.apiService),
      ),
    ).then((_) => _load());
  }

  void _openSubcategory(CategoryTreeResponse sub) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          categoryId: sub.id,
          categoryName: sub.name,
          preloadedChildren: sub.children,
          apiService: widget.apiService,
        ),
      ),
    );
    if (changed == true) {
      _anyChanged = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_anyChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentName),
          actions: [
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              tooltip: 'Rename',
              onPressed: _renameCategory,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _deleteCategory,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: SpeedDialFab(
          heroTag: 'cat_detail_${widget.categoryId}',
          items: [
            SpeedDialItem(
              icon: Icons.folder_special_outlined,
              label: 'Add Subcategory',
              onTap: _openAddSubcategory,
            ),
            SpeedDialItem(
              icon: Icons.inventory_2_outlined,
              label: 'Add Item',
              onTap: _openAddItem,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final subcategories = _subcategories ?? [];
    final items = _items ?? [];
    final activeItems = items.where((i) => !isZeroAmount(i)).toList();
    final emptyItems = items.where((i) => isZeroAmount(i)).toList();

    if (subcategories.isEmpty && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Nothing here yet.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Use + to add an item or subcategory.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (subcategories.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.folder_special_outlined,
              label: 'Subcategories',
              color: Theme.of(context).colorScheme.secondary,
            ),
            ...subcategories.map(
              (sub) => _SubcategoryTile(
                category: sub,
                onTap: () => _openSubcategory(sub),
              ),
            ),
          ],
          if (activeItems.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.inventory_2_outlined,
              label: 'Items',
              color: Theme.of(context).colorScheme.primary,
            ),
            ...activeItems.map(
              (item) => ItemTile(
                item: item,
                onTap: () => _openItem(item.id),
              ),
            ),
          ],
          if (emptyItems.isNotEmpty)
            ExpansionTile(
              leading: Icon(
                Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.outline,
                size: 20,
              ),
              title: Text(
                'Empty items (${emptyItems.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              initiallyExpanded: false,
              children: emptyItems
                  .map(
                    (item) => ItemTile(
                      item: item,
                      onTap: () => _openItem(item.id),
                    ),
                  )
                  .toList(),
            ),
          // Extra padding so FAB doesn't cover last item
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final CategoryTreeResponse category;
  final VoidCallback onTap;

  const _SubcategoryTile({required this.category, required this.onTap});

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
      onTap: onTap,
    );
  }
}

/// Reusable item list tile used in category and storage detail screens.
class ItemTile extends StatelessWidget {
  final ItemListEntry item;
  final VoidCallback onTap;

  const ItemTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: _buildLeadingIcon(theme),
      title: Text(item.name),
      subtitle: _buildSubtitle(theme),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    if (item.broken) {
      return const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.build_outlined, color: Colors.white, size: 20),
      );
    }
    if (item.borrowed) {
      return CircleAvatar(
        backgroundColor: theme.colorScheme.tertiary,
        child: Icon(Icons.person_outline,
            color: theme.colorScheme.onTertiary, size: 20),
      );
    }
    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.onPrimaryContainer,
        size: 20,
      ),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final parts = <String>[];
    if (item.quantity != null) {
      final qty = item.quantity! % 1 == 0
          ? item.quantity!.toInt().toString()
          : item.quantity!.toString();
      parts.add(qty);
    }
    if (item.tags.isNotEmpty) parts.add(item.tags.join(', '));
    if (item.expiresAt != null) {
      final diff = item.expiresAt!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        parts.add('Expired');
      } else if (diff <= 30) {
        parts.add('Expires in $diff days');
      }
    }
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );
  }
}
