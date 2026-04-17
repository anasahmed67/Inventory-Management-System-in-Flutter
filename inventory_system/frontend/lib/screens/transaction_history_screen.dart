/// Transaction History Screen
/// 
/// Displays an immutable ledger of every stock change (Add, Deduct).
/// Transactions are grouped by date (Today, Yesterday, etc.) for easier reading.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  /// Pulls the complete list of transactions from the backend database.
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.getTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction History',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_transactions.length} records found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                _buildHeaderIconButton(
                  icon: Icons.file_download_outlined,
                  tooltip: 'Export CSV',
                  onTap: () {
                    if (_transactions.isNotEmpty) {
                      ExportService.exportTransactionsToCSV(_transactions);
                    }
                  },
                ),
                const SizedBox(width: AppTheme.spacingMd),
                ElevatedButton.icon(
                  onPressed: _fetchTransactions,
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.black),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Main Content ──
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.danger),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to load transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: TextStyle(color: AppTheme.secondaryTextColor(context)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.hintColor(context),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No transactions found',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.hintColor(context)),
            ),
          ],
        ),
      );
    }

    // ── Item 11: Group transactions by date ──
    final grouped = _groupByDate(_transactions);

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final group = grouped[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : AppTheme.spacingMd,
                  bottom: AppTheme.spacingSm,
                ),
                child: _buildDateHeader(group.label),
              ),
              // Transaction cards
              ...group.transactions.map((tx) => _buildTransactionCard(tx)),
            ],
          );
        },
      ),
    );
  }

  // ── Item 11: Date grouping logic ──
  /// Parses the raw transaction list and groups them conceptually into 'Today', 'Yesterday',
  /// or specific calendar dates to organize the list view cleanly.
  List<_DateGroup> _groupByDate(List<dynamic> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> groups = {};
    final Map<String, DateTime> groupDates = {};

    for (final tx in transactions) {
      final dateStr = tx['transaction_date'] ?? '';
      DateTime? date;
      if (dateStr.isNotEmpty) {
        date = DateTime.tryParse(dateStr)?.toLocal();
      }

      String label;
      DateTime sortDate;
      if (date != null) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly == today) {
          label = 'Today';
        } else if (dateOnly == yesterday) {
          label = 'Yesterday';
        } else {
          label = DateFormat('MMM dd, yyyy').format(date);
        }
        sortDate = dateOnly;
      } else {
        label = 'Unknown Date';
        sortDate = DateTime(1970);
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(tx);
      groupDates.putIfAbsent(label, () => sortDate);
    }

    // Sort groups by date (most recent first)
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) {
        final dateA = groupDates[a.key] ?? DateTime(1970);
        final dateB = groupDates[b.key] ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

    return sortedEntries
        .map((e) => _DateGroup(label: e.key, transactions: e.value))
        .toList();
  }

  Widget _buildDateHeader(String label) {
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final isToday = label == 'Today';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary
            : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: isToday ? Colors.black : AppTheme.textColor(context),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type = tx['type'].toString().toUpperCase();
    final isOut = type == 'OUT';
    final iconColor = isOut ? AppTheme.danger : AppTheme.success;
    final iconData = isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);

    final dateStr = tx['transaction_date'] ?? '';
    DateTime? date;
    if (dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr);
    }
    final formattedDate = date != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(date.toLocal())
        : 'Unknown Date';

    final productName = tx['product_name'] ?? 'Unknown Product';
    final quantity = tx['quantity']?.toString() ?? '0';
    final reason = tx['reason']?.toString() ?? '';
    final user = tx['user_name'] ?? 'Unknown User';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
        boxShadow: AppTheme.adaptiveSoftShadow(context),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: borderCol, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, color: Colors.black, size: 20),
                Text(
                  isOut ? 'OUT' : 'IN',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOut
                            ? (isDark ? const Color(0xFF3D1F1F) : AppTheme.dangerLight)
                            : (isDark ? const Color(0xFF1A3D2E) : AppTheme.successLight),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(color: borderCol, width: 1.5),
                      ),
                      child: Text(
                        '${isOut ? '-' : '+'}$quantity qty',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isOut ? AppTheme.danger : AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'By: $user',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.infoLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: borderCol, width: 1.5),
                    ),
                    child: Text(
                      'REASON: $reason',
                      style: TextStyle(
                        fontSize: 11,
                        color: textCol,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.info,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor(context), width: 2),
              boxShadow: AppTheme.adaptiveSoftShadow(context),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
        ),
      ),
    );
  }
}

// ── Data class for grouped transactions ──
class _DateGroup {
  final String label;
  final List<Map<String, dynamic>> transactions;

  _DateGroup({required this.label, required this.transactions});
}
