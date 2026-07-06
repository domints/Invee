import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final ApiService apiService;

  const ItemListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.apiService,
  });

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<ItemListEntry>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.apiService.getCategoryItems(widget.categoryId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openItem(int itemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemId: itemId,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadItems,
          ),
        ],
      ),
      body: _buildBody(),
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
                onPressed: _loadItems,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items == null || _items!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No items in this category.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.separated(
        itemCount: _items!.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _ItemTile(
          item: _items![i],
          onTap: () => _openItem(_items![i].id),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ItemListEntry item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: _buildLeadingIcon(theme),
      title: Text(item.name),
      subtitle: _buildSubtitle(theme),
      trailing: const Icon(Icons.chevron_right),
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
        child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
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

    if (item.tags.isNotEmpty) {
      parts.add(item.tags.join(', '));
    }

    if (item.expiresAt != null) {
      final now = DateTime.now();
      final diff = item.expiresAt!.difference(now).inDays;
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
