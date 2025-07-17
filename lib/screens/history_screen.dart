import 'package:flutter/material.dart';
import '../models/history_item_model.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../utils/category_icons.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Time')),
              const PopupMenuItem(value: 'week', child: Text('Last Week')),
              const PopupMenuItem(value: 'month', child: Text('Last Month')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<HistoryItemModel>>(
        stream: _getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Indexes are being built',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'History will be available soon.\nPlease try again in a few minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Trigger rebuild
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you mark as used will appear here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildHistoryItemTile(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItemTile(HistoryItemModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: item.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.imageUrl.isEmpty
              ? Icon(
                  CategoryIcons.getIconForCategory(item.category),
                  color: Colors.grey,
                )
              : null,
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy HH:mm').format(item.usedAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  item.status == 'clear'
                      ? Icons.cleaning_services
                      : Icons.check_circle,
                  size: 14,
                  color: item.status == 'clear' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  item.status == 'clear' ? 'Cleared' : 'Used',
                  style: TextStyle(
                    color: item.status == 'clear' ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteHistoryItem(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<HistoryItemModel>> _getHistoryStream() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'week':
        final lastWeek = now.subtract(const Duration(days: 7));
        return _historyService.getHistoryByDateRange(lastWeek, now);
      case 'month':
        final lastMonth = now.subtract(const Duration(days: 30));
        return _historyService.getHistoryByDateRange(lastMonth, now);
      default:
        return _historyService.getUserHistory();
    }
  }

  Future<void> _deleteHistoryItem(HistoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}" from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _historyService.deleteHistoryItem(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
