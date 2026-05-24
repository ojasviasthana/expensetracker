import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_providers.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotalsAsync = ref.watch(categoryWiseExpensesProvider);
    final categoryColors = ref.watch(categoryColorsProvider);
    final currency = ref.watch(currencyProvider).symbol;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Insights'),
      ),
      child: SafeArea(
        child: categoryTotalsAsync.when(
          data: (totals) {
            if (totals.isEmpty) {
              final emptyQuotes = [
                "Currently tracking: immaculate self-control ✨",
                "Too early for charts.\nGo spend responsibly. We believe in you.",
                "Your budget is undefeated 🏆\nLog some expenses when reality kicks in.",
                "Your expenses are hiding.\nProbably scared of accountability.",
                "No data yet, but the vibes are financially responsible.",
                "Zero expenses detected.\nEither you’re saving like a legend or surviving on free samples.",
                "Your wallet is suspiciously peaceful.",
              ];
              final randomQuote = emptyQuotes[DateTime.now().millisecond % emptyQuotes.length];

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    randomQuote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              );
            }

            final categories = totals.keys.toList();
            final maxAmount = totals.values.fold<double>(0, (max, val) => val > max ? val : max);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending by Category',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxAmount * 1.2,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${categories[groupIndex]}\n',
                                        const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: '$currency${rod.toY.toStringAsFixed(2)}',
                                            style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= categories.length) return const SizedBox();
                                        final category = categories[value.toInt()];
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            category.substring(0, min(category.length, 3)),
                                            style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey),
                                          ),
                                        );
                                      },
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                barGroups: categories.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cat = entry.value;
                                  final amount = totals[cat]!;
                                  return BarChartGroupData(
                                    x: idx,
                                    barRods: [
                                      BarChartRodData(
                                        toY: amount,
                                        color: categoryColors[cat] ?? CupertinoColors.activeBlue,
                                        width: 18,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: maxAmount * 1.2,
                                          color: CupertinoColors.systemGroupedBackground,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final amount = totals[category]!;
                      final color = categoryColors[category] ?? CupertinoColors.activeBlue;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 16),
                            Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const Spacer(),
                            Text(
                              '$currency${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
