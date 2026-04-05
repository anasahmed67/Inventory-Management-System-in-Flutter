import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
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
      appBar: AppBar(title: const Text('Transaction Logs')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<dynamic>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            }

            final transactions = snapshot.data!;

            return ListView.separated(
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final type = tx['type'];
                final qty = tx['quantity'];
                final date = DateTime.parse(tx['transaction_date'].toString());
                final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(date.toLocal());

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == 'IN' ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      type == 'IN' ? Icons.add : Icons.remove,
                      color: type == 'IN' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(tx['product_name'] ?? 'Unknown Product'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: ${tx['user_name']} | Reason: ${tx['reason'] ?? 'N/A'}'),
                      Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Text(
                    '${type == 'IN' ? '+' : '-'}$qty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: type == 'IN' ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
