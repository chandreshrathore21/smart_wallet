import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String date;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'],
        title: map['title'],
        amount: map['amount'],
        category: map['category'],
        type: map['type'],
        date: map['date'],
      );
}
class BudgetModel {
  final String category;
  final double monthlyLimit;

  BudgetModel({required this.category, required this.monthlyLimit});

  Map<String, dynamic> toMap() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
        category: map['category'],
        monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      );
}
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'encrypted_smart_wallet.db');
    const dbPassword = 'YourSecureMasterPassword123!';

    return await openDatabase(
      path,
      password: dbPassword,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets (
            category TEXT PRIMARY KEY,
            monthlyLimit REAL NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budgets (
              category TEXT PRIMARY KEY,
              monthlyLimit REAL NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final res = await db.query('transactions', orderBy: 'date DESC');
    return res.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> setBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    final res = await db.query('budgets');
    return res.map((e) => BudgetModel.fromMap(e)).toList();
  }
}