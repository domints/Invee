import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart' show ImageDto;
import '../models/storage_detail.dart';
import '../services/api_service.dart';
import '../utils/quantity_utils.dart';
import '../widgets/speed_dial_fab.dart';
import 'add_storage_screen.dart';
import 'category_detail_screen.dart' show ItemTile;
import 'create_item_screen.dart';
import 'item_detail_screen.dart';

/// Drill-down screen for a single storage. Shows sub-storages and items.
/// Returns `true` via pop when the storage tree has been mutated.
class StorageDetailScreen extends StatefulWidget {
  final int storageId;
  final String storageName;
  final ApiService apiService;

  const StorageDetailScreen({
    super.key,
    required this.storageId,
    required this.storageName,
    required this.apiService,
  });

  @override
  State<StorageDetailScreen> createState() => _StorageDetailScreenState();
}

class _StorageDetailScreenState extends State<StorageDetailScreen> {
  late String _currentName;
  StorageItemsResponse? _detail;
  bool _loading = true;
  String? _error;
  bool _anyChanged = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.storageName;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail =
          await widget.apiService.getStorageDetail(widget.storageId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _currentName = detail.name;
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

  Future<void> _renameStorage() async {
    final detail = _detail;
    final controller = TextEditingController(text: _currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Storage'),
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
      await widget.apiService.updateStorage(
        widget.storageId,
        name,
        detail?.type.id ?? 1,
      );
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

  Future<void> _deleteStorage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Storage'),
        content: Text('Delete "$_currentName"? This cannot be undone.'),
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
      await widget.apiService.deleteStorage(widget.storageId);
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

  Future<void> _uploadImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      await widget.apiService.uploadStorageImageFromBytes(
          widget.storageId, bytes, file.name);
      if (mounted) _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteImage(int imageId) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Remove this image from the storage?'),
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
      await widget.apiService.deleteStorageImage(widget.storageId, imageId);
      if (mounted) _load();
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

  void _openAddSubStorage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStorageScreen(
          apiService: widget.apiService,
          parentId: widget.storageId,
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
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CreateItemScreen(
              apiService: widget.apiService,
            ),
          ),
        )
        .then((_) => _load());
  }

  void _openItem(int itemId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                ItemDetailScreen(itemId: itemId, apiService: widget.apiService),
          ),
        )
        .then((_) => _load());
  }

  void _openSubStorage(StorageListEntry sub) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StorageDetailScreen(
          storageId: sub.id,
          storageName: sub.name,
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
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Upload photo',
              onPressed: _loading ? null : _uploadImage,
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline),
              tooltip: 'Rename',
              onPressed: _renameStorage,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _deleteStorage,
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
          heroTag: 'sto_detail_${widget.storageId}',
          items: [
            SpeedDialItem(
              icon: Icons.warehouse_outlined,
              label: 'Add Sub-storage',
              onTap: _openAddSubStorage,
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

    final detail = _detail;
    if (detail == null) return const SizedBox();

    final hasContent = detail.childStorages.isNotEmpty ||
        detail.items.isNotEmpty ||
        detail.images.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nothing here yet.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'Use + to add an item or sub-storage.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (detail.images.isNotEmpty)
            _StorageImageGallery(
              images: detail.images,
              apiService: widget.apiService,
              onDelete: _deleteImage,
            ),
          if (detail.childStorages.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.warehouse_outlined,
              label: 'Sub-storages',
              color: Theme.of(context).colorScheme.tertiary,
            ),
            ...detail.childStorages.map(
              (sub) => _SubStorageTile(
                storage: sub,
                onTap: () => _openSubStorage(sub),
              ),
            ),
          ],
          if (detail.items.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.inventory_2_outlined,
              label: 'Items',
              color: Theme.of(context).colorScheme.primary,
            ),
            ...detail.items
                .where((i) => !isZeroAmount(i))
                .map(
                  (item) => ItemTile(
                    item: item,
                    onTap: () => _openItem(item.id),
                  ),
                ),
            if (detail.items.any(isZeroAmount))
              ExpansionTile(
                leading: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.outline,
                  size: 20,
                ),
                title: Text(
                  'Empty items (${detail.items.where(isZeroAmount).length})',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                initiallyExpanded: false,
                children: detail.items
                    .where(isZeroAmount)
                    .map(
                      (item) => ItemTile(
                        item: item,
                        onTap: () => _openItem(item.id),
                      ),
                    )
                    .toList(),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StorageImageGallery extends StatelessWidget {
  final List<ImageDto> images;
  final ApiService apiService;
  final void Function(int imageId) onDelete;

  const _StorageImageGallery({
    required this.images,
    required this.apiService,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (ctx, i) {
          final img = images[i];
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
                      onPressed: () => onDelete(img.id),
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

class _SubStorageTile extends StatelessWidget {
  final StorageListEntry storage;
  final VoidCallback onTap;

  const _SubStorageTile({required this.storage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        child: Icon(
          Icons.warehouse_outlined,
          color: theme.colorScheme.onTertiaryContainer,
          size: 20,
        ),
      ),
      title: Text(storage.name),
      subtitle: Text(
        storage.type.name,
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
