import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<dynamic>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _transactionsFuture = ApiService.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                        'Transaction Logs',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track all stock movements',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _buildIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: _refresh,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Transaction List ──
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppTheme.danger),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Error loading transactions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.textHint),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No transactions yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    );
                  }

                  final transactions = snapshot.data!;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingSm),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(
                            indent: 72,
                            endIndent: AppTheme.spacingMd,
                          ),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return _buildTransactionTile(tx);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final type = tx['type'];
    final qty = tx['quantity'];
    final date =
        DateTime.parse(tx['transaction_date'].toString());
    final formattedDate =
        DateFormat('MMM dd, yyyy • HH:mm').format(date.toLocal());
    final isIn = type == 'IN';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // ── Type Badge ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIn
                  ? AppTheme.successLight
                  : AppTheme.dangerLight,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.success : AppTheme.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['product_name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${tx['user_name']}  •  ${tx['reason'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),

          // ── Quantity ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isIn
                  ? AppTheme.successLight
                  : AppTheme.dangerLight,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${isIn ? '+' : '-'}$qty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    isIn ? AppTheme.success : AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
        ),
      ),
    );
  }
}
