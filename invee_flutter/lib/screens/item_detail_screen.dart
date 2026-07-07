import 'package:flutter/material.dart';
import '../models/barcode_type.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'edit_item_screen.dart';
import 'qr_scanner_screen.dart';

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

  Future<void> _openEdit(ItemResponse item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditItemScreen(
          item: item,
          apiService: widget.apiService,
        ),
      ),
    );
    if (updated == true) _loadItem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.name ?? 'Item Detail'),
        actions: [
          if (_item != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit item',
              onPressed: () => _openEdit(_item!),
            ),
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

    return _ItemDetailView(
      item: _item!,
      apiService: widget.apiService,
      onReload: _loadItem,
    );
  }
}

class _ItemDetailView extends StatefulWidget {
  final ItemResponse item;
  final ApiService apiService;
  final VoidCallback onReload;

  const _ItemDetailView({
    required this.item,
    required this.apiService,
    required this.onReload,
  });

  @override
  State<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<_ItemDetailView> {
  ItemResponse get item => widget.item;
  ApiService get apiService => widget.apiService;

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
        _buildTagsSection(context),
        _buildCodesSection(context),
        if (item.borrowings.isNotEmpty) _buildBorrowingsSection(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _deleteImage(BuildContext context, int imageId) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Remove this image from the item?'),
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
      await apiService.deleteItemImage(item.id, imageId);
      if (mounted) widget.onReload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48, color: Colors.grey),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 20),
                      tooltip: 'Delete image',
                      onPressed: () => _deleteImage(context, img.id),
                    ),
                  ),
                ),
              ],
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
          _buildInfoRow(
            context,
            icon: Icons.category_outlined,
            label: 'Category',
            value: item.category.name,
          ),
          _buildInfoRow(
            context,
            icon: Icons.warehouse_outlined,
            label: 'Storage',
            value: item.storage.name,
          ),
          _buildQuantityRow(context),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Added',
            value: _formatDate(item.addedAt),
          ),
          if (item.expiresAt != null)
            _buildInfoRow(
              context,
              icon: Icons.event_outlined,
              label: 'Expires',
              value: _formatDate(item.expiresAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityRow(BuildContext context) {
    final theme = Theme.of(context);
    final qty = item.quantity == null
        ? null
        : item.quantity! % 1 == 0
            ? item.quantity!.toInt().toString()
            : item.quantity!.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.format_list_numbered, size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  qty ?? '—',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (_quantityTypeInt(item.quantityType) != 0) ...[
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              tooltip: 'Decrease',
              onPressed: () => _adjustQuantity(context, -1),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Increase',
              onPressed: () => _adjustQuantity(context, 1),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit quantity',
            onPressed: () => _showEditQuantityDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustQuantity(BuildContext context, double delta) async {
    final messenger = ScaffoldMessenger.of(context);
    final newQty = (item.quantity ?? 0) + delta;
    try {
      await apiService.updateItem(
        id: item.id,
        name: item.name,
        categoryId: item.category.id,
        storageId: item.storage.id,
        quantityType: _quantityTypeInt(item.quantityType),
        quantity: newQty,
        broken: item.broken,
        note: item.note,
        slug: item.slug,
        expiresAt: item.expiresAt,
      );
      if (mounted) widget.onReload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEditQuantityDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final initialText = item.quantity?.toString() ?? '';
    final controller = TextEditingController(text: initialText)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialText.length,
      );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final raw = controller.text.trim();
    controller.dispose();
    if (confirmed != true || !mounted) return;
    final newQty = raw.isEmpty ? null : double.tryParse(raw);

    try {
      await apiService.updateItem(
        id: item.id,
        name: item.name,
        categoryId: item.category.id,
        storageId: item.storage.id,
        quantityType: _quantityTypeInt(item.quantityType),
        quantity: newQty,
        broken: item.broken,
        note: item.note,
        slug: item.slug,
        expiresAt: item.expiresAt,
      );
      if (mounted) widget.onReload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
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
                Icon(Icons.label_outline, size: 18,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tags',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit tags',
                  onPressed: () => _showEditTagsSheet(context),
                ),
              ],
            ),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.tags
                    .map((t) => Chip(
                          label: Text(t),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text('No tags', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTagsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TagEditorSheet(
        item: item,
        apiService: apiService,
        onSaved: widget.onReload,
      ),
    );
  }

  Future<void> _deleteBarcode(BuildContext context, int codeId) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Barcode'),
        content: const Text('Remove this barcode from the item?'),
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
      await apiService.deleteItemCode(item.id, codeId);
      if (mounted) widget.onReload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete barcode: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addBarcode(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<Map<String, String?>>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null || !mounted) return;

    final contents = result['data'];
    final codeTypeStr = result['codeType'];
    if (contents == null || contents.isEmpty) return;

    final codeType = BarcodeType.fromCipherlab(codeTypeStr);
    if (codeType == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Unsupported barcode format: ${codeTypeStr ?? 'unknown'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await apiService.addItemCode(item.id, codeType, contents);
      if (mounted) widget.onReload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to add barcode: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                Icon(Icons.qr_code, size: 18,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Barcodes',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  tooltip: 'Add barcode',
                  onPressed: () => _addBarcode(context),
                ),
              ],
            ),
            if (item.codes.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'No barcodes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ...item.codes.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Delete barcode',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteBarcode(context, c.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final active = item.borrowings
        .where((b) =>
            b.status == '1' || b.status == 'Active' || b.status == '2')
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
                Icon(Icons.person_outline, size: 18,
                    color: theme.colorScheme.primary),
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
                          Text(b.borrower,
                              style: theme.textTheme.bodyMedium),
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

  String _codeTypeName(String raw) => BarcodeType.displayName(raw);

  int _quantityTypeInt(String type) {
    final asInt = int.tryParse(type);
    if (asInt != null) return asInt;
    switch (type.toLowerCase()) {
      case 'levels':
        return 1;
      case 'precise':
        return 2;
      default:
        return 0;
    }
  }
}

// ---------------------------------------------------------------------------
// Tag editor bottom sheet
// ---------------------------------------------------------------------------

class _TagEditorSheet extends StatefulWidget {
  final ItemResponse item;
  final ApiService apiService;
  final VoidCallback onSaved;

  const _TagEditorSheet({
    required this.item,
    required this.apiService,
    required this.onSaved,
  });

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  List<TagDto>? _allTags;
  Set<int> _selectedIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _newTagController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _creatingTag = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tags = await widget.apiService.getTags();
      if (!mounted) return;
      final selectedIds = tags
          .where((t) => widget.item.tags.contains(t.name))
          .map((t) => t.id)
          .toSet();
      setState(() {
        _allTags = tags;
        _selectedIds = selectedIds;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creatingTag = true);
    try {
      final id = await widget.apiService.createTag(name);
      if (!mounted) return;
      final newTag = TagDto(id: id, name: name);
      setState(() {
        _allTags = [...(_allTags ?? []), newTag];
        _selectedIds = {..._selectedIds, id};
        _newTagController.clear();
        _creatingTag = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingTag = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create tag: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.apiService.setItemTags(
          widget.item.id, _selectedIds.toList());
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save tags: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(
                children: [
                  Text('Edit Tags',
                      style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: const Text('Save'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: _buildBody(theme, scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadTags, child: const Text('Retry')),
          ],
        ),
      );
    }
    final allTags = _allTags ?? [];
    final filteredTags = _searchQuery.isEmpty
        ? allTags
        : allTags
            .where((t) =>
                t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // New tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTagController,
                decoration: const InputDecoration(
                  labelText: 'New tag name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _createTag(),
              ),
            ),
            const SizedBox(width: 8),
            _creatingTag
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create tag',
                    onPressed: _createTag,
                  ),
          ],
        ),
        const SizedBox(height: 12),
        // Search filter
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search tags',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 16),
        if (allTags.isEmpty)
          Text('No tags yet. Create one above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ))
        else if (filteredTags.isEmpty)
          Text('No tags match "$_searchQuery".',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredTags.map((tag) {
              final selected = _selectedIds.contains(tag.id);
              return FilterChip(
                label: Text(tag.name),
                selected: selected,
                onSelected: (val) => setState(() {
                  if (val) {
                    _selectedIds = {..._selectedIds, tag.id};
                  } else {
                    _selectedIds = _selectedIds
                        .where((id) => id != tag.id)
                        .toSet();
                  }
                }),
              );
            }).toList(),
          ),
      ],
    );
  }
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
