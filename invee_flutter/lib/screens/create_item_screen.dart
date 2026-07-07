import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/barcode_type.dart';
import '../models/category.dart';
import '../models/storage.dart';
import '../services/api_service.dart';
import '../utils.dart';
import '../widgets/entity_picker_modal.dart';
import 'item_detail_screen.dart';

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
  final _quantityController = TextEditingController(text: '1');

  List<PickerEntry>? _categoryEntries;
  List<PickerEntry>? _storageEntries;
  bool _loadingData = true;
  String? _loadError;

  PickerEntry? _selectedCategory;
  PickerEntry? _selectedStorage;
  int _quantityType = 0;
  DateTime? _expiresAt;

  bool _saving = false;
  bool _offLookupLoading = false;
  String? _offLookupError;

  /// Image to upload after item creation (camera or gallery).
  XFile? _pendingPhoto;

  /// Image URL from Open Food Facts to upload after creation.
  String? _offImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        _loadingData = false;
        // Pre-select category if provided
        if (widget.prefillCategoryId != null) {
          _selectedCategory = catEntries
              .where((e) => e.id == widget.prefillCategoryId)
              .firstOrNull;
          if (_selectedCategory == null && widget.prefillCategoryName != null) {
            _selectedCategory = PickerEntry(
              id: widget.prefillCategoryId!,
              label: widget.prefillCategoryName!,
            );
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
        if (result.frontImageUrl != null) {
          _offImageUrl = result.frontImageUrl;
        }
      });
      if (mounted && result.productName.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${result.productName}'
                '${result.frontImageUrl != null ? ' — photo will be imported' : ''}'),
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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() {
        _pendingPhoto = image;
        _offImageUrl = null; // camera overrides OFFood image
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() {
        _pendingPhoto = image;
        _offImageUrl = null; // gallery overrides OFFood image
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null && mounted) {
      setState(() => _expiresAt = picked);
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
      final itemName = _nameController.text.trim();
      final itemId = await widget.apiService.createItem(
        name: itemName,
        categoryId: _selectedCategory!.id,
        storageId: _selectedStorage!.id,
        quantityType: _quantityType,
        quantity: _quantityType != 0
            ? double.tryParse(_quantityController.text.trim())
            : null,
        expiresAt: _expiresAt,
        slug: slugify(itemName),
      );

      // Attach barcode code if scanned
      final barcode = widget.prefillBarcode;
      final codeTypeInt = BarcodeType.fromCipherlab(widget.prefillCodeType);
      if (barcode != null && barcode.isNotEmpty && codeTypeInt != null) {
        await widget.apiService.addItemCode(itemId, codeTypeInt, barcode);
      }

      // Upload photo: camera/gallery takes priority, then OFFood image
      if (_pendingPhoto != null) {
        final bytes = await _pendingPhoto!.readAsBytes();
        await widget.apiService.uploadItemImageFromBytes(
          itemId,
          bytes,
          _pendingPhoto!.name,
        );
      } else if (_offImageUrl != null) {
        await widget.apiService
            .uploadItemImageFromUrl(itemId, _offImageUrl!);
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
          _buildCategoryPicker(),
          const SizedBox(height: 16),
          _buildStoragePicker(),
          const SizedBox(height: 16),
          _buildQuantityTypeDropdown(),
          if (_quantityType != 0) ...[
            const SizedBox(height: 16),
            _buildQuantityValueField(),
          ],
          const SizedBox(height: 16),
          _buildExpiryField(),
          const SizedBox(height: 16),
          _buildPhotoSection(),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontFamily: 'monospace'),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              if (_offImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Product photo found — will be imported',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
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

  Widget _buildCategoryPicker() {
    final locked = widget.prefillCategoryId != null;
    return InkWell(
      onTap: locked ? null : _pickCategory,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category *',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.folder_special_outlined),
          suffixIcon: locked
              ? const Icon(Icons.lock_outline, size: 18)
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _selectedCategory?.label ?? 'Select category…',
          style: _selectedCategory == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStoragePicker() {
    return InkWell(
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
    );
  }

  Widget _buildQuantityTypeDropdown() {
    return DropdownButtonFormField<int>(
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
    );
  }

  Widget _buildQuantityValueField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Quantity is required';
        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  Widget _buildExpiryField() {
    return InkWell(
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
    );
  }

  Widget _buildPhotoSection() {
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
          )
        else if (_offImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.image_outlined,
                    size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Product photo from Open Food Facts',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _offImageUrl = null),
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
