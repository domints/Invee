import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final int itemId;
  final ApiService apiService;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    required this.apiService,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ItemResponse? _item;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await widget.apiService.getItem(widget.itemId);
      if (mounted) setState(() => _item = item);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.name ?? 'Item Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadItem,
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
                onPressed: _loadItem,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_item == null) return const SizedBox();

    return _ItemDetailView(item: _item!, apiService: widget.apiService);
  }
}

class _ItemDetailView extends StatelessWidget {
  final ItemResponse item;
  final ApiService apiService;

  const _ItemDetailView({required this.item, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (item.images.isNotEmpty) _buildImageGallery(context),
        _buildStatusChips(context),
        _buildInfoSection(context),
        if (item.note != null && item.note!.isNotEmpty)
          _buildNoteSection(context),
        if (item.tags.isNotEmpty) _buildTagsSection(context),
        if (item.codes.isNotEmpty) _buildCodesSection(context),
        if (item.borrowings.isNotEmpty) _buildBorrowingsSection(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: item.images.length,
        itemBuilder: (ctx, i) {
          final img = item.images[i];
          final url = apiService.imageUrl(img.url);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChips(BuildContext context) {
    final chips = <Widget>[];

    if (item.broken) {
      chips.add(_StatusChip(
        label: 'Broken',
        icon: Icons.build_outlined,
        color: Colors.red,
      ));
    }
    if (item.isBorrowed) {
      chips.add(_StatusChip(
        label: 'Borrowed',
        icon: Icons.person_outline,
        color: Colors.orange,
      ));
    }
    if (item.expiresAt != null) {
      final diff = item.expiresAt!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        chips.add(_StatusChip(
          label: 'Expired',
          icon: Icons.schedule,
          color: Colors.red,
        ));
      } else if (diff <= 30) {
        chips.add(_StatusChip(
          label: 'Expires in $diff days',
          icon: Icons.schedule,
          color: Colors.amber,
        ));
      }
    }

    if (chips.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_InfoRow>[];

    rows.add(_InfoRow(
      icon: Icons.category_outlined,
      label: 'Category',
      value: item.category.name,
    ));

    rows.add(_InfoRow(
      icon: Icons.warehouse_outlined,
      label: 'Storage',
      value: item.storage.name,
    ));

    if (item.quantity != null) {
      final qty = item.quantity! % 1 == 0
          ? item.quantity!.toInt().toString()
          : item.quantity!.toString();
      rows.add(_InfoRow(
        icon: Icons.format_list_numbered,
        label: 'Quantity',
        value: qty,
      ));
    }

    rows.add(_InfoRow(
      icon: Icons.calendar_today_outlined,
      label: 'Added',
      value: _formatDate(item.addedAt),
    ));

    if (item.expiresAt != null) {
      rows.add(_InfoRow(
        icon: Icons.event_outlined,
        label: 'Expires',
        value: _formatDate(item.expiresAt!),
      ));
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Details',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ...rows.map((r) => _buildInfoRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, _InfoRow row) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(row.icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(row.value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Note',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.note!, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: item.tags
                  .map((t) => Chip(
                        label: Text(t),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodesSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Barcodes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...item.codes.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _codeTypeName(c.codeType),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.contents,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final active = item.borrowings
        .where((b) => b.status == '1' || b.status == 'Active' || b.status == '2')
        .toList();
    if (active.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Currently Borrowed',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...active.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.borrower, style: theme.textTheme.bodyMedium),
                          if (b.start != null)
                            Text(
                              'Since ${_formatDate(b.start!)}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _codeTypeName(String raw) {
    const names = {
      '0': 'QR',
      '1': 'EAN-13',
      '2': 'EAN-8',
      '3': 'UPC-A',
      '4': 'Code128',
      '5': 'Code39',
      '6': 'DataMatrix',
      '7': 'PDF417',
      '8': 'Aztec',
      '9': 'ITF-14',
    };
    return names[raw] ?? raw;
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
