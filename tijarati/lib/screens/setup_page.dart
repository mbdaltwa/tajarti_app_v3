import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_theme.dart';
import 'home_page.dart'; // سننشئها بعد قليل

class SetupPage extends StatelessWidget {
  final bool isFirstTime;
  const SetupPage({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final box = Hive.box('tajarti_royal_v1');
    
    nameCtrl.text = box.get('shop_name') ?? "";
    phoneCtrl.text = box.get('shop_phone') ?? "";

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue, 
        title: Text(isFirstTime ? "مرحباً بك" : "تعديل المتجر", style: const TextStyle(color: Colors.white)),
        leading: isFirstTime ? null : IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.store, size: 80, color: AppTheme.royalBlue),
              const SizedBox(height: 20),
              Text(isFirstTime ? "إعداد متجرك" : "تحديث البيانات", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.royalBlue)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "اسم المتجر", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), prefixIcon: const Icon(Icons.store))),
              const SizedBox(height: 15),
              TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: "رقم الهاتف", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), prefixIcon: const Icon(Icons.phone))),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                    if(nameCtrl.text.isNotEmpty) {
                        box.put('shop_name', nameCtrl.text);
                        box.put('shop_phone', phoneCtrl.text);
                        if (isFirstTime) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                        } else {
                          Navigator.pop(context); 
                        }
                    }
                },
                child: const Text("حفظ", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}