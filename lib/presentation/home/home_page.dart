import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../../domain/models/expense.dart';
import '../add_expense/add_expense_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyBudgetMetricsProvider);
    final expensesAsync = ref.watch(todayExpensesProvider);
    final currency = ref.watch(currencyProvider).symbol;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Dashboard'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add_circled_solid),
          onPressed: () => _showAddExpense(context),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: metricsAsync.when(
                  data: (metrics) => _BudgetCard(
                    limit: metrics.limit, 
                    spent: metrics.spent, 
                    remaining: metrics.remaining, 
                    currency: currency
                  ),
                  loading: () => const CupertinoActivityIndicator(),
                  error: (e, st) => Text('Error: $e'),
                ),
              ),
            ),
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No expenses today.')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];
                      final isIncome = expense.type == 'income';
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: CupertinoColors.destructiveRed,
                          child: const Icon(CupertinoIcons.trash_fill, color: CupertinoColors.white),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: CupertinoColors.activeBlue,
                          child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            ref.read(expenseRepositoryProvider)?.deleteExpense(expense.id);
                            return true;
                          } else {
                            _showAddExpense(context, expense);
                            return false;
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CupertinoListTile(
                            leadingSize: 40,
                            leading: Container(
                              decoration: BoxDecoration(color: CupertinoColors.systemGroupedBackground, borderRadius: BorderRadius.circular(12)),
                              child: Icon(isIncome ? CupertinoIcons.arrow_down_left_circle_fill : CupertinoIcons.arrow_up_right_circle_fill, 
                                        color: isIncome ? CupertinoColors.activeGreen : CupertinoColors.systemPink),
                            ),
                            title: Text(expense.categoryId, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: expense.note != null ? Text(expense.note!, style: const TextStyle(color: CupertinoColors.systemGrey)) : null,
                            trailing: Text(
                              '${isIncome ? '+' : '-'}$currency${expense.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isIncome ? CupertinoColors.activeGreen : CupertinoColors.label.resolveFrom(context)
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: expenses.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: CupertinoActivityIndicator()),
              error: (e, st) => SliverToBoxAdapter(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context, [Expense? existingExpense]) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddExpenseSheet(existingExpense: existingExpense),
    );
  }
}

class BudgetRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  BudgetRingPainter({required this.progress, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, sweepAngle, false,
      Paint()..color = progressColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant BudgetRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.trackColor != trackColor || oldDelegate.progressColor != progressColor;
  }
}

class _BudgetCard extends StatelessWidget {
  final double limit;
  final double spent;
  final double remaining;
  final String currency;

  const _BudgetCard({required this.limit, required this.spent, required this.remaining, required this.currency});

  @override
  Widget build(BuildContext context) {
    final progress = limit > 0 ? (spent / limit) : 0.0;
    final isOverspent = remaining < 0;
    
    final progressColor = isOverspent ? CupertinoColors.systemRed : CupertinoColors.white;
    final trackColor = CupertinoColors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E5CE6), Color(0xFF8E8CF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5E5CE6).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Budget', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                  '$currency${limit.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 32, letterSpacing: -1.0, fontWeight: FontWeight.w800, color: CupertinoColors.white),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Color(0x33000000), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Spent: $currency${spent.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: BudgetRingPainter(
                progress: progress,
                trackColor: trackColor,
                progressColor: progressColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Remaining', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '$currency${remaining > 0 ? remaining.toStringAsFixed(0) : "0"}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: progressColor),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
