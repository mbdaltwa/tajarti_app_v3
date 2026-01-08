import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';
import '../widgets/royal_drawer.dart';
import 'client_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('tajarti_royal_v1');
  String search = "";
  String filterCurrency = 'All';
  bool isPrivacyMode = false;

  // ... (هنا نفس دوال getChartData و getTotalsByCurrency التي كانت في main.dart) ...
  // للاختصار، سأكتبها هنا، تأكد من نسخها كاملة كما في الكود السابق
  Map<String, double> getChartData() {
    double totalOut = 0; double totalIn = 0;  
    for (var key in box.keys) {
      if (key == 'shop_name' || key == 'shop_phone' || key == 'fingerprint_enabled' || key == 'products') continue;
      var c = box.get(key);
      if (filterCurrency != 'All' && c['currency'] != filterCurrency) continue;
      if (c is Map && c.containsKey('trans')) {
         for(var t in c['trans']) {
           if(t['type'] == 'out') totalOut += t['amt']; else totalIn += t['amt'];
         }
      }
    }
    return {'out': totalOut, 'in': totalIn};
  }

  Map<String, double> getTotalsByCurrency() {
    double yemenRial = 0; double saudiRial = 0; double usDollar = 0;
    for (var key in box.keys) {
      if (key == 'shop_name' || key == 'shop_phone' || key == 'fingerprint_enabled' || key == 'products') continue;
      var c = box.get(key);
      if (c is Map && c.containsKey('trans')) {
        String curr = c['currency'] ?? 'YR'; 
        double bal = _calculateBalance(c['trans']);
        if (curr == 'SAR') saudiRial += bal; else if (curr == 'USD') usDollar += bal; else yemenRial += bal;
      }
    }
    return {'YR': yemenRial, 'SAR': saudiRial, 'USD': usDollar};
  }

  double _calculateBalance(List? trans) {
    if (trans == null) return 0;
    double bal = 0;
    for (var t in trans) {
      if (t['type'] == 'out') bal += t['amt']; else bal -= t['amt'];
    }
    return bal;
  }

  @override
  Widget build(BuildContext context) {
    var clients = box.values.where((e) => e is Map && e.containsKey('name')).toList();
    var filtered = clients.where((c) {
      bool matchesSearch = c['name'].toString().contains(search);
      bool matchesCurrency = filterCurrency == 'All' || c['currency'] == filterCurrency;
      return matchesSearch && matchesCurrency;
    }).toList();
    
    filtered.sort((a, b) {
      double balA = _calculateBalance(a['trans']);
      double balB = _calculateBalance(b['trans']);
      return balB.compareTo(balA);
    });

    final chartData = getChartData();
    final totals = getTotalsByCurrency();

    return Scaffold(
      drawer: const RoyalDrawer(), 
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 0, right: 0, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.royalBlue, Color(0xFF3949AB)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 30), onPressed: () => Scaffold.of(context).openDrawer())),
                      const Text("تجارتي", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      IconButton(icon: Icon(isPrivacyMode ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 28), onPressed: () => setState(() => isPrivacyMode = !isPrivacyMode))
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!isPrivacyMode && (chartData['out']! > 0 || chartData['in']! > 0))
                  SizedBox(height: 100, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 25, sections: [PieChartSectionData(color: AppTheme.alertOrange, value: chartData['out'], title: '', radius: 15), PieChartSectionData(color: Colors.white, value: chartData['in'], title: '', radius: 18)])))
                else if (isPrivacyMode)
                   const SizedBox(height: 100, child: Center(child: Icon(Icons.lock, size: 50, color: Colors.white24)))
                else
                   const SizedBox(height: 20),

                const SizedBox(height: 10),
                SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [_buildCurrencyCard("ريال يمني", totals['YR']!), _buildCurrencyCard("ريال سعودي", totals['SAR']!), _buildCurrencyCard("دولار أمريكي", totals['USD']!)])),
                const SizedBox(height: 15),
                SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_buildFilterChip("الكل", 'All'), const SizedBox(width: 10), _buildFilterChip("يمني (YR)", 'YR'), const SizedBox(width: 10), _buildFilterChip("سعودي (SAR)", 'SAR'), const SizedBox(width: 10), _buildFilterChip("دولار (USD)", 'USD')])),
                const SizedBox(height: 15),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(onChanged: (v) => setState(() => search = v), style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "بحث عن عميل...", hintStyle: const TextStyle(color: Colors.white60), prefixIcon: const Icon(Icons.search, color: Colors.white70), filled: true, fillColor: Colors.black12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20)))),
              ],
            ),
          ),
          Expanded(child: filtered.isEmpty ? const Center(child: Text("لا يوجد بيانات", style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.all(15), itemCount: filtered.length, itemBuilder: (ctx, i) { final client = filtered[i]; double balance = _calculateBalance(client['trans']); return _buildClientCard(client, balance); })),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.alertOrange, child: const Icon(Icons.person_add, color: Colors.white), onPressed: _addClientDialog),
    );
  }

  Widget _buildFilterChip(String label, String code) {
    bool isSelected = filterCurrency == code;
    return ChoiceChip(label: Text(label), selected: isSelected, onSelected: (val) => setState(() => filterCurrency = code), selectedColor: Colors.white, backgroundColor: Colors.white.withOpacity(0.2), labelStyle: TextStyle(color: isSelected ? AppTheme.royalBlue : Colors.white, fontWeight: FontWeight.bold), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
  }

  Widget _buildCurrencyCard(String title, double val) {
    final fmt = intl.NumberFormat("#,##0.0");
    return Container(width: 140, margin: const EdgeInsets.symmetric(horizontal: 5), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), Text(isPrivacyMode ? "****" : fmt.format(val), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  Widget _buildClientCard(Map client, double balance) {
    bool isDebt = balance > 0;
    String currency = client['currency'] ?? 'YR';
    return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetail(id: client['id']))).then((_) => setState((){})), leading: CircleAvatar(backgroundColor: const Color(0xFFF5F7FA), child: Text(currency.substring(0,1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalBlue))), title: Text(client['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalBlue)), subtitle: Text(client['phone']), trailing: Text(isPrivacyMode ? "****" : "${balance.toStringAsFixed(1)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDebt ? AppTheme.alertOrange : AppTheme.royalBlue))));
  }

  void _addClientDialog() {
    final n = TextEditingController(); final p = TextEditingController(); String currency = 'YR';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) { return AlertDialog(title: const Text("عميل جديد", style: TextStyle(color: AppTheme.royalBlue)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: "الاسم", border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "الجوال", border: OutlineInputBorder())), const SizedBox(height: 15), const Text("نوع العملة:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalBlue)), DropdownButton<String>(value: currency, isExpanded: true, items: const [DropdownMenuItem(value: 'YR', child: Text("ريال يمني")), DropdownMenuItem(value: 'SAR', child: Text("ريال سعودي")), DropdownMenuItem(value: 'USD', child: Text("دولار أمريكي"))], onChanged: (v) => setState(() => currency = v!))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue), onPressed: () { if(n.text.isNotEmpty) { String id = DateTime.now().millisecondsSinceEpoch.toString(); box.put(id, {'id': id, 'name': n.text, 'phone': p.text, 'currency': currency, 'trans': []}); setState((){}); Navigator.pop(ctx); } }, child: const Text("حفظ", style: TextStyle(color: Colors.white)))]);}));
  }
}