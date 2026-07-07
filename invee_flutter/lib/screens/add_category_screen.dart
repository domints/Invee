import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/entity_picker_modal.dart';

/// Form screen to create a new category.
/// Returns `true` via pop if the category was created successfully.
class AddCategoryScreen extends StatefulWidget {
  final ApiService apiService;

  /// When provided, the new category will be pre-filled as a child of this.
  final int? parentId;
  final String? parentName;

  const AddCategoryScreen({
    super.key,
    required this.apiService,
    this.parentId,
    this.parentName,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<PickerEntry>? _categoryEntries;
  bool _loadingData = true;
  String? _loadError;

  PickerEntry? _selectedParent;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final tree = await widget.apiService.getCategoryTree();
      if (!mounted) return;
      final entries = PickerEntry.fromCategoryTree(tree);
      setState(() {
        _categoryEntries = entries;
        _loadingData = false;
        // Pre-select parent if provided
        if (widget.parentId != null) {
          _selectedParent = entries.where((e) => e.id == widget.parentId).firstOrNull;
          if (_selectedParent == null && widget.parentName != null) {
            _selectedParent = PickerEntry(
                id: widget.parentId!, label: widget.parentName!);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingData = false;
      });
    }
  }

  Future<void> _pickParent() async {
    final entries = _categoryEntries;
    if (entries == null) return;
    final picked = await showEntityPicker(
      context,
      title: 'Select Parent Category',
      entries: entries,
      selectedId: _selectedParent?.id,
      icon: Icons.folder_special_outlined,
    );
    if (picked != null && mounted) {
      setState(() => _selectedParent = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final catName = _nameController.text.trim();
      await widget.apiService.createCategory(
        name: catName,
        parentId: _selectedParent?.id,
        slug: slugify(catName),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create category: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Category'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _loadingData ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Category name *',
              hintText: 'e.g. Electronics',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_special_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Parent picker
          InkWell(
            onTap: _pickParent,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Parent category (optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_tree_outlined),
                suffixIcon: _selectedParent != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear',
                        onPressed: () =>
                            setState(() => _selectedParent = null),
                      )
                    : const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _selectedParent?.label ?? 'None (root category)',
                style: _selectedParent == null
                    ? TextStyle(color: Theme.of(context).hintColor)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Create Category'),
          ),
        ],
      ),
    );
  }
}
