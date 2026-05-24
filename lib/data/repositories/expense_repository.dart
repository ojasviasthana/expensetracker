import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchTodayExpenses();
  Stream<List<Expense>> watchAllExpenses();
  Future<void> addExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> updateExpense(Expense expense);
}
