import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/category.dart';

class QuickExpenseScreen extends StatefulWidget {
  const QuickExpenseScreen({super.key});
  @override
  State<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

class _QuickExpenseScreenState extends State<QuickExpenseScreen> {
  List<Category> _categories       = [];
  List<Category> _savingCategories = [];
  Category? _selectedCategory;
  Category? _selectedAccount;
  final _priceCtrl   = TextEditingController();
  final _commentCtrl = TextEditingController();
  DateTime _date     = DateTime.now();
  bool _loading      = true;
  bool _saving       = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats   = await ApiClient.getCategories();
      final saving = await ApiClient.getSavingCategories();
      setState(() {
        _categories       = cats.map((c) => Category.fromJson(c)).toList();
        _savingCategories = saving.map((c) => Category.fromJson(c)).toList();
        _selectedCategory = _categories.firstWhere(
          (c) => c.name == 'Spożywcze',
          orElse: () => _categories.first,
        );
        _selectedAccount = _savingCategories.firstWhere(
          (c) => c.name == 'Portfel: income',
          orElse: () => _savingCategories.first,
        );
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
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  double get _parsedPrice {
    final raw = _priceCtrl.text.replaceAll(',', '.').trim();
    final parts = RegExp(r'[+\-]?[0-9]*\.?[0-9]+').allMatches(raw);
    return parts.fold(0.0, (sum, m) => sum + double.parse(m.group(0)!));
  }

  Future<void> _save() async {
    if (_selectedCategory == null) {
      setState(() => _errorMsg = 'Wybierz kategorię');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty || _parsedPrice <= 0) {
      setState(() => _errorMsg = 'Podaj kwotę');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _errorMsg = null; _successMsg = null; });

    try {
      await ApiClient.createExpenses({
        'date': DateFormat('dd.MM.yyyy').format(_date),
        'saving_category_id': _selectedAccount?.id ?? 0,
        'items': [{
          'category_id': _selectedCategory!.id,
          'price':       _parsedPrice.toStringAsFixed(2),
          'comment':     _commentCtrl.text.trim(),
        }],
      });

      setState(() {
        _successMsg  = '✓ Dodano: ${_selectedCategory!.name} — ${_parsedPrice.toStringAsFixed(2)} zł';
        _priceCtrl.text   = '';
        _commentCtrl.text = '';
        _date = DateTime.now();
        _selectedCategory = _categories.firstWhere(
          (c) => c.name == 'Spożywcze',
          orElse: () => _categories.first,
        );
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
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Komunikat sukcesu
          if (_successMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_successMsg!,
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),

          // Błąd
          if (_errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_errorMsg!,
                  style: const TextStyle(color: Colors.red)),
            ),

          // Kategoria
          const Text('Kategoria',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 14),

          // Kwota
          const Text('Kwota (zł)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: false),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '0.00',
              suffixText: 'zł',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Komentarz
          const Text('Komentarz (opcjonalny)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _commentCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'np. Biedronka',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Data
          const Text('Data',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd.MM.yyyy').format(_date),
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 14),

          // Konto
          const Text('Konto',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            value: _selectedAccount,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: _savingCategories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccount = v),
          ),
          const SizedBox(height: 24),

          // Przycisk
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text('DODAJ WYDATEK',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
