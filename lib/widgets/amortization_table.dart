import 'package:emi_calculator/models/emi_schedule_row.dart';
import 'package:emi_calculator/utils/export_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import '../providers/emi_provider.dart';

class AmortizationTable extends ConsumerStatefulWidget {
  const AmortizationTable({super.key});

  @override
  ConsumerState<AmortizationTable> createState() => _AmortizationTableState();
}

class _AmortizationTableState extends ConsumerState<AmortizationTable> {
  bool isYearly = false;

  @override
  Widget build(BuildContext context) {
    final emiNotifier = ref.watch(emiProvider);
    final limit = ref.watch(emiPaginationProvider);

    // Choose schedule based on view mode
    final fullSchedule = isYearly
        ? emiNotifier.yearlySchedule
        : emiNotifier.schedule;

    // If yearly, we usually want to show all years, or reuse pagination logic if years are many?
    // User probably wants to see all years if it's yearly view (usually max 5-7 years for loans).
    // If monthly, we respect pagination.
    final displaySchedule = isYearly
        ? fullSchedule
        : fullSchedule.take(limit).toList();

    // Precompute totals for footer
    double totalEmi = 0;
    double totalCpf = 0;
    double totalPayment = 0;
    double totalRevenue = 0;
    double totalProfit = 0;
    double totalLoss = 0;
    for (final row in displaySchedule) {
      totalEmi += row.emi;
      totalCpf += row.cpf;
      totalPayment += row.emi + row.cpf;
      totalRevenue += row.revenue;
      totalProfit += row.profit;
      totalLoss += row.loss;
    }
    final double totalNetCash = totalProfit - totalLoss;

    // Create data source
    // Pass isYearly flag to help format "Month" column as "Year X"
    final dataSource = AmortizationDataSource(
      displaySchedule,
      emiNotifier.currentMonth,
      isYearly: isYearly,
    );

    return Column(
      children: [
        // Tab Bar / Toggle
        Container(
          width: 300,
          margin: const EdgeInsets.only(bottom: 16),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: isYearly
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isYearly = true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          "Yearly",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isYearly
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isYearly = false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          "Monthly",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: !isYearly
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _exportToExcel(
                isYearly ? emiNotifier.yearlySchedule : emiNotifier.schedule,
              ),
              icon: const Icon(Icons.download),
              label: Text('Export ${isYearly ? "Yearly" : "Monthly"} to Excel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        Container(
          // height: 500,
          width: double.infinity, // Ensure container takes full width
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              headerColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              headerHoverColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
            ),
            child: SfDataGrid(
              source: dataSource,
              allowSorting: false,
              allowFiltering: false,
              selectionMode: SelectionMode.single,
              rowHeight: 42,
              headerRowHeight: 44,
              columnWidthMode: ColumnWidthMode.fill, // Fill available width
              gridLinesVisibility: GridLinesVisibility.both,
              headerGridLinesVisibility: GridLinesVisibility.both,
              shrinkWrapRows: true,
              verticalScrollPhysics: const NeverScrollableScrollPhysics(),
              columns: [
                GridColumn(
                  columnName: 'month',
                  label: _buildHeader(isYearly ? "Year" : "Month"),
                  width: 80,
                ),
                GridColumn(
                  columnName: 'emi',
                  label: _buildHeader(
                    isYearly ? "EMI (Yearly)" : "EMI (Monthly)",
                  ),
                ),
                GridColumn(
                  columnName: 'cpf',
                  label: _buildHeader(
                    isYearly ? "CPF (Yearly)" : "CPF (Monthly)",
                  ),
                ),
                GridColumn(
                  columnName: 'revenue',
                  label: _buildHeader("Revenue"),
                ),
                GridColumn(
                  columnName: 'payment',
                  label: _buildHeader(isYearly ? "Repayment" : "Repayment"),
                ),
                GridColumn(
                  columnName: 'loanCut',
                  label: _buildHeader("Debit From Balance"),
                ),
                GridColumn(
                  columnName: 'loanBalance',
                  label: _buildHeader("Balance"),
                ),
                // GridColumn(
                //   columnName: 'principal',
                //   label: _buildHeader("Principal"),
                // ),
                // GridColumn(
                //   columnName: 'interest',
                //   label: _buildHeader("Interest"),
                // ),
                // GridColumn(
                //   columnName: 'balance',
                //   label: _buildHeader("Balance"),
                // ),
                GridColumn(columnName: 'profit', label: _buildHeader("Profit")),
                GridColumn(
                  columnName: 'loss',
                  label: _buildHeader("From Pocket"),
                ),
                GridColumn(
                  columnName: 'netCash',
                  label: _buildHeader("Net Cash"),
                ),
                // stackedHeaderRows: [
                //   StackedHeaderRow(
                //     cells: [
                //       StackedHeaderCell(
                //         columnNames: ['principal', 'interest'],
                //         child: Center(
                //           child: Text(
                //             "Payment Breakdown",
                //             style: GoogleFonts.inter(
                //               fontWeight: FontWeight.bold,
                //               color: Theme.of(context).colorScheme.onSurface,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ],
              ],
            ),
          ),
        ),

        // Footer totals for quick overview
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${isYearly ? "Yearly Totals" : "Visible Totals"}  |  '
              'Payment: ${emiNotifier.formatCurrency(totalPayment)}   '
              'EMI: ${emiNotifier.formatCurrency(totalEmi)}   '
              'CPF: ${emiNotifier.formatCurrency(totalCpf)}   '
              'Revenue: ${emiNotifier.formatCurrency(totalRevenue)}   '
              'Profit: ${emiNotifier.formatCurrency(totalProfit)}   '
              'From Pocket: ${emiNotifier.formatCurrency(totalLoss)}   '
              'Net Cash: ${emiNotifier.formatCurrency(totalNetCash)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Pagination only makes sense for Monthly view to avoid huge list
        if (!isYearly) _buildPaginationButtons(ref),
      ],
    );
  }

  Future<void> _exportToExcel(List<EmiScheduleRow> schedule) async {
    // Convert schedule to list of maps for export
    final List<Map<String, dynamic>> data = schedule.map((row) {
      return {
        isYearly ? 'Year' : 'Month': row.month,
        isYearly ? 'Total Payment' : 'Monthly Payment': row.emi + row.cpf,
        'EMI': row.emi,
        isYearly ? 'Total CPF' : 'Monthly CPF': row.cpf,
        'Revenue': row.revenue,
        'Principal': row.principal,
        'Interest': row.interest,
        'Balance': row.balance,
      };
    }).toList();

    await ExportUtils.exportToPDF(
      data: data,
      fileName:
          'EMI_Schedule_${isYearly ? "Yearly" : "Monthly"}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Widget _buildHeader(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaginationButtons(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPaginationButton(ref, 12, "12 Months"),
        const SizedBox(width: 10),
        _buildPaginationButton(ref, 24, "24 Months"),
        const SizedBox(width: 10),
        _buildPaginationButton(ref, 1000, "Show All"),
      ],
    );
  }

  Widget _buildPaginationButton(WidgetRef ref, int limit, String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ref.watch(emiPaginationProvider) == limit
            ? Theme.of(ref.context).colorScheme.primary
            : null,
      ),
      onPressed: () => ref.read(emiPaginationProvider.notifier).setLimit(limit),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: ref.watch(emiPaginationProvider) == limit
              ? Colors.white
              : null,
        ),
      ),
    );
  }
}

