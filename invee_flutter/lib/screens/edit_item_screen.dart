import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/storage.dart';
import '../services/api_service.dart';
import '../widgets/entity_picker_modal.dart';

/// Edit screen for an existing item. Receives the full [ItemResponse] and
/// calls `PUT /api/items/{id}` on save. Supports photo capture.
class EditItemScreen extends StatefulWidget {
  final ItemResponse item;
  final ApiService apiService;

  const EditItemScreen({
    super.key,
    required this.item,
    required this.apiService,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _quantityController;

  List<PickerEntry>? _categoryEntries;
  List<PickerEntry>? _storageEntries;
  bool _loadingData = true;
  String? _loadError;

  PickerEntry? _selectedCategory;
  PickerEntry? _selectedStorage;
  late int _quantityType;
  late bool _broken;
  DateTime? _expiresAt;

  bool _saving = false;
  XFile? _pendingPhoto;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _noteController = TextEditingController(text: item.note ?? '');
    _quantityController =
        TextEditingController(text: item.quantity?.toString() ?? '');
    _quantityType = _quantityTypeInt(item.quantityType);
    _broken = item.broken;
    _expiresAt = item.expiresAt;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.apiService.getCategoryTree(),
        widget.apiService.getStorageTree(),
      ]);
      if (!mounted) return;
      final catTree = results[0] as List<CategoryTreeResponse>;
      final stoTree = results[1] as List<StorageTreeResponse>;
      final catEntries = PickerEntry.fromCategoryTree(catTree);
      final stoEntries = PickerEntry.fromStorageTree(stoTree);
      setState(() {
        _categoryEntries = catEntries;
        _storageEntries = stoEntries;
        // Try to pre-select current values
        _selectedCategory = catEntries
            .where((e) => e.id == widget.item.category.id)
            .firstOrNull;
        _selectedCategory ??= PickerEntry(
          id: widget.item.category.id,
          label: widget.item.category.name,
        );
        _selectedStorage = stoEntries
            .where((e) => e.id == widget.item.storage.id)
            .firstOrNull;
        _selectedStorage ??= PickerEntry(
          id: widget.item.storage.id,
          label: widget.item.storage.name,
        );
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingData = false;
      });
    }
  }

  Future<void> _pickCategory() async {
    final entries = _categoryEntries;
    if (entries == null) return;
    final picked = await showEntityPicker(
      context,
      title: 'Select Category',
      entries: entries,
      selectedId: _selectedCategory?.id,
      icon: Icons.folder_special_outlined,
    );
    if (picked != null && mounted) {
      setState(() => _selectedCategory = picked);
    }
  }

  Future<void> _pickStorage() async {
    final entries = _storageEntries;
    if (entries == null) return;
    final picked = await showEntityPicker(
      context,
      title: 'Select Storage',
      entries: entries,
      selectedId: _selectedStorage?.id,
      icon: Icons.warehouse_outlined,
    );
    if (picked != null && mounted) {
      setState(() => _selectedStorage = picked);
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null && mounted) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _pendingPhoto = image);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _pendingPhoto = image);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedStorage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a storage location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.apiService.updateItem(
        id: widget.item.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        storageId: _selectedStorage!.id,
        quantityType: _quantityType,
        quantity: _quantityType != 0
            ? double.tryParse(_quantityController.text.trim())
            : null,
        broken: _broken,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        slug: widget.item.slug,
        expiresAt: _expiresAt,
      );

      // Upload pending photo if any
      if (_pendingPhoto != null) {
        setState(() => _uploadingPhoto = true);
        final bytes = await _pendingPhoto!.readAsBytes();
        await widget.apiService.uploadItemImageFromBytes(
          widget.item.id,
          bytes,
          _pendingPhoto!.name,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _quantityTypeInt(String type) {
    switch (type.toLowerCase()) {
      case 'levels':
      case '1':
        return 1;
      case 'precise':
      case '2':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        actions: [
          if (_saving || _uploadingPhoto)
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
          // Name
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Category picker
          InkWell(
            onTap: _pickCategory,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_special_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _selectedCategory?.label ?? 'Select category…',
                style: _selectedCategory == null
                    ? TextStyle(color: Theme.of(context).hintColor)
                    : null,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Storage picker
          InkWell(
            onTap: _pickStorage,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Storage *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warehouse_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _selectedStorage?.label ?? 'Select storage…',
                style: _selectedStorage == null
                    ? TextStyle(color: Theme.of(context).hintColor)
                    : null,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity type
          DropdownButtonFormField<int>(
            initialValue: _quantityType,
            decoration: const InputDecoration(
              labelText: 'Quantity type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('None')),
              DropdownMenuItem(value: 1, child: Text('Levels')),
              DropdownMenuItem(value: 2, child: Text('Precise')),
            ],
            onChanged: (v) => setState(() => _quantityType = v ?? 0),
          ),
          if (_quantityType != 0) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Quantity is required';
                }
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // Expiry date
          InkWell(
            onTap: _pickExpiryDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Expiry date',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: _expiresAt != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _expiresAt = null),
                      )
                    : const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _expiresAt == null
                    ? 'Not set'
                    : '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}',
                style: _expiresAt == null
                    ? TextStyle(color: Theme.of(context).hintColor)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Optional notes about this item',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Broken toggle
          SwitchListTile(
            value: _broken,
            onChanged: (v) => setState(() => _broken = v),
            title: const Text('Broken'),
            secondary: const Icon(Icons.build_outlined),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Photo section
          _buildPhotoSection(context),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: (_saving || _uploadingPhoto) ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_uploadingPhoto ? 'Uploading photo…' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photo', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        if (_pendingPhoto != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _pendingPhoto!.name,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _pendingPhoto = null),
                ),
              ],
            ),
          ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }
}
