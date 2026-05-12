import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/TransactionController.dart';
import '../models/transactionModel.dart';
import '../service/monthly_report_service.dart';
import '../theme/app_theme.dart';

class MoneyView extends StatelessWidget {
  MoneyView({super.key});

  final TransactionController controller = Get.put(TransactionController());
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final RxString type = 'income'.obs;
  final Rx<DateTime> reportMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          IconButton(
            tooltip: 'Export monthly report',
            onPressed: () => _exportMonthlyReport(),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Obx(() {
          final balance = controller.getBalance();
          final income = controller.transactions
              .where((tx) => tx.type == 'income')
              .fold<double>(0, (sum, tx) => sum + tx.amount);
          final expense = controller.transactions
              .where((tx) => tx.type == 'expense')
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              _balanceCard(balance, income, expense),
              const SizedBox(height: 16),
              _moneyChart(),
              const SizedBox(height: 16),
              _monthlyReportCard(context),
              const SizedBox(height: 16),
              if (controller.transactions.isEmpty)
                _emptyState()
              else
                ...controller.transactions.reversed.map(_transactionTile),
            ],
          );
        }),
      ),
    );
  }

  Widget _balanceCard(double balance, double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: premiumCard(color: AppTheme.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Color(0xFFD1D5DB)),
          ),
          const SizedBox(height: 6),
          Text(
            balance.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _moneyPill('Income', income, AppTheme.teal)),
              const SizedBox(width: 10),
              Expanded(child: _moneyPill('Expense', expense, AppTheme.rose)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moneyPill(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(txn) {
    final isIncome = txn.type == 'income';
    final color = isIncome ? AppTheme.teal : AppTheme.rose;

    return Dismissible(
      key: Key(txn.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.rose,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteTransaction(txn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: premiumCard(),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.10),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            txn.note,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(isIncome ? 'Income' : 'Expense'),
          trailing: Text(
            '${isIncome ? '+' : '-'}${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _moneyChart() {
    final transactions = controller.transactions.toList();
    final income = transactions
        .where((tx) => tx.type == 'income')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final expense = transactions
        .where((tx) => tx.type == 'expense')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Flow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _MoneyChartPainter(income: income, expense: expense),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyReportCard(BuildContext context) {
    return Obx(() {
      final month = reportMonth.value;
      final transactions = _transactionsForMonth(month);
      final income = transactions
          .where((tx) => tx.type == 'income')
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final expense = transactions
          .where((tx) => tx.type == 'expense')
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: premiumCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Monthly Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Choose month',
                  onPressed: () => _pickReportMonth(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _reportMetric('Income', income, AppTheme.teal)),
                const SizedBox(width: 10),
                Expanded(
                  child: _reportMetric('Expense', expense, AppTheme.rose),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _reportMetric(
                    'Entries',
                    transactions.length.toDouble(),
                    AppTheme.primary,
                    isCount: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _exportMonthlyReport,
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Export PDF'),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _reportMetric(
    String label,
    double amount,
    Color color, {
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            isCount ? amount.toStringAsFixed(0) : amount.toStringAsFixed(0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 42),
          SizedBox(height: 10),
          Text(
            'No transactions yet',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4),
          Text(
            'Track income and expenses here.',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                return SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.south_west),
                    ),
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.north_east),
                    ),
                  ],
                  selected: {type.value},
                  onSelectionChanged: (value) => type.value = value.first,
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (title.isEmpty || amount <= 0) return;
                    controller.addTransaction(type.value, amount, title);
                    titleController.clear();
                    amountController.clear();
                    Get.back();
                  },
                  child: const Text('Add Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickReportMonth(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: reportMonth.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Choose report month',
    );
    if (selected == null) return;
    reportMonth.value = DateTime(selected.year, selected.month);
  }

  Future<void> _exportMonthlyReport() async {
    try {
      await MonthlyReportService.shareMonthlyMoneyReport(
        month: reportMonth.value,
        transactions: controller.transactions.toList(),
      );
    } catch (_) {
      Get.snackbar(
        'Export failed',
        'Could not create the monthly report PDF.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  List<TransactionModel> _transactionsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return controller.transactions
        .where((tx) => !tx.date.isBefore(start) && tx.date.isBefore(end))
        .toList();
  }
}

class _MoneyChartPainter extends CustomPainter {
  final double income;
  final double expense;

  _MoneyChartPainter({required this.income, required this.expense});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final maxValue = [income, expense, 1].reduce((a, b) => a > b ? a : b);
    final barWidth = size.width * 0.26;
    final baseY = size.height - 24;

    void drawBar(double x, double value, Color color, String label) {
      final height = (value / maxValue) * (size.height - 44);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - height, barWidth, height),
        const Radius.circular(10),
      );
      paint.color = color;
      canvas.drawRRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, baseY + 8),
      );
    }

    drawBar(size.width * 0.18, income, AppTheme.teal, 'Income');
    drawBar(size.width * 0.56, expense, AppTheme.rose, 'Expense');
  }

  @override
  bool shouldRepaint(covariant _MoneyChartPainter oldDelegate) {
    return oldDelegate.income != income || oldDelegate.expense != expense;
  }
}
