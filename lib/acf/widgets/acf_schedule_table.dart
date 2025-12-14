import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import '../providers/acf_provider.dart';
import '../models/acf_schedule_row.dart';

class AcfScheduleTable extends ConsumerWidget {
  const AcfScheduleTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acfNotifier = ref.watch(acfProvider);
    final schedule = acfNotifier.schedule;

    // Create data source
    final dataSource = AcfScheduleDataSource(schedule: schedule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Schedule',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black, // Monochrome/Navy per theme
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
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
              rowHeight: 48,
              headerRowHeight: 50,
              columnWidthMode: ColumnWidthMode.fill,
              gridLinesVisibility: GridLinesVisibility.both,
              headerGridLinesVisibility: GridLinesVisibility.both,
              shrinkWrapRows:
                  true, // Important for use in SingleChildScrollView
              verticalScrollPhysics: const NeverScrollableScrollPhysics(),
              columns: [
                GridColumn(
                  columnName: 'month',
                  label: _buildHeader('Month'),
                  width: 80,
                ),
                GridColumn(
                  columnName: 'installment',
                  label: _buildHeader('Payment Amount'),
                ),
                GridColumn(
                  columnName: 'cumulative',
                  label: _buildHeader('Total Paid'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class AcfScheduleDataSource extends DataGridSource {
  final List<AcfScheduleRow> schedule;
  List<DataGridRow> _rows = [];

  final NumberFormat indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  AcfScheduleDataSource({required this.schedule}) {
    _rows = schedule.map((row) {
      return DataGridRow(
        cells: [
          DataGridCell<int>(columnName: 'month', value: row.month),
          DataGridCell<double>(
            columnName: 'installment',
            value: row.installment,
          ),
          DataGridCell<double>(
            columnName: 'cumulative',
            value: row.cumulativePayment,
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final cells = row.getCells();
    return DataGridRowAdapter(
      cells: cells.map((cell) {
        String displayValue;
        if (cell.columnName == 'month') {
          displayValue = cell.value.toString();
        } else {
          displayValue = indianFormat.format(cell.value);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Text(
            displayValue,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: cell.columnName == 'cumulative'
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}
