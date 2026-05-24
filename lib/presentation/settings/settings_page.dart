import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _dailyController;
  late TextEditingController _monthlyController;
  late String _localCurrency;
  late bool _localNotifications;

  @override
  void initState() {
    super.initState();
    final budget = ref.read(budgetProvider);
    _dailyController = TextEditingController(text: budget.dailyLimit.toStringAsFixed(0));
    _monthlyController = TextEditingController(text: budget.monthlyLimit?.toStringAsFixed(0) ?? '');
    _localCurrency = ref.read(currencyProvider);
    _localNotifications = ref.read(notificationsEnabledProvider);
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final daily = double.tryParse(_dailyController.text) ?? ref.read(budgetProvider).dailyLimit;
    final monthly = double.tryParse(_monthlyController.text);
    
    ref.read(budgetProvider.notifier).updateLimit(daily, monthly);
    ref.read(currencyProvider.notifier).setCurrency(_localCurrency);
    ref.read(notificationsEnabledProvider.notifier).setEnabled(_localNotifications);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Saved'),
        content: const Text('Your app settings have been successfully updated.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveSettings,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            CupertinoListSection.insetGrouped(
              header: const Text('PROFILE'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_circle, size: 30, color: CupertinoColors.activeBlue),
                  title: Text(user['name']!),
                  subtitle: Text(user['email']!),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('BUDGET'),
              children: [
                CupertinoListTile(
                  title: const Text('Daily Budget'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_localCurrency.symbol, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: CupertinoTextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          placeholder: '0.00',
                          controller: _dailyController,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Monthly Budget'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_localCurrency.symbol, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: CupertinoTextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          placeholder: 'None',
                          controller: _monthlyController,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('PREFERENCES'),
              children: [
                CupertinoListTile(
                  title: const Text('Currency'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showCurrencyPicker(context, _localCurrency),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_localCurrency.symbol} $_localCurrency'),
                        const Icon(CupertinoIcons.chevron_up_chevron_down, size: 16),
                      ],
                    ),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Notifications'),
                  trailing: CupertinoSwitch(
                    value: _localNotifications,
                    onChanged: (val) => setState(() => _localNotifications = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton.filled(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, String current) {
    final currencies = ['INR', 'USD', 'EUR', 'GBP'];
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
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(modalContext),
                )
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: currencies.indexOf(current)),
                itemExtent: 32,
                onSelectedItemChanged: (idx) => setState(() => _localCurrency = currencies[idx]),
                children: currencies.map((c) => Text(c)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
