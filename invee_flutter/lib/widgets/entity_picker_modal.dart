import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/storage.dart';

class PickerEntry {
  final int id;
  final String label;

  const PickerEntry({required this.id, required this.label});

  static List<PickerEntry> fromCategoryTree(
    List<CategoryTreeResponse> nodes, [
    String prefix = '',
  ]) {
    final result = <PickerEntry>[];
    for (final node in nodes) {
      final label = prefix.isEmpty ? node.name : '$prefix / ${node.name}';
      result.add(PickerEntry(id: node.id, label: label));
      result.addAll(fromCategoryTree(node.children, label));
    }
    return result;
  }

  static List<PickerEntry> fromStorageTree(
    List<StorageTreeResponse> nodes, [
    String prefix = '',
  ]) {
    final result = <PickerEntry>[];
    for (final node in nodes) {
      final label = prefix.isEmpty ? node.name : '$prefix / ${node.name}';
      result.add(PickerEntry(id: node.id, label: label));
      result.addAll(fromStorageTree(node.children, label));
    }
    return result;
  }
}

/// Opens a full-screen searchable picker. Returns the selected [PickerEntry]
/// or null if the user cancelled.
Future<PickerEntry?> showEntityPicker(
  BuildContext context, {
  required String title,
  required List<PickerEntry> entries,
  int? selectedId,
  IconData icon = Icons.list_outlined,
}) {
  return Navigator.of(context).push<PickerEntry>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _EntityPickerPage(
        title: title,
        entries: entries,
        selectedId: selectedId,
        icon: icon,
      ),
    ),
  );
}

class _EntityPickerPage extends StatefulWidget {
  final String title;
  final List<PickerEntry> entries;
  final int? selectedId;
  final IconData icon;

  const _EntityPickerPage({
    required this.title,
    required this.entries,
    this.selectedId,
    required this.icon,
  });

  @override
  State<_EntityPickerPage> createState() => _EntityPickerPageState();
}

class _EntityPickerPageState extends State<_EntityPickerPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.entries
        : widget.entries
            .where((e) => e.label.toLowerCase().contains(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _controller.clear,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Text(
                'No results',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final entry = filtered[i];
                final selected = entry.id == widget.selectedId;
                final colorScheme = Theme.of(context).colorScheme;
                return ListTile(
                  leading: Icon(
                    widget.icon,
                    color: selected ? colorScheme.primary : null,
                  ),
                  title: Text(
                    entry.label,
                    style: selected
                        ? TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                  trailing: selected
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(entry),
                );
              },
            ),
    );
  }
}
