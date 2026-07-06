import 'package:flutter/material.dart';
import '../models/storage.dart';
import '../services/api_service.dart';
import 'storage_detail_screen.dart';

/// Body-only widget (no Scaffold) listing top-level storages.
/// Embedded inside [MainShell] via an IndexedStack.
class StorageBrowserBody extends StatefulWidget {
  final ApiService apiService;

  const StorageBrowserBody({super.key, required this.apiService});

  @override
  State<StorageBrowserBody> createState() => StorageBrowserBodyState();
}

class StorageBrowserBodyState extends State<StorageBrowserBody> {
  List<StorageTreeResponse>? _tree;
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
      final tree = await widget.apiService.getStorageTree();
      if (mounted) {
        setState(() {
          _tree = tree;
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
    if (_tree == null || _tree!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No storages yet.',
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
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        itemCount: _tree!.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _StorageRootTile(
          storage: _tree![i],
          apiService: widget.apiService,
          onChanged: reload,
        ),
      ),
    );
  }
}

class _StorageRootTile extends StatelessWidget {
  final StorageTreeResponse storage;
  final ApiService apiService;
  final VoidCallback onChanged;

  const _StorageRootTile({
    required this.storage,
    required this.apiService,
    required this.onChanged,
  });

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
      subtitle: storage.children.isNotEmpty
          ? Text(
              '${storage.children.length} sub-storage${storage.children.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => StorageDetailScreen(
              storageId: storage.id,
              storageName: storage.name,
              apiService: apiService,
            ),
          ),
        );
        if (changed == true) onChanged();
      },
    );
  }
}
