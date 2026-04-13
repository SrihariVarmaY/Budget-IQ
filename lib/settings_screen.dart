import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('budgets')
            .doc(monthId)
            .snapshots(),
        builder: (context, snapshot) {
          double currentBudget = 0.0;
          if (snapshot.hasData && snapshot.data!.exists) {
            currentBudget = double.tryParse(snapshot.data!['amount'].toString()) ?? 0.0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Account'),
                _buildSettingTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: user.email ?? 'Not available',
                ),
                _buildSettingTile(
                  icon: Icons.password_outlined,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                _buildSettingTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pop(context)),
                ),
                _buildSettingTile(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  color: Colors.redAccent,
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Budgeting'),
                _buildSettingTile(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Modify Monthly Budget',
                  subtitle: 'Current: ₹${currentBudget.toStringAsFixed(0)}',
                  onTap: () => _showEditBudgetDialog(context, user.uid, monthId, currentBudget),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Data Management'),
                _buildSettingTile(
                  icon: Icons.clear_all,
                  title: 'Clear All Expenses',
                  onTap: () => _confirmClearData(context),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('About'),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'BudgetIQ',
                  subtitle: 'Version 1.0.0',
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Made with ❤️ by DevZenith', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? Colors.white70),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20, color: Colors.white24) : null,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(labelText: 'Current Password', filled: true, fillColor: Colors.black26),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(labelText: 'New Password', filled: true, fillColor: Colors.black26),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;
              final currentPass = currentPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (currentPass.isEmpty || newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid input')));
                return;
              }

              try {
                // 1. Re-authenticate
                AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPass);
                await user.reauthenticateWithCredential(credential);
                
                // 2. Update Password
                await user.updatePassword(newPass);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!'), behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), behavior: SnackBarBehavior.floating));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, String uid, String monthId, double currentAmount) {
    final controller = TextEditingController(text: currentAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Update Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Budget (₹)',
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(controller.text.trim());
              if (newBudget != null && newBudget > 0) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('budgets')
                    .doc(monthId)
                    .update({'amount': newBudget});
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear all data?'),
        content: const Text('This will delete all your recorded expenses for all time. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('expenses');
              final snapshots = await ref.get();
              for (var doc in snapshots.docs) {
                await doc.reference.delete();
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared'), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account?'),
        content: const Text('This will permanently delete your account and all associated data from our servers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser!;
                await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                await user.delete();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Re-authentication required. Please logout and login again.'), behavior: SnackBarBehavior.floating));
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
