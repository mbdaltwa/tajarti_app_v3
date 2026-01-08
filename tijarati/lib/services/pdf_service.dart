import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  
  // طباعة كشف الحساب (A4)
  static Future<void> printStatement({
    required Map client,
    required List<Map> data,
    required double tOut,
    required double tIn,
    required double finalBal,
    required String currency,
    required String shopName,
    required String shopPhone,
    bool isShare = false, // هل نريد مشاركة أم طباعة؟
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context context) {
        return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            // الترويسة
            pw.Stack(alignment: pw.Alignment.topCenter, children: [
                pw.Center(child: pw.Text("تجارتي برو", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                   pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Text(shopPhone, style: const pw.TextStyle(fontSize: 10))]),
                   pw.Column(children: [pw.Text("كشف حساب", style: pw.TextStyle(fontSize: 14)), pw.Text("التاريخ: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 8))])
                ])
            ]), 
            pw.Divider(thickness: 2, color: PdfColors.blue900), 
            pw.SizedBox(height: 10),
            
            // بيانات العميل
            pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(5), decoration: pw.BoxDecoration(color: PdfColors.grey100), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("العميل: ${client['name']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text("الجوال: ${client['phone']}")])), 
            pw.SizedBox(height: 10),
            
            // الجدول
            pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(1.5)}, children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue900), children: ["البيان", "له", "عليه", "الرصيد", "التاريخ"].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)))).toList()),
                ...data.map((e) { 
                  final isDebt = e['type'] == 'out'; final index = data.indexOf(e); 
                  return pw.TableRow(decoration: pw.BoxDecoration(color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50), children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e['note'], textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(!isDebt ? "${e['amt']}" : "", textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.green, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(isDebt ? "${e['amt']}" : "", textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.red, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${e['b'].toStringAsFixed(1)}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e['date'].toString().substring(0, 10), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)))
                  ]);
                }).toList(),
                // الفوتر
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue50), children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("الإجمالي النهائي", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${tIn.toStringAsFixed(1)}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${tOut.toStringAsFixed(1)}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("${finalBal.toStringAsFixed(1)}", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 12))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("", textAlign: pw.TextAlign.center))
                ])
            ]), 
            pw.Spacer(), pw.Divider(color: PdfColors.grey), pw.Center(child: pw.Text("تم إصدار هذا الكشف إلكترونياً عبر تطبيق تجارتي برو", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
        ]);
    }));

    if (isShare) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'statement_${client['name']}.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    }
  }

  // طباعة الإيصال الفوري (الصغير)
  static Future<void> printReceipt({
    required Map client,
    required double amount,
    required String note,
    required String type,
    required String date,
    required double oldBal,
    required double newBal,
    required String currency,
    required String shopName,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(pw.Page(pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm), theme: pw.ThemeData.withFont(base: font, bold: boldFont), textDirection: pw.TextDirection.rtl, build: (pw.Context context) {
        return pw.Column(mainAxisSize: pw.MainAxisSize.min, crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Text(shopName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)), pw.Text("إيصال عملية", style: const pw.TextStyle(fontSize: 10)), pw.Divider(thickness: 1, color: PdfColors.grey), pw.SizedBox(height: 5),
            pw.Text(type == 'out' ? "تسجيل دين" : "سداد مبلغ", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)), pw.Text("${amount.toStringAsFixed(2)} $currency", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black)), pw.SizedBox(height: 10),
            pw.Container(padding: const pw.EdgeInsets.all(5), decoration: pw.BoxDecoration(border: pw.Border.all(style: pw.BorderStyle.dashed)), child: pw.Column(children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("العميل:"), pw.Text(client['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]), pw.Divider(thickness: 0.5),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("الرصيد السابق:"), pw.Text("${oldBal.toStringAsFixed(1)}")]), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("المبلغ الحالي:"), pw.Text("${amount.toStringAsFixed(1)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]), pw.Divider(thickness: 0.5),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("المتبقي عليه:"), pw.Text("${newBal.toStringAsFixed(1)} $currency", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))]),
            ])), pw.SizedBox(height: 10),
            pw.Text("البيان: $note", style: const pw.TextStyle(fontSize: 8)), pw.Text(date.substring(0, 16), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)), pw.Text("نظام تجارتي برو", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
        ]);
    }));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}