import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart'; // نستخدمها للمشاركة

class BackupService {
  // دالة التصدير (Backup)
  static Future<void> createBackup(BuildContext context) async {
    try {
      final box = Hive.box('tajarti_royal_v1');
      Map<String, dynamic> allData = box.toMap().cast<String, dynamic>();
      String jsonString = jsonEncode(allData);
      
      // نستخدم Printing للمشاركة كملف (حيلة ذكية لتعمل على كل المنصات)
      await Printing.sharePdf(
        bytes: Uint8List.fromList(utf8.encode(jsonString)), 
        filename: 'tajarti_backup_${DateTime.now().millisecondsSinceEpoch}.json'
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل النسخ: $e"), backgroundColor: Colors.red));
    }
  }

  // دالة الاستعادة (Restore)
  static Future<void> restoreBackup(BuildContext context, VoidCallback onSuccess) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;
        if(fileBytes != null) {
          String content = utf8.decode(fileBytes);
          Map<String, dynamic> data = jsonDecode(content);
          
          final box = Hive.box('tajarti_royal_v1');
          await box.clear(); // تنظيف القديم
          await box.putAll(data); // وضع الجديد
          
          onSuccess(); // استدعاء دالة النجاح لتحديث الواجهة
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم استعادة البيانات بنجاح!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الملف: $e"), backgroundColor: Colors.red));
    }
  }
}