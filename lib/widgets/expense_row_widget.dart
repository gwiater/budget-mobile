import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/expense_item.dart';

class ExpenseRowWidget extends StatefulWidget {
  final ExpenseItem item;
  final List<Category> categories;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const ExpenseRowWidget({
    super.key,
    required this.item,
    required this.categories,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<ExpenseRowWidget> createState() => _ExpenseRowWidgetState();
}

class _ExpenseRowWidgetState extends State<ExpenseRowWidget> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl   = TextEditingController(text: widget.item.price);
    _commentCtrl = TextEditingController(text: widget.item.comment);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Category>(
                    value: widget.item.category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategoria',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => widget.item.category = v);
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: false),
                    decoration: const InputDecoration(
                      labelText: 'Kwota',
                      suffixText: 'zł',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    onChanged: (v) {
                      widget.item.price = v;
                      widget.onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Komentarz (opcjonalny)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) {
                widget.item.comment = v;
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
