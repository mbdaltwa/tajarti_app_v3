import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/backup_service.dart';
import '../utils/app_theme.dart';
import '../screens/products_page.dart';
import '../screens/setup_page.dart';
// التغيير هنا: استدعاء HomePage من مكانها الصحيح الجديد
import '../screens/home_page.dart'; 

class RoyalDrawer extends StatelessWidget {
  const RoyalDrawer({super.key});

  void _openSettings(BuildContext context) {
    final box = Hive.box('tajarti_royal_v1');
    bool isFingerprintEnabled = box.get('fingerprint_enabled') ?? false;
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text("الإعدادات", style: TextStyle(color: AppTheme.royalBlue)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.fingerprint, size: 30, color: AppTheme.royalBlue),
                title: const Text("قفل التطبيق بالبصمة"),
                trailing: Switch(
                  activeColor: AppTheme.royalBlue,
                  value: isFingerprintEnabled,
                  onChanged: (val) {
                    setState(() {isFingerprintEnabled = val; box.put('fingerprint_enabled', val);});
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.store, color: AppTheme.royalBlue),
                title: const Text("تعديل بيانات المتجر"),
                onTap: () { 
                  Navigator.pop(ctx); 
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage(isFirstTime: false))); 
                },
              )
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إغلاق"))],
        );
      }
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.royalBlue, Color(0xFF3949AB)])
            ),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet, size: 40, color: AppTheme.royalBlue)),
                  const SizedBox(height: 10),
                  const Text("تجارتي برو", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ])),
          ),
          ListTile(leading: const Icon(Icons.home, color: AppTheme.royalBlue), title: const Text("الرئيسية"), onTap: () {
            Navigator.pop(context);
            // التأكد من عدم تكرار الصفحة إذا كنا فيها أصلاً
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }),
          ListTile(leading: const Icon(Icons.category, color: Colors.orange), title: const Text("إدارة المنتجات"), onTap: () {
            Navigator.pop(context); 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsPage()));
          }),
          ListTile(leading: const Icon(Icons.download, color: AppTheme.royalBlue), title: const Text("حفظ نسخة احتياطية"), onTap: () => BackupService.createBackup(context)),
          ListTile(leading: const Icon(Icons.upload, color: AppTheme.royalBlue), title: const Text("استرجاع نسخة احتياطية"), onTap: () => BackupService.restoreBackup(context, () {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          })),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings, color: Colors.grey), title: const Text("الإعدادات"), onTap: () => _openSettings(context)),
          ListTile(leading: const Icon(Icons.support_agent, color: Colors.blue), title: const Text("دعم فني"), onTap: () async {
              final url = Uri.parse("https://wa.me/?text=مساعدة"); if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          }),
        ],
      ),
    );
  }
}