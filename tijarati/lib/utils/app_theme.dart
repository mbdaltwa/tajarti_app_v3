import 'package:flutter/material.dart';

class AppTheme {
  static const Color royalBlue = Color(0xFF1A237E); // اللون الأساسي
  static const Color alertOrange = Color(0xFFE65100); // للتنبيهات والديون
  static const Color background = Color(0xFFF5F7FA); // الخلفية
  static const Color white = Colors.white;
  
  // ثيم النصوص (اختياري لتوحيد الخطوط)
  static TextStyle heading = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: royalBlue);
  static TextStyle body = const TextStyle(fontSize: 14, color: Colors.black87);
}