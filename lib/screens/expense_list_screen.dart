import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/category.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<dynamic> _expenses = [];
  List<Category> _categories = [];
  double _sum = 0;
  bool _loading = false;

  // Filtry — bieżący miesiąc domyślnie
  late DateTime _monthDate;
  Category? _filterCategory;

  @override
  void initState() {
    super.initState();
    _monthDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _load();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ApiClient.getCategories();
    setState(() => _categories = cats.map((c) => Category.fromJson(c)).toList());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lastDay = DateTime(_monthDate.year, _monthDate.month + 1, 0);
      final data = await ApiClient.getExpenses(
        dateFrom: DateFormat('dd.MM.yyyy').format(_monthDate),
        dateTo:   DateFormat('dd.MM.yyyy').format(lastDay),
        categoryId: _filterCategory?.id,
        limit: 200,
      );
      setState(() {
        _expenses = data['items'] as List;
        _sum      = (data['sum'] as num).toDouble();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() => _monthDate =
        DateTime(_monthDate.year, _monthDate.month - 1, 1));
    _load();
  }

  void _nextMonth() {
    setState(() => _monthDate =
        DateTime(_monthDate.year, _monthDate.month + 1, 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nawigacja miesiąc
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left, size: 28)),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'pl').format(_monthDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right, size: 28)),
            ],
          ),
        ),

        // Filtr kategorii
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<Category>(
            value: _filterCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kategoria',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('-- wszystkie --')),
              ..._categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) {
              setState(() => _filterCategory = v);
              _load();
            },
          ),
        ),

        // Suma
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_expenses.length} wydatków',
                  style: const TextStyle(color: Colors.grey)),
              Text('Suma: ${_sum.toStringAsFixed(2)} zł',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const Divider(height: 1),

        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? const Center(child: Text('Brak wydatków'))
                  : ListView.separated(
                      itemCount: _expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = _expenses[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.green[100],
                            child: Text(
                              (e['category'] as String).isNotEmpty
                                  ? (e['category'] as String)[0]
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(e['category'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(e['comment'] ?? '',
                              overflow: TextOverflow.ellipsis),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(e['price'] as num).toStringAsFixed(2)} zł',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              Text(e['date'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
