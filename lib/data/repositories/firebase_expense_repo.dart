import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expense.dart';
import 'expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  FirebaseExpenseRepository(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>> get _expensesRef => 
      _firestore.collection('users').doc(_userId).collection('expenses');

  @override
  Stream<List<Expense>> watchTodayExpenses() {
    final now = DateTime.now();
    DateTime startOfFinancialDay = DateTime(now.year, now.month, now.day, 5);
    if (now.hour < 5) {
      startOfFinancialDay = startOfFinancialDay.subtract(const Duration(days: 1));
    }
    
    return _expensesRef
        .where('timestamp', isGreaterThanOrEqualTo: startOfFinancialDay)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id})).toList());
  }
  
  @override
  Stream<List<Expense>> watchAllExpenses() {
    return _expensesRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id})).toList());
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _expensesRef.doc(expense.id).set(expense.toJson());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _expensesRef.doc(expense.id).update(expense.toJson());
  }
}
