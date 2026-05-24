import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/firebase_expense_repo.dart';
import '../../data/auth/firebase_auth_service.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/budget.dart';

// --- FIREBASE AUTH & FALLBACK MOCK CONNECTIONS ---

final authServiceProvider = Provider((ref) => FirebaseAuthService());

class MockUser {
  final String uid = 'mock-user-123';
  final String displayName = 'Local Tester';
  final String email = 'test@example.com';
}

class MockAuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void login() => state = true;
}
final isMockLoggedInProvider = NotifierProvider<MockAuthNotifier, bool>(MockAuthNotifier.new);

final authStateProvider = StreamProvider<dynamic>((ref) async* {
  try {
    if (Firebase.apps.isNotEmpty) {
      yield* FirebaseAuth.instance.authStateChanges();
      return;
    }
  } catch (e) {
    print('Firebase authState bypass: $e');
  }
  
  final isMockLoggedIn = ref.watch(isMockLoggedInProvider);
  yield isMockLoggedIn ? MockUser() : null;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user is User) return user.uid;
  if (user is MockUser) return user.uid;
  return null;
});

// --- MOCK REPOSITORY FOR LOCAL TESTING ---
class MockExpenseRepository implements ExpenseRepository {
  final _controller = StreamController<List<Expense>>.broadcast();
  final List<Expense> _expenses = [];

  MockExpenseRepository() {
    Future.delayed(Duration.zero, () => _controller.add(List.from(_expenses)));
  }

  @override
  Stream<List<Expense>> watchTodayExpenses() {
    return _controller.stream.map((expenses) {
      final now = DateTime.now();
      DateTime startOfFinancialDay = DateTime(now.year, now.month, now.day, 5);
      if (now.hour < 5) {
        startOfFinancialDay = startOfFinancialDay.subtract(const Duration(days: 1));
      }
      return expenses.where((e) => e.timestamp.isAfter(startOfFinancialDay)).toList();
    });
  }

  @override
  Stream<List<Expense>> watchAllExpenses() => _controller.stream;

  @override
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    _controller.add(List.from(_expenses)); 
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    _controller.add(List.from(_expenses));
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _controller.add(List.from(_expenses));
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  
  try {
     if (Firebase.apps.isNotEmpty) {
       return FirebaseExpenseRepository(FirebaseFirestore.instance, uid);
     }
  } catch(e) {
    print('Firebase Repo bypass: $e');
  }
  
  return MockExpenseRepository(); 
});

final todayExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.watchTodayExpenses();
});

final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.watchAllExpenses();
});

final categoryWiseExpensesProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final expensesAsync = ref.watch(allExpensesProvider);
  
  return expensesAsync.whenData((expenses) {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      if (expense.type == 'expense') {
        categoryTotals[expense.categoryId] = (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }
    }
    return categoryTotals;
  });
});

final categoryColorsProvider = Provider<Map<String, Color>>((ref) {
  return {
    'Food': const Color(0xFFFF9500),
    'Transport': const Color(0xFF5AC8FA),
    'Bills': const Color(0xFF5856D6),
    'Shopping': const Color(0xFFFF2D55),
    'Entertainment': const Color(0xFFA2845E),
    'Salary': const Color(0xFF34C759),
    'Other': const Color(0xFF8E8E93),
  };
});

// --- APP STATE (Settings) ---

final userProfileProvider = Provider((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user is User) {
    return {'name': user.displayName ?? 'No Name', 'email': user.email ?? 'No Email'};
  } else if (user is MockUser) {
    return {'name': user.displayName, 'email': user.email};
  }
  return {'name': 'Anonymous', 'email': 'Login Required'};
});

class VendorMemory {
  final String note;
  final String category;
  const VendorMemory(this.note, this.category);
}
class VendorMemoryNotifier extends Notifier<Map<String, VendorMemory>> {
  @override
  Map<String, VendorMemory> build() => {};
  void learn(String rawVendor, String customNote, String category) {
    state = {...state, rawVendor: VendorMemory(customNote, category)};
  }
}
final vendorMemoryProvider = NotifierProvider<VendorMemoryNotifier, Map<String, VendorMemory>>(VendorMemoryNotifier.new);

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() => 'INR';
  void setCurrency(String c) => state = c;
}
final currencyProvider = NotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);

class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void setEnabled(bool val) => state = val;
}
final notificationsEnabledProvider = NotifierProvider<NotificationsNotifier, bool>(NotificationsNotifier.new);

class BudgetNotifier extends Notifier<Budget> {
  @override
  Budget build() => const Budget(dailyLimit: 1000.0);
  void updateLimit(double daily, double? monthly) {
    state = state.copyWith(dailyLimit: daily, monthlyLimit: monthly);
  }
}
final budgetProvider = NotifierProvider<BudgetNotifier, Budget>(BudgetNotifier.new);

class BudgetMetrics {
  final double limit;
  final double spent;
  final double remaining;
  const BudgetMetrics({required this.limit, required this.spent, required this.remaining});
}

final dailyBudgetMetricsProvider = Provider<AsyncValue<BudgetMetrics>>((ref) {
  final budget = ref.watch(budgetProvider);
  final todayExpensesAsync = ref.watch(todayExpensesProvider);

  if (todayExpensesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  final totalSpent = todayExpensesAsync.value?.fold<double>(
      0, (sum, exp) => sum + (exp.type == 'expense' ? exp.amount : 0)) ?? 0.0;
  
  final dailyLimit = budget.dailyLimit;
  final remaining = dailyLimit - totalSpent;

  return AsyncValue.data(BudgetMetrics(limit: dailyLimit, spent: totalSpent, remaining: remaining));
});

extension CurrencySymbolExt on String {
  String get symbol {
    switch (this) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return this;
    }
  }
}
