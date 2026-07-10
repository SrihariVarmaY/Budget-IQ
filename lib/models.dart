import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Budget(
      id: doc.id,
      amount: (data?['amount'] as num?)?.toDouble() ?? 0.0,
      month: (data?['month'] as num?)?.toInt() ?? 0,
      year: (data?['year'] as num?)?.toInt() ?? 0,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final int month;
  final int year;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.month,
    required this.year,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    // Safely extract timestamp from multiple possible fields
    dynamic rawDate = data?['date'] ?? data?['timestamp'] ?? data?['createdAt'];
    Timestamp? timestamp;
    if (rawDate is Timestamp) {
      timestamp = rawDate;
    } else if (rawDate is String) {
      timestamp = Timestamp.fromDate(DateTime.tryParse(rawDate) ?? DateTime.now());
    }

    final date = timestamp?.toDate() ?? DateTime.now();
    
    return Expense(
      id: doc.id,
      title: data?['title'] ?? data?['category'] ?? 'Untitled',
      amount: (data?['amount'] as num?)?.toDouble() ?? 0.0,
      category: data?['category'] ?? 'Other',
      date: date,
      month: (data?['month'] as num?)?.toInt() ?? date.month,
      year: (data?['year'] as num?)?.toInt() ?? date.year,
    );
  }
}

class Subscription {
  final String id;
  final double amount;
  final String name;

  Subscription({
    required this.id,
    required this.amount,
    required this.name,
  });

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Subscription(
      id: doc.id,
      amount: (data?['amount'] as num?)?.toDouble() ?? 0.0,
      name: data?['name'] ?? 'Untitled',
    );
  }
}
