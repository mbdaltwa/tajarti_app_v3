import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../services/pdf_service.dart';

class ClientDetail extends StatefulWidget {
  final String id;
  const ClientDetail({super.key, required this.id});
  @override
  State<ClientDetail> createState() => _ClientDetailState();
}

class _ClientDetailState extends State<ClientDetail> {
  final box = Hive.box('tajarti_royal_v1');

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openWhatsAppOptions(BuildContext context, String phone, String name, double balance, String currency) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("اختر نوع الرسالة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.royalBlue)), const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.sentiment_satisfied_alt, color: Colors.green), title: const Text("تذكير لطيف"), onTap: () {Navigator.pop(ctx); _launchURL("https://wa.me/$phone?text=${Uri.encodeComponent('مرحباً أخي $name، نود تذكيرك بلطف بأن الرصيد المتبقي هو $balance $currency.')}");}),
            ListTile(leading: const Icon(Icons.description, color: Colors.blue), title: const Text("مطالبة رسمية"), onTap: () {Navigator.pop(ctx); _launchURL("https://wa.me/$phone?text=${Uri.encodeComponent('عزيزي العميل $name، يرجى التكرم بسداد المبلغ المستحق $balance $currency.')}");}),
    ])));
  }

  void _deleteTransaction(int index, Map clientData) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("حذف العملية"), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
            List tr = List.from(clientData['trans']); tr.removeAt(index);
            box.put(widget.id, {...clientData, 'trans': tr}); setState((){}); Navigator.pop(ctx);
          }, child: const Text("حذف", style: TextStyle(color: Colors.white)))
      ]));
  }

  @override
  Widget build(BuildContext context) {
    var c = box.get(widget.id);
    if(c == null) return const Scaffold(body: Center(child: Text("خطأ")));

    String currency = c['currency'] ?? 'YR';
    List tr = List.from(c['trans'] ?? []);
    double bal = 0, totalIn = 0, totalOut = 0;
    List<Map> data = [];

    for(var t in tr) {
      if(t['type'] == 'out') { bal += t['amt']; totalOut += t['amt']; } 
      else { bal -= t['amt']; totalIn += t['amt']; }
      data.add({...t, 'b': bal});
    }

    final sName = box.get('shop_name') ?? "متجري";
    final sPhone = box.get('shop_phone') ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: Row(children: [const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name'], style: const TextStyle(fontSize: 16, color: Colors.white)), Text("${c['phone']} ($currency)", style: const TextStyle(fontSize: 12, color: Colors.white70))])]),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => PdfService.printStatement(client: c, data: data, tOut: totalOut, tIn: totalIn, finalBal: bal, currency: currency, shopName: sName, shopPhone: sPhone, isShare: true)),
          IconButton(icon: const Icon(Icons.print, color: Colors.white), onPressed: () => PdfService.printStatement(client: c, data: data, tOut: totalOut, tIn: totalIn, finalBal: bal, currency: currency, shopName: sName, shopPhone: sPhone, isShare: false)),
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () => _launchURL("tel:${c['phone']}")),
        ],
      ),
      body: Column(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), color: Colors.white, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("الرصيد المستحق", style: TextStyle(fontSize: 12, color: Colors.grey)), Text("${bal.toStringAsFixed(2)} $currency", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bal > 0 ? AppTheme.alertOrange : AppTheme.royalBlue))]),
                 ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white), icon: const Icon(Icons.chat), label: const Text("تذكير"), onPressed: () => _openWhatsAppOptions(context, c['phone'], c['name'], bal, currency))
              ])),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(15), itemCount: data.length, itemBuilder: (ctx, i) {
                int originalIndex = data.length - 1 - i;
                final item = data[originalIndex]; 
                final isDebt = item['type'] == 'out';
                String? dueDate = item['dueDate'];
                bool isOverdue = false;
                if(isDebt && dueDate != null) { isOverdue = DateTime.parse(dueDate).isBefore(DateTime.now()); }

                return InkWell(
                  onLongPress: () => _deleteTransaction(originalIndex, c),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
                    width: MediaQuery.of(context).size.width * 0.75,
                    decoration: BoxDecoration(color: isDebt ? Colors.white : const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(15)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(isDebt ? "عليه (دين)" : "له (سداد)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDebt ? AppTheme.alertOrange : AppTheme.royalBlue)),
                          Text("${item['amt']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const Divider(height: 10, thickness: 0.5),
                        Text(item['note'], style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                           Text(item['date'].toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                           if(isDebt && dueDate != null) Row(children: [Icon(isOverdue ? Icons.access_alarm : Icons.calendar_today, size: 12, color: isOverdue ? Colors.red : Colors.grey), const SizedBox(width: 4), Text("وعد: ${dueDate.substring(0,10)}", style: TextStyle(fontSize: 10, color: isOverdue ? Colors.red : Colors.grey))])
                        ])
                    ]),
                  ),
                );
              })),
      ]),
      bottomNavigationBar: Container(padding: const EdgeInsets.all(10), color: Colors.white, child: Row(children: [
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertOrange), onPressed: () => _addTransDialog('out', c, bal), child: const Text("تسجيل دين 🔴", style: TextStyle(color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue), onPressed: () => _addTransDialog('in', c, bal), child: const Text("تسجيل سداد 🔵", style: TextStyle(color: Colors.white)))),
          ])),
    );
  }

  void _addTransDialog(String type, Map client, double currentBal) {
    final amt = TextEditingController();
    final note = TextEditingController();
    final box = Hive.box('tajarti_royal_v1');
    List products = box.get('products') ?? [];
    String currency = client['currency'] ?? 'YR';
    DateTime? promiseDate;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(type == 'out' ? "إضافة دين" : "إضافة سداد", style: const TextStyle(color: AppTheme.royalBlue)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if(products.isNotEmpty) ...[
              const Text("أصناف سريعة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              Wrap(spacing: 5, children: products.map((p) => ActionChip(label: Text("${p['name']} (${p['price']})", style: const TextStyle(fontSize: 10)), onPressed: () {amt.text = p['price'].toString(); note.text = p['name'];})).toList()),
              const Divider(),
            ],
            TextField(controller: amt, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "المبلغ ($currency)", border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: note, decoration: const InputDecoration(labelText: "البيان", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            if(type == 'out')
              OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(promiseDate == null ? "موعد سداد (اختياري)" : "${promiseDate.toString().substring(0,10)}"), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030)); if(d != null) setState(() => promiseDate = d); }),
          ]),
        ),
        actions: [
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white), onPressed: () {
            if(amt.text.isNotEmpty) {
               var c = box.get(widget.id); List tr = List.from(c['trans'] ?? []);
               double amount = double.parse(amt.text);
               String transDate = DateTime.now().toString();
               tr.add({'amt': amount, 'note': note.text, 'type': type, 'date': transDate, 'dueDate': promiseDate?.toString()});
               box.put(widget.id, {...c, 'trans': tr});
               double newBal = type == 'out' ? currentBal + amount : currentBal - amount;
               setState((){}); Navigator.pop(ctx);
               showDialog(context: context, builder: (ctx2) => AlertDialog(
                 content: Column(mainAxisSize: MainAxisSize.min, children: [
                   const Icon(Icons.check_circle, color: AppTheme.royalBlue, size: 60),
                   const Text("تمت العملية", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   const Text("هل تريد مشاركة إيصال؟"),
                 ]),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text("لا")),
                   ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white), onPressed: () { 
                       Navigator.pop(ctx2); 
                       final sName = box.get('shop_name') ?? "";
                       PdfService.printReceipt(client: client, amount: amount, note: note.text, type: type, date: transDate, oldBal: currentBal, newBal: newBal, currency: currency, shopName: sName); 
                     }, icon: const Icon(Icons.receipt), label: const Text("إيصال"))
                 ],
               ));
            }
          }, child: const Text("حفظ"))
        ],
      )
    ));
  }
}