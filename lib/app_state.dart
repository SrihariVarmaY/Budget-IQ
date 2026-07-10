import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Budget? _currentBudget;
  List<Expense> _expenses = [];
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  // Track initialization of each stream to manage loading state properly
  bool _budgetLoaded = false;
  bool _expensesLoaded = false;
  bool _subsLoaded = false;

  // Streams
  StreamSubscription? _budgetSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _subsSub;

  Budget? get currentBudget => _currentBudget;
  List<Expense> get expenses => _expenses;
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  double get totalExpenses {
    final now = DateTime.now();
    final total = _expenses
        .where((e) => e.month == now.month && e.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
    debugPrint('Calculation: Total Month Expenses = ₹$total');
    return total;
  }

  double get totalSubscriptions {
    final total = _subscriptions.fold(0.0, (sum, s) => sum + s.amount);
    return total;
  }

  double get totalSpent => totalExpenses + totalSubscriptions;

  double get remainingBudget {
    if (_currentBudget == null) return -totalSpent;
    return _currentBudget!.amount - totalSpent;
  }

  double get spendingPercentage {
    if (_currentBudget == null || _currentBudget!.amount <= 0) return 0.0;
    return (totalSpent / _currentBudget!.amount).clamp(0.0, 1.0);
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    final now = DateTime.now();
    for (var expense in _expenses) {
      if (expense.month == now.month && expense.year == now.year) {
        totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  AppState() {
    debugPrint('AppState: Initializing...');
    
    // Check current user immediately
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      debugPrint('AppState: Found existing session for: ${currentUser.uid}');
      _initListeners(currentUser.uid);
    }

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('AppState: Auth state changed: User logged in: ${user.uid}');
        // Only re-init if UID changed or wasn't initialized
        if (_expensesSub == null) {
          _initListeners(user.uid);
        }
      } else {
        debugPrint('AppState: Auth state changed: User logged out');
        _disposeListeners();
      }
    });
  }

  void _checkLoadingStatus() {
    if (_budgetLoaded && _expensesLoaded && _subsLoaded) {
      _isLoading = false;
      debugPrint('AppState: All data streams loaded and synced');
      notifyListeners();
    }
  }

  void _initListeners(String uid) {
    _disposeListeners(); // Clear any existing subscriptions
    _isLoading = true;
    _budgetLoaded = false;
    _expensesLoaded = false;
    _subsLoaded = false;
    _error = null;
    notifyListeners();

    final now = DateTime.now();
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    debugPrint('AppState: Fetching budget for $monthId');

    // 1. Budget Listener
    _budgetSub = _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(monthId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _currentBudget = Budget.fromFirestore(doc);
        debugPrint('AppState: Budget loaded: ₹${_currentBudget?.amount}');
      } else {
        _currentBudget = null;
        debugPrint('AppState: No budget found for this month');
      }
      _budgetLoaded = true;
      _checkLoadingStatus();
    }, onError: (e) {
      debugPrint('AppState: Budget Error: $e');
      _handleError("Budget Error: $e");
    });

    // 2. Expenses Listener
    debugPrint('AppState: Starting real-time expense stream...');
    _expensesSub = _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint('AppState: Received expense snapshot, count: ${snapshot.docs.length}');
      _expenses = snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      _expensesLoaded = true;
      _checkLoadingStatus();
      notifyListeners(); // Ensure UI updates even if other streams aren't done
    }, onError: (e) {
      debugPrint('AppState: Expenses Error: $e');
      _handleError("Expenses Error: $e");
      // Fallback: Try without orderBy if there's an index error
      if (e.toString().contains('index')) {
        _retryExpensesWithoutOrder(uid);
      }
    });

    // 3. Subscriptions Listener
    _subsSub = _db
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .snapshots()
        .listen((snapshot) {
      debugPrint('AppState: Received subscriptions snapshot, count: ${snapshot.docs.length}');
      _subscriptions = snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList();
      _subsLoaded = true;
      _checkLoadingStatus();
      notifyListeners();
    }, onError: (e) {
      debugPrint('AppState: Subscriptions Error: $e');
      _handleError("Subscriptions Error: $e");
    });
  }

  void _retryExpensesWithoutOrder(String uid) {
    debugPrint('AppState: Retrying expenses without orderBy (waiting for index?)');
    _expensesSub?.cancel();
    _expensesSub = _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {
      _expenses = snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      // Sort manually in memory if index is missing
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _expensesLoaded = true;
      _checkLoadingStatus();
      notifyListeners();
    });
  }

  void _disposeListeners() {
    _budgetSub?.cancel();
    _expensesSub?.cancel();
    _subsSub?.cancel();
    _budgetSub = null;
    _expensesSub = null;
    _subsSub = null;
    _currentBudget = null;
    _expenses = [];
    _subscriptions = [];
    _isLoading = false;
    _budgetLoaded = false;
    _expensesLoaded = false;
    _subsLoaded = false;
  }

  void _handleError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  // Actions
  Future<void> setBudget(double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    debugPrint('AppState: Saving budget ₹$amount for $monthId');
    await _db.collection('users').doc(user.uid).collection('budgets').doc(monthId).set({
      'amount': amount,
      'month': now.month,
      'year': now.year,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addExpense(double amount, String category, {String? title}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    debugPrint('AppState: Adding expense ₹$amount in $category');

    await _db.collection('users').doc(user.uid).collection('expenses').add({
      'title': title ?? category,
      'amount': (amount as num).toDouble(), // Ensure double
      'category': category,
      'date': FieldValue.serverTimestamp(),
      'month': now.month,
      'year': now.year,
    });
  }

  Future<void> deleteExpense(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    debugPrint('AppState: Deleting expense $id');
    await _db.collection('users').doc(user.uid).collection('expenses').doc(id).delete();
  }

  Future<void> updateExpense(String id, double amount, String category, {String? title}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    debugPrint('AppState: Updating expense $id');
    await _db.collection('users').doc(user.uid).collection('expenses').doc(id).update({
      'title': title ?? category,
      'amount': amount,
      'category': category,
    });
  }

  Future<void> addSubscription(String name, double amount, int billingDate) async {
    final user = _auth.currentUser;
    if (user == null) return;
    debugPrint('AppState: Adding subscription $name');
    await _db.collection('users').doc(user.uid).collection('subscriptions').add({
      'name': name,
      'amount': amount,
      'billingDate': billingDate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubscription(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).collection('subscriptions').doc(id).delete();
  }

  Future<void> updateSubscription(String id, String name, double amount, int billingDate) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).collection('subscriptions').doc(id).update({
      'name': name,
      'amount': amount,
      'billingDate': billingDate,
    });
  }

  Future<void> clearAllExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    debugPrint('AppState: Clearing all expenses for user ${user.uid}');
    final snapshots = await _db.collection('users').doc(user.uid).collection('expenses').get();
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _disposeListeners();
    super.dispose();
  }
}
