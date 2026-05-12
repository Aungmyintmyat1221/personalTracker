import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transactionModel.dart';

class MonthlyReportService {
  static final DateFormat _monthFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _fileMonthFormatter = DateFormat('yyyy_MM');
  static final DateFormat _dateFormatter = DateFormat('MMM d, yyyy');
  static final NumberFormat _moneyFormatter = NumberFormat('#,##0.##');

  static Future<void> shareMonthlyMoneyReport({
    required DateTime month,
    required List<TransactionModel> transactions,
  }) async {
    final bytes = await buildMonthlyMoneyReport(
      month: month,
      transactions: transactions,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'money_report_${_fileMonthFormatter.format(month)}.pdf',
    );
  }

  static Future<Uint8List> buildMonthlyMoneyReport({
    required DateTime month,
    required List<TransactionModel> transactions,
  }) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final monthlyTransactions =
        transactions
            .where((tx) => !tx.date.isBefore(start) && tx.date.isBefore(end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final income = _sumByType(monthlyTransactions, 'income');
    final expense = _sumByType(monthlyTransactions, 'expense');
    final balance = income - expense;
    final generatedAt = DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Pyidaungsu-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Pyidaungsu-Bold.ttf'),
    );

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        ),
        build: (context) => [
          _header(month, generatedAt),
          pw.SizedBox(height: 20),
          _summaryRow(income: income, expense: expense, balance: balance),
          pw.SizedBox(height: 24),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (monthlyTransactions.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text('No transactions recorded for this month.'),
            )
          else
            _transactionsTable(monthlyTransactions),
        ],
      ),
    );

    return document.save();
  }

  static double _sumByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where((tx) => tx.type == type)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
  }

  static pw.Widget _header(DateTime month, String generatedAt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Money Monthly Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _monthFormatter.format(month),
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          'Generated $generatedAt',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow({
    required double income,
    required double expense,
    required double balance,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(child: _summaryBox('Income', income, PdfColors.teal700)),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _summaryBox('Expense', expense, PdfColors.red600)),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _summaryBox('Balance', balance, PdfColors.blue700)),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _moneyFormatter.format(amount),
            style: pw.TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _transactionsTable(List<TransactionModel> transactions) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      headers: const ['Date', 'Type', 'Note', 'Amount'],
      data: transactions.map((tx) {
        final isIncome = tx.type == 'income';
        return [
          _dateFormatter.format(tx.date),
          isIncome ? 'Income' : 'Expense',
          tx.note.isEmpty ? '-' : tx.note,
          '${isIncome ? '+' : '-'}${_moneyFormatter.format(tx.amount)}',
        ];
      }).toList(),
    );
  }
}
