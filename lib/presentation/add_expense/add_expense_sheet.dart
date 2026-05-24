import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../providers/expense_providers.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? existingExpense;
  const AddExpenseSheet({super.key, this.existingExpense});
  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _smsController = TextEditingController();
  String _extractedVendor = '';
  String _selectedType = 'expense';
  String _selectedCategory = 'Food';

  final _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Salary', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _amountController.text = widget.existingExpense!.amount.toString();
      _noteController.text = widget.existingExpense!.note ?? '';
      _selectedType = widget.existingExpense!.type;
      _selectedCategory = widget.existingExpense!.categoryId;
    }
  }

  void _parseSMS(String sms) {
    if (sms.trim().isEmpty) return;
    final lowerSms = sms.toLowerCase();

    // 1. Determine Type based on the first occurring keyword
    final incomeKeywords = ['received', 'credited', 'added', 'refund', 'depos'];
    final expenseKeywords = ['sent', 'paid', 'debited', 'spent', 'deducted'];
    
    int firstIncomeIdx = 999999;
    for (var word in incomeKeywords) {
      final idx = lowerSms.indexOf(word);
      if (idx != -1 && idx < firstIncomeIdx) firstIncomeIdx = idx;
    }
    int firstExpenseIdx = 999999;
    for (var word in expenseKeywords) {
      final idx = lowerSms.indexOf(word);
      if (idx != -1 && idx < firstExpenseIdx) firstExpenseIdx = idx;
    }

    if (firstExpenseIdx < firstIncomeIdx) {
      _selectedType = 'expense';
    } else if (firstIncomeIdx < firstExpenseIdx && firstIncomeIdx != 999999) {
      _selectedType = 'income';
    } else {
      _selectedType = 'expense';
    }

    // 2. Extract Amount
    final amountRegex = RegExp(r'(?:rs\.?|inr|\$|₹)\s*([\d,]+(?:\.\d+)?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(sms);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '');
      if (amountStr != null) _amountController.text = amountStr;
    } else {
      final fallbackRegex = RegExp(r'(?:sent|paid|debited|credited|received)[^\d]*([\d,]+(?:\.\d+)?)', caseSensitive: false);
      final fallbackMatch = fallbackRegex.firstMatch(sms);
      if (fallbackMatch != null) {
        final amountStr = fallbackMatch.group(1)?.replaceAll(',', '');
        if (amountStr != null) _amountController.text = amountStr;
      }
    }

    // 3. Extract Note / Recipient (Vendor)
    String rawVendor = '';
    final toRegex = RegExp(r'to\s+(.*?)(?:\s+on|\.|\s+ref|\s+upi)', caseSensitive: false);
    final toMatch = toRegex.firstMatch(sms);
    if (toMatch != null) {
      rawVendor = toMatch.group(1)?.trim() ?? '';
    } else {
      final atRegex = RegExp(r'at\s+(.*?)(?:\s+on|\.|\s+ref|\s+upi|\s+from)', caseSensitive: false);
      final atMatch = atRegex.firstMatch(sms);
      if (atMatch != null) {
        rawVendor = atMatch.group(1)?.trim() ?? '';
      } else {
        // Fallback for ICICI format: ...; MERCHANT NAME credited.
        final semiRegex = RegExp(r';\s*([^;]+)\s+(?:credited|upi)', caseSensitive: false);
        final semiMatch = semiRegex.firstMatch(sms);
        if (semiMatch != null) rawVendor = semiMatch.group(1)?.trim() ?? '';
      }
    }
    
    if (rawVendor.isNotEmpty) {
      _extractedVendor = rawVendor;
      final memory = ref.read(vendorMemoryProvider);

      if (memory.containsKey(rawVendor.toLowerCase())) {
        // Load smart mapped memory
        _noteController.text = memory[rawVendor.toLowerCase()]!.note;
        _selectedCategory = memory[rawVendor.toLowerCase()]!.category;
      } else {
        _noteController.text = rawVendor;
        
        // Default Category Auto-guess
        final lowerNote = rawVendor.toLowerCase();
        if (lowerNote.contains('swiggy') || lowerNote.contains('zomato') || lowerNote.contains('food') || lowerNote.contains('cafe') || lowerNote.contains('starbucks')) {
          _selectedCategory = 'Food';
        } else if (lowerNote.contains('uber') || lowerNote.contains('ola') || lowerNote.contains('irctc') || lowerNote.contains('metro')) {
          _selectedCategory = 'Transport';
        } else if (lowerNote.contains('amazon') || lowerNote.contains('flipkart') || lowerNote.contains('myntra')) {
          _selectedCategory = 'Shopping';
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider).symbol;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.existingExpense != null ? 'Edit Entry' : 'Smart Entry', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.clear_circled_solid, color: CupertinoColors.systemGrey, size: 28),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              if (widget.existingExpense == null) ...[
                CupertinoTextField(
                  controller: _smsController,
                  maxLines: 2,
                  placeholder: 'Paste Bank SMS here to auto-fill...',
                  style: const TextStyle(fontSize: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.3))
                  ),
                  onChanged: _parseSMS,
                ),
                const SizedBox(height: 24),
              ],
              
              SizedBox(
                width: double.infinity,
                child: CupertinoSegmentedControl<String>(
                  groupValue: _selectedType,
                  selectedColor: _selectedType == 'expense' ? CupertinoColors.systemPink : CupertinoColors.activeGreen,
                  borderColor: _selectedType == 'expense' ? CupertinoColors.systemPink : CupertinoColors.activeGreen,
                  children: const {
                    'expense': Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Expense', style: TextStyle(fontWeight: FontWeight.w600))),
                    'income': Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Income', style: TextStyle(fontWeight: FontWeight.w600))),
                  },
                  onValueChanged: (val) => setState(() => _selectedType = val),
                ),
              ),
              const SizedBox(height: 24),

              CupertinoTextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                placeholder: '0.00',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1.0),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Text(currency, style: const TextStyle(fontSize: 24, color: CupertinoColors.systemGrey, fontWeight: FontWeight.w600)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(height: 16),

              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Category', style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
                      Row(
                        children: [
                          Text(_selectedCategory, style: const TextStyle(color: CupertinoColors.systemGrey, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey, size: 16)
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CupertinoTextField(
                controller: _noteController,
                placeholder: 'Add a note (optional)',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(CupertinoIcons.text_alignleft, color: CupertinoColors.systemGrey),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(16)),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _submit,
                  child: const Text('Save Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () => Navigator.pop(modalContext))
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: _categories.indexOf(_selectedCategory)),
                itemExtent: 40,
                onSelectedItemChanged: (idx) => setState(() => _selectedCategory = _categories[idx]),
                children: _categories.map((c) => Center(child: Text(c, style: const TextStyle(fontSize: 22)))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final expense = Expense(
      id: widget.existingExpense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategory,
      timestamp: widget.existingExpense?.timestamp ?? DateTime.now(),
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (_extractedVendor.isNotEmpty) {
      // Learn mapping for the future!
      ref.read(vendorMemoryProvider.notifier).learn(_extractedVendor.toLowerCase(), _noteController.text, _selectedCategory);
    }

    final repo = ref.read(expenseRepositoryProvider);
    if (widget.existingExpense != null) {
      repo?.updateExpense(expense);
    } else {
      repo?.addExpense(expense);
    }
    Navigator.of(context).pop();
  }
}
