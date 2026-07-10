import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subscriptions = state.subscriptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Summary Header
          _buildSubscriptionSummary(state.totalSubscriptions),
          
          Expanded(
            child: subscriptions.isEmpty
                ? const Center(child: Text('No subscriptions added', style: TextStyle(color: Colors.white30)))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: subscriptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return _buildSubscriptionCard(context, sub);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        label: const Text('Add Subscription'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }

  Widget _buildSubscriptionSummary(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurpleAccent.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Text('Monthly Fixed Costs', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic sub) {
    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent.withAlpha(30), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
      ),
      confirmDismiss: (direction) => _confirmDelete(context, sub.id),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(backgroundColor: Colors.white10, child: Text(_getEmoji(sub.name), style: const TextStyle(fontSize: 20))),
          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${sub.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white24), onPressed: () => _showAddEditDialog(context, sub: sub)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent.withAlpha(150)), onPressed: () => _confirmDelete(context, sub.id)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {dynamic sub}) {
    final nameController = TextEditingController(text: sub?.name);
    final amountController = TextEditingController(text: sub?.amount?.toStringAsFixed(0));
    int selectedDate = 1; // Simplified for brevity as per cleanup

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub == null ? 'New Subscription' : 'Edit Subscription', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(nameController, 'Name (e.g. Netflix)', Icons.subscriptions_outlined),
            const SizedBox(height: 16),
            _buildField(amountController, 'Monthly Cost (₹)', Icons.currency_rupee, isNumeric: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (nameController.text.isNotEmpty && amount != null) {
                    final state = context.read<AppState>();
                    if (sub == null) {
                      await state.addSubscription(nameController.text.trim(), amount, selectedDate);
                    } else {
                      await state.updateSubscription(sub.id, nameController.text.trim(), amount, selectedDate);
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(sub == null ? 'Add Subscription' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNumeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String id) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete?'),
        content: const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<AppState>().deleteSubscription(id);
              if (context.mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription deleted'), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String name) {
    name = name.toLowerCase();
    if (name.contains('netflix')) return '🎬';
    if (name.contains('spotify')) return '🎵';
    if (name.contains('youtube')) return '📺';
    if (name.contains('rent')) return '🏠';
    if (name.contains('gym')) return '💪';
    if (name.contains('internet') || name.contains('wifi')) return '🌐';
    return '💳';
  }
}
