import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_theme.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final box = Hive.box('tajarti_royal_v1');
  List products = [];

  @override
  void initState() {
    super.initState();
    products = box.get('products') ?? [];
  }

  void _addProductDialog() {
    final name = TextEditingController();
    final price = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("منتج جديد", style: TextStyle(color: AppTheme.royalBlue)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: "اسم الصنف", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر", border: OutlineInputBorder())),
      ]),
      actions: [
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue), onPressed: () {
          if(name.text.isNotEmpty && price.text.isNotEmpty) {
            products.add({'name': name.text, 'price': double.parse(price.text)});
            box.put('products', products);
            setState((){}); Navigator.pop(ctx);
          }
        }, child: const Text("إضافة", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue, 
        title: const Text("المخزن السريع", style: TextStyle(color: Colors.white)), 
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))
      ),
      body: products.isEmpty 
      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey), Text("أضف منتجاتك لتسهيل البيع", style: TextStyle(color: Colors.grey))]))
      : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: products.length,
        itemBuilder: (ctx, i) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.local_offer, color: AppTheme.royalBlue)),
            title: Text(products[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${products[i]['price']} ريال"),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
              products.removeAt(i); box.put('products', products); setState((){});
            }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.alertOrange, onPressed: _addProductDialog, child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}