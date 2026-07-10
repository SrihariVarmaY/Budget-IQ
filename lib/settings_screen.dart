import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser!;
    final currentBudget = state.currentBudget?.amount ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
              onTap: () {
                final nav = Navigator.of(context);
                FirebaseAuth.instance.signOut().then((_) {
                  if (nav.canPop()) nav.pop();
                });
              },
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
              onTap: () => _showEditBudgetDialog(context, currentBudget),
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
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final user = FirebaseAuth.instance.currentUser!;
              final currentPass = currentPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (currentPass.isEmpty || newPass.length < 6) {
                messenger.showSnackBar(const SnackBar(content: Text('Invalid input')));
                return;
              }

              try {
                AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPass);
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPass);
                
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Password updated!'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, double currentAmount) {
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
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final state = context.read<AppState>();
              final newBudget = double.tryParse(controller.text.trim());
              if (newBudget != null && newBudget > 0) {
                try {
                  await state.setBudget(newBudget);
                  nav.pop();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
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
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await context.read<AppState>().clearAllExpenses();
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text('All data cleared'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
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
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                final user = FirebaseAuth.instance.currentUser!;
                // Note: Actual deletion usually requires recent login
                await user.delete();
                nav.pop();
              } catch (e) {
                messenger.showSnackBar(const SnackBar(content: Text('Error: Re-authentication required. Please logout and login again.'), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
