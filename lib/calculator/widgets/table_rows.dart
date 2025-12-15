// class AmortizationDataSource extends DataGridSource {
//   final List<EmiScheduleRow> schedule;
//   final int currentMonth;
//   final bool isYearly;
//   List<DataGridRow> _rows = [];

//   final NumberFormat indianFormat = NumberFormat.currency(
//     locale: 'en_IN',
//     symbol: '',
//     decimalDigits: 2,
//   );

//   AmortizationDataSource(
//     this.schedule,
//     this.currentMonth, {
//     this.isYearly = false,
//   }) {
//     _rows = buildRows();
//   }

//   List<DataGridRow> buildRows() {
//     return schedule.map((row) {
//       return DataGridRow(
//         cells: [
//           DataGridCell<int>(columnName: 'month', value: row.month),
//           DataGridCell<double>(columnName: 'emi', value: row.emi),
//           DataGridCell<double>(columnName: 'cpf', value: row.cpf),
//           DataGridCell<double>(columnName: 'revenue', value: row.revenue),
//           DataGridCell<double>(columnName: 'payment', value: row.emi + row.cpf),
//           DataGridCell<double>(
//             columnName: 'loanCut',
//             value: row.emiFromLoanPool + row.cpfFromLoanPool,
//           ),
//           DataGridCell<double>(
//             columnName: 'loanBalance',
//             value: row.loanPoolBalance,
//           ),
//           DataGridCell<double>(columnName: 'profit', value: row.profit),
//           DataGridCell<double>(columnName: 'loss', value: row.loss),
//           DataGridCell<double>(
//             columnName: 'netCash',
//             value: row.profit - row.loss,
//           ),
//         ],
//       );
//     }).toList();
//   }

//   @override
//   List<DataGridRow> get rows => _rows;

//   @override
//   DataGridRowAdapter buildRow(DataGridRow row) {
//     final month = row.getCells()[0].value as int;

//     // Determine if this row has positive profit or loss
//     final profitCell = row.getCells().firstWhere(
//       (c) => c.columnName == 'profit',
//       orElse: () => row.getCells().first,
//     );
//     final double profitValue = profitCell.columnName == 'profit'
//         ? (profitCell.value as double)
//         : 0.0;
//     final bool hasProfit = profitValue > 0;

//     final lossCell = row.getCells().firstWhere(
//       (c) => c.columnName == 'loss',
//       orElse: () => row.getCells().first,
//     );
//     final double lossValue = lossCell.columnName == 'loss'
//         ? (lossCell.value as double)
//         : 0.0;
//     final bool hasLoss = lossValue > 0;

//     Color? rowColor;
//     if (hasLoss) {
//       rowColor = Colors.grey.shade300;
//     } else if (hasProfit) {
//       rowColor = Colors.green.shade50;
//     }

//     return DataGridRowAdapter(
//       color: rowColor,
//       cells: row.getCells().map((cell) {
//         final col = cell.columnName;
//         final value = cell.value;
//         String displayValue;
//         if (col == "month") {
//           displayValue = isYearly ? "Year $value" : value.toString();
//         } else {
//           displayValue = indianFormat.format(value as num);
//         }
//         Color? textColor;
//         if (col == "loss" && lossValue > 0) {
//           textColor = Colors.red.shade700;
//         } else if (col == "profit" && profitValue > 0) {
//           textColor = Colors.green.shade700;
//         } else if (col == "netCash") {
//           final netCashValue = profitValue - lossValue;
//           if (netCashValue > 0) {
//             textColor = Colors.green.shade700;
//           } else if (netCashValue < 0) {
//             textColor = Colors.red.shade700;
//           }
//         }

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           alignment: Alignment.center,
//           color: rowColor,
//           child: Text(
//             displayValue,
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: textColor,
//               fontWeight: FontWeight.normal,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }
