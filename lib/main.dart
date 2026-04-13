import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'subscriptions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BudgetIQApp());
}

class BudgetIQApp extends StatelessWidget {
  const BudgetIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudgetIQ',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
          primary: Colors.deepPurpleAccent,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeWrapper();
        }
        return const LoginScreen();
      },
    );
  }
}

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(monthId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const BudgetSetupScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_lock_outlined, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 24),
            const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Send Reset Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetSetupScreen extends StatelessWidget {
  const BudgetSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 24),
            const Text('Set Monthly Budget', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Enter your budget for this month to get started.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text.trim());
                  if (amount != null && amount > 0) {
                    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('budgets')
                        .doc(monthId)
                        .set({
                      'amount': amount,
                      'month': now.month,
                      'year': now.year,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 24),
            const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email', filled: true, fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password', filled: true, fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                    );
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController, obscureText: true,
              decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController, obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password', filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(onPressed: () async {
                if (_passwordController.text != _confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                try {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Food', 'Transport', 'Shopping', 'Rent', 'Bill', 'Other'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser!;
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('subscriptions').snapshots(),
      builder: (context, subSnapshot) {
        double totalSubs = 0;
        if (subSnapshot.hasData) {
          for (var doc in subSnapshot.data!.docs) {
            totalSubs += double.tryParse((doc.data() as Map<String, dynamic>)['amount'].toString()) ?? 0;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('expenses').orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            double totalSpent = 0.0;
            final allDocs = snapshot.data?.docs ?? [];
            final List<QueryDocumentSnapshot> filteredDocs = [];

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
              final timestamp = data['date'] as Timestamp?;
              final category = data['category']?.toString() ?? 'Other';

              if (timestamp != null) {
                final date = timestamp.toDate();
                if (date.month == now.month && date.year == now.year) {
                  totalSpent += amount;
                  if (selectedCategory == 'All' || category.toLowerCase() == selectedCategory.toLowerCase()) {
                    filteredDocs.add(doc);
                  }
                }
              }
            }

            final double combinedTotal = totalSpent + totalSubs;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('budgets').doc(monthId).snapshots(),
              builder: (context, budgetSnapshot) {
                double monthlyBudget = 0.0;
                if (budgetSnapshot.hasData && budgetSnapshot.data!.exists) {
                  final budgetData = budgetSnapshot.data!.data() as Map<String, dynamic>?;
                  monthlyBudget = double.tryParse(budgetData?['amount']?.toString() ?? '0') ?? 0.0;
                }

                final double remaining = monthlyBudget - combinedTotal;
                final double percent = monthlyBudget > 0 ? (combinedTotal / monthlyBudget) : 0.0;

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('BudgetIQ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    actions: [
                      IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()))),
                      IconButton(icon: const Icon(Icons.receipt_long_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionsScreen()))),
                      IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                BudgetCard(budget: monthlyBudget, spent: combinedTotal),
                                
                                if (percent >= 0.8) ...[
                                  const SizedBox(height: 16),
                                  _buildSpendingAlert(percent),
                                ],

                                if (totalSubs > 0) ...[
                                  const SizedBox(height: 16),
                                  _buildSubsInfo(totalSubs),
                                ],

                                const SizedBox(height: 32),
                                const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: categories.map((cat) => Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: FilterChip(
                                        label: Text(cat),
                                        selected: selectedCategory == cat,
                                        onSelected: (selected) {
                                          setState(() {
                                            selectedCategory = cat;
                                          });
                                        },
                                        selectedColor: Colors.deepPurpleAccent.withAlpha(100),
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(color: selectedCategory == cat ? Colors.white : Colors.white70),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    )).toList(),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  selectedCategory == 'All' ? 'Recent Activity' : '$selectedCategory Activity',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                
                                filteredDocs.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 40.0),
                                          child: Text(
                                            selectedCategory == 'All' ? 'No expenses recorded yet' : 'No expenses in $selectedCategory',
                                            style: const TextStyle(color: Colors.white30),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredDocs.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final doc = filteredDocs[index];
                                          final data = doc.data() as Map<String, dynamic>;
                                          return Dismissible(
                                            key: Key(doc.id),
                                            direction: DismissDirection.endToStart,
                                            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.redAccent.withAlpha(25), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28)),
                                            confirmDismiss: (direction) => _confirmDelete(context, doc.id),
                                            child: ExpenseCard(docId: doc.id, category: data['category']?.toString() ?? 'Other', amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0, date: data['date'] as Timestamp?),
                                          );
                                        },
                                      ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton: Container(
                    height: 64, width: 160,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.deepPurpleAccent, Colors.deepPurple.shade700]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withAlpha(77), blurRadius: 12, offset: const Offset(0, 6))]),
                    child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(32), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen())), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white), SizedBox(width: 8), Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]))),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSubsInfo(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text('Fixed subscriptions: ₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSpendingAlert(double percent) {
    bool isExceeded = percent >= 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExceeded ? Colors.redAccent.withAlpha(30) : Colors.orangeAccent.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExceeded ? Colors.redAccent.withAlpha(100) : Colors.orangeAccent.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(isExceeded ? Icons.warning_rounded : Icons.info_outline, color: isExceeded ? Colors.redAccent : Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExceeded 
                ? 'Alert: You have exceeded your budget!' 
                : 'Warning: You have used ${(percent * 100).toStringAsFixed(0)}% of your budget.',
              style: TextStyle(
                color: isExceeded ? Colors.redAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String docId) {
    final user = FirebaseAuth.instance.currentUser!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Expense?'),
        content: const Text('This action will permanently remove this transaction.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('expenses').doc(docId).delete();
            if (context.mounted) Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted'), behavior: SnackBarBehavior.floating));
          }, child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final double budget;
  final double spent;
  const BudgetCard({super.key, required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final percent = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.deepPurpleAccent, Colors.deepPurple.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Budget', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text('₹${budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))]),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.wallet, color: Colors.white, size: 28)),
        ]),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildInfo('Spent', '₹${spent.toStringAsFixed(0)}', Colors.white), _buildInfo('Remaining', '₹${remaining.toStringAsFixed(0)}', remaining >= 0 ? Colors.greenAccent : Colors.redAccent)]),
        const SizedBox(height: 24),
        Stack(children: [Container(height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))), AnimatedContainer(duration: const Duration(milliseconds: 500), height: 10, width: (MediaQuery.of(context).size.width - 96) * percent, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.white70, Colors.white]), borderRadius: BorderRadius.circular(10)))]),
        const SizedBox(height: 12),
        Text('${(percent * 100).toStringAsFixed(1)}% of budget used', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }

  Widget _buildInfo(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]);
  }
}

class ExpenseCard extends StatelessWidget {
  final String docId;
  final String category;
  final double amount;
  final Timestamp? date;
  const ExpenseCard({super.key, required this.docId, required this.category, required this.amount, this.date});

  @override
  Widget build(BuildContext context) {
    final dateObj = date?.toDate() ?? DateTime.now();
    final dateStr = "${dateObj.day} ${_getMonthName(dateObj.month)} ${dateObj.year}";
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddExpenseScreen(docId: docId, existingAmount: amount, existingCategory: category))),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(height: 56, width: 56, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(_getEmoji(category), style: const TextStyle(fontSize: 24)))),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 13))),
        trailing: Text('-₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  String _getEmoji(String category) {
    category = category.toLowerCase();
    if (category.contains('food')) return '🍔';
    if (category.contains('transport') || category.contains('cab')) return '🚗';
    if (category.contains('shopping')) return '🛍️';
    if (category.contains('rent')) return '🏠';
    if (category.contains('bill') || category.contains('electricity')) return '⚡';
    return '💸';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class AddExpenseScreen extends StatelessWidget {
  final String? docId;
  final double? existingAmount;
  final String? existingCategory;
  const AddExpenseScreen({super.key, this.docId, this.existingAmount, this.existingCategory});

  @override
  Widget build(BuildContext context) {
    final amountController = TextEditingController(text: existingAmount?.toStringAsFixed(0) ?? '');
    final categoryController = TextEditingController(text: existingCategory ?? '');
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: Text(docId == null ? 'New Expense' : 'Modify Record')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          const SizedBox(height: 20),
          _buildField(controller: amountController, label: 'Amount', icon: Icons.currency_rupee, isNumeric: true),
          const SizedBox(height: 24),
          _buildField(controller: categoryController, label: 'Category', icon: Icons.category_outlined),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 64,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                final category = categoryController.text.trim();
                if (amount != null && category.isNotEmpty) {
                  final data = {'amount': amount, 'category': category, 'date': Timestamp.now()};
                  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('expenses');
                  if (docId == null) await ref.add(data);
                  else await ref.doc(docId).update(data);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8, shadowColor: Colors.deepPurpleAccent.withAlpha(102)),
              child: Text(docId == null ? 'Save Record' : 'Apply Changes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool isNumeric = false}) {
    return TextField(
      controller: controller, keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.deepPurpleAccent), filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2))),
    );
  }
}