class AmortizationDataSource extends DataGridSource {
  final List<EmiScheduleRow> schedule;
  final int currentMonth;
  final bool isYearly;
  List<DataGridRow> _rows = [];

  final NumberFormat indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  AmortizationDataSource(
    this.schedule,
    this.currentMonth, {
    this.isYearly = false,
  }) {
    _rows = buildRows();
  }

  List<DataGridRow> buildRows() {
    return schedule.map((row) {
      return DataGridRow(
        cells: [
          DataGridCell<int>(columnName: 'month', value: row.month),
          DataGridCell<double>(columnName: 'emi', value: row.emi),
          DataGridCell<double>(columnName: 'cpf', value: row.cpf),
          DataGridCell<double>(columnName: 'revenue', value: row.revenue),
          DataGridCell<double>(columnName: 'payment', value: row.emi + row.cpf),
          DataGridCell<double>(
            columnName: 'loanCut',
            value: row.emiFromLoanPool + row.cpfFromLoanPool,
          ),
          DataGridCell<double>(
            columnName: 'loanBalance',
            value: row.loanPoolBalance,
          ),
          // DataGridCell<double>(columnName: 'principal', value: row.principal),
          // DataGridCell<double>(columnName: 'interest', value: row.interest),
          // DataGridCell<double>(columnName: 'balance', value: row.balance),
          DataGridCell<double>(columnName: 'profit', value: row.profit),
          DataGridCell<double>(columnName: 'loss', value: row.loss),
          DataGridCell<double>(
            columnName: 'netCash',
            value: row.profit - row.loss,
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final month = row.getCells()[0].value as int;
    // final isCurrent = month == currentMonth;

    // Determine if this row has positive profit or loss
    final profitCell = row.getCells().firstWhere(
      (c) => c.columnName == 'profit',
      orElse: () => row.getCells().first,
    );
    final double profitValue = profitCell.columnName == 'profit'
        ? (profitCell.value as double)
        : 0.0;
    final bool hasProfit = profitValue > 0;

    final lossCell = row.getCells().firstWhere(
      (c) => c.columnName == 'loss',
      orElse: () => row.getCells().first,
    );
    final double lossValue = lossCell.columnName == 'loss'
        ? (lossCell.value as double)
        : 0.0;
    final bool hasLoss = lossValue > 0;

    Color? rowColor;
    if (hasLoss) {
      rowColor = Colors.grey.shade300;
    } else if (hasProfit) {
      rowColor = Colors.green.shade50;
    }

    return DataGridRowAdapter(
      color: /*  isCurrent ? Colors.blue : */ rowColor,
      cells: row.getCells().map((cell) {
        final col = cell.columnName;
        final value = cell.value;
        String displayValue;
        if (col == "month") {
          displayValue = isYearly ? "Year $value" : value.toString();
        } else {
          displayValue = indianFormat.format(value as num);
        }
        Color? textColor;
        if (col == "principal") {
          textColor = Colors.green.shade700;
        } else if (col == "interest") {
          textColor = Colors.red.shade700;
        } else if (col == "loss" && lossValue > 0) {
          textColor = Colors.red.shade700;
        } else if (col == "profit" && profitValue > 0) {
          textColor = Colors.green.shade700;
        } else if (col == "netCash") {
          final netCashValue = profitValue - lossValue;
          if (netCashValue > 0) {
            textColor = Colors.green.shade700;
          } else if (netCashValue < 0) {
            textColor = Colors.red.shade700;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: Alignment.center,
          color: rowColor,
          child: Text(
            displayValue,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textColor,
              fontWeight: /*  isCurrent ? FontWeight.bold : */
                  FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

final emiPaginationProvider = StateNotifierProvider<EmiPaginationNotifier, int>(
  (ref) {
    return EmiPaginationNotifier();
  },
);

class EmiPaginationNotifier extends StateNotifier<int> {
  EmiPaginationNotifier() : super(12);

  void setLimit(int limit) {
    state = limit;
  }
}
