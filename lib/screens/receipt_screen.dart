import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/category.dart';
import '../models/expense_item.dart';
import '../widgets/expense_row_widget.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  List<Category> _categories       = [];
  List<Category> _savingCategories = [];
  List<ExpenseItem> _items         = [];
  Category? _paymentCategory;
  DateTime _date                   = DateTime.now();
  bool _loading                    = false;
  bool _saving                     = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final cats   = await ApiClient.getCategories();
      final saving = await ApiClient.getSavingCategories();
      setState(() {
        _categories       = cats.map((c) => Category.fromJson(c)).toList();
        _savingCategories = saving.map((c) => Category.fromJson(c)).toList();
        _paymentCategory  = _savingCategories.isNotEmpty ? _savingCategories.first : null;
        _items = [ExpenseItem(), ExpenseItem(), ExpenseItem()];
      });
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('pl'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  double get _total =>
      _items.fold(0, (sum, item) => sum + item.parsedPrice);

  Future<void> _save() async {
    final validItems = _items.where((i) => i.isValid).toList();
    if (validItems.isEmpty) {
      setState(() => _errorMsg = 'Dodaj co najmniej jedną pozycję z kategorią i kwotą');
      return;
    }

    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      final dateStr = DateFormat('dd.MM.yyyy').format(_date);
      await ApiClient.createExpenses({
        'date': dateStr,
        'saving_category_id': _paymentCategory?.id ?? 0,
        'items': validItems.map((i) => {
          'category_id': i.category!.id,
          'price': i.parsedPrice.toStringAsFixed(2),
          'comment': i.comment,
        }).toList(),
      });

      setState(() {
        _successMsg = 'Zapisano ${validItems.length} wydatków!';
        _items = [ExpenseItem(), ExpenseItem(), ExpenseItem()];
        _date  = DateTime.now();
      });
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header — data i konto
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(DateFormat('dd.MM.yyyy').format(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Category>(
                  value: _paymentCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Płatność',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _savingCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentCategory = v),
                ),
              ),
            ],
          ),
        ),

        // Komunikaty
        if (_successMsg != null)
          Container(
            width: double.infinity,
            color: Colors.green[100],
            padding: const EdgeInsets.all(12),
            child: Text('✓ $_successMsg',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        if (_errorMsg != null)
          Container(
            width: double.infinity,
            color: Colors.red[100],
            padding: const EdgeInsets.all(12),
            child: Text(_errorMsg!,
                style: const TextStyle(color: Colors.red)),
          ),

        // Lista pozycji
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              ..._items.asMap().entries.map((e) => ExpenseRowWidget(
                    key: ValueKey(e.key),
                    item: e.value,
                    categories: _categories,
                    onDelete: () => setState(() {
                      if (_items.length > 1) _items.removeAt(e.key);
                    }),
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => setState(() => _items.add(ExpenseItem())),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj pozycję'),
              ),
            ],
          ),
        ),

        // Footer — suma i zapis
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Suma: ${_total.toStringAsFixed(2)} zł',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Zapisz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
