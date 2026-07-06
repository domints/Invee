import 'package:flutter/material.dart';
import '../models/barcode_type.dart';
import '../models/category.dart';
import '../models/storage.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class _CategoryEntry {
  final int id;
  final String displayName;
  const _CategoryEntry({required this.id, required this.displayName});
}

List<_CategoryEntry> _flattenCategories(
    List<CategoryTreeResponse> nodes, String prefix) {
  final result = <_CategoryEntry>[];
  for (final node in nodes) {
    final label = prefix.isEmpty ? node.name : '$prefix / ${node.name}';
    result.add(_CategoryEntry(id: node.id, displayName: label));
    result.addAll(_flattenCategories(node.children, label));
  }
  return result;
}

class CreateItemScreen extends StatefulWidget {
  final ApiService apiService;

  /// When launched from CategoryDetail, the category is pre-selected.
  final int? prefillCategoryId;
  final String? prefillCategoryName;

  /// When launched from a barcode scan that found no item.
  final String? prefillBarcode;
  final String? prefillCodeType;

  const CreateItemScreen({
    super.key,
    required this.apiService,
    this.prefillCategoryId,
    this.prefillCategoryName,
    this.prefillBarcode,
    this.prefillCodeType,
  });

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<_CategoryEntry>? _categories;
  List<StorageEntry>? _storages;
  bool _loadingData = true;
  String? _loadError;

  int? _selectedCategoryId;
  int? _selectedStorageId;
  int _quantityType = 0;
  DateTime? _expiresAt;

  bool _saving = false;
  bool _offLookupLoading = false;
  String? _offLookupError;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.prefillCategoryId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.apiService.getCategoryTree(),
        widget.apiService.getStorages(),
      ]);
      if (!mounted) return;
      final catTree = results[0] as List<CategoryTreeResponse>;
      final storages = results[1] as List<StorageEntry>;
      setState(() {
        _categories = _flattenCategories(catTree, '');
        _storages = storages;
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

  Future<void> _lookupOpenFoodFacts() async {
    final barcode = widget.prefillBarcode;
    if (barcode == null) return;
    setState(() {
      _offLookupLoading = true;
      _offLookupError = null;
    });
    try {
      final result = await widget.apiService.lookupProductByBarcode(barcode);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _offLookupLoading = false;
          _offLookupError = 'Product not found in Open Food Facts.';
        });
        return;
      }
      setState(() {
        _offLookupLoading = false;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.productName;
        }
      });
      if (result.productName.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${result.productName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _offLookupLoading = false;
        _offLookupError = 'Lookup failed: $e';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedStorageId == null) {
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
      final itemId = await widget.apiService.createItem(
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        storageId: _selectedStorageId!,
        quantityType: _quantityType,
        expiresAt: _expiresAt,
      );

      final barcode = widget.prefillBarcode;
      final codeTypeInt = BarcodeType.fromCipherlab(widget.prefillCodeType);
      if (barcode != null && barcode.isNotEmpty && codeTypeInt != null) {
        await widget.apiService.addItemCode(itemId, codeTypeInt, barcode);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ItemDetailScreen(itemId: itemId, apiService: widget.apiService),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create item: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null && mounted) {
      setState(() => _expiresAt = picked);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Item'),
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
          _buildBarcodeCard(),
          const SizedBox(height: 16),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildStorageDropdown(),
          const SizedBox(height: 16),
          _buildQuantityTypeDropdown(),
          const SizedBox(height: 16),
          _buildExpiryField(),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Create Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard() {
    final barcode = widget.prefillBarcode;
    if (barcode == null) return const SizedBox.shrink();

    final typeName = BarcodeType.displayName(widget.prefillCodeType);
    final canLookup = BarcodeType.supportsOpenFoodFacts(widget.prefillCodeType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Barcode',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              barcode,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            Text(
              typeName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (canLookup) ...[
              const SizedBox(height: 12),
              if (_offLookupError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _offLookupError!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _offLookupLoading ? null : _lookupOpenFoodFacts,
                icon: _offLookupLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: const Text('Look up on Open Food Facts'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Name *',
        hintText: 'e.g. Coffee Beans',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label_outline),
      ),
      textCapitalization: TextCapitalization.sentences,
      autofocus: widget.prefillBarcode == null,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final cats = _categories ?? [];
    final locked = widget.prefillCategoryId != null;

    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Category *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.category_outlined),
        suffixIcon: locked
            ? const Icon(Icons.lock_outline, size: 16)
            : null,
      ),
      items: cats
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.displayName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: locked ? null : (v) => setState(() => _selectedCategoryId = v),
      validator: (v) => v == null ? 'Please select a category' : null,
    );
  }

  Widget _buildStorageDropdown() {
    final storages = _storages ?? [];

    return DropdownButtonFormField<int>(
      initialValue: _selectedStorageId,
      decoration: const InputDecoration(
        labelText: 'Storage *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      items: storages
          .map(
            (s) => DropdownMenuItem(
              value: s.id,
              child: Text(s.displayName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedStorageId = v),
      validator: (v) => v == null ? 'Please select a storage location' : null,
    );
  }

  Widget _buildQuantityTypeDropdown() {
    const options = [
      (0, 'None'),
      (1, 'Levels'),
      (2, 'Precise'),
    ];
    return DropdownButtonFormField<int>(
      initialValue: _quantityType,
      decoration: const InputDecoration(
        labelText: 'Quantity Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.straighten_outlined),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
          )
          .toList(),
      onChanged: (v) => setState(() => _quantityType = v ?? 0),
    );
  }

  Widget _buildExpiryField() {
    return InkWell(
      onTap: _pickExpiryDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expiry Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.event_outlined),
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          _expiresAt == null
              ? 'Not set'
              : '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}',
          style: _expiresAt == null
              ? Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor)
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
