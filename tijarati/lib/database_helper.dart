import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tijarati.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // إنشاء الجداول (جدول العملاء وجدول العمليات)
  Future _createDB(Database db, int version) async {
    // جدول العملاء
    await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT
    )
    ''');

    // جدول العمليات (له وعليه)
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customerId INTEGER,
      amount REAL NOT NULL,
      note TEXT,
      date TEXT,
      isCredit INTEGER, -- 1 لـ "له" ، 0 لـ "عليه"
      FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
    )
    ''');
  }

  // --- عمليات العملاء ---
  
  Future<int> addCustomer(String name, String phone) async {
    final db = await instance.database;
    return await db.insert('customers', {'name': name, 'phone': phone});
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await instance.database;
    return await db.query('customers', orderBy: 'name');
  }

  // --- عمليات المبالغ والديون ---

  Future<int> addTransaction(int customerId, double amount, String note, String date, int isCredit) async {
    final db = await instance.database;
    return await db.insert('transactions', {
      'customerId': customerId,
      'amount': amount,
      'note': note,
      'date': date,
      'isCredit': isCredit,
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions(int customerId) async {
    final db = await instance.database;
    return await db.query('transactions', where: 'customerId = ?', whereArgs: [customerId], orderBy: 'id DESC');
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}