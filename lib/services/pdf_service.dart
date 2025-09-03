import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import './boxes.dart';

class PdfService {
  // Thermal printer configurations
  static const double thermalWidth58mm = 164.0;  // 58mm width
  static const double thermalWidth80mm = 227.0;  // 80mm width
  
  static Future<void> generateInvoice(
    Sale sale, {
    ThermalSize thermalSize = ThermalSize.mm58,
    bool includeHeader = true,
    bool includeFooter = true,
    bool includeGST = false,
  }) async {
    final doc = pw.Document();
    final double pageWidth = thermalSize == ThermalSize.mm58 
        ? thermalWidth58mm 
        : thermalWidth80mm;
    
    // Load logo
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/icon/floralbill_icon.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Logo not found: $e');
      // Continue without logo
    }
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          pageWidth,
          double.infinity,
          marginLeft: 4,  // Reduced margins for 58mm
          marginRight: 4,
          marginTop: 6,
          marginBottom: 6,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header Section
              if (includeHeader) ..._buildHeader(thermalSize, logoImage),
              
              // Invoice Information
              ..._buildInvoiceInfo(sale, thermalSize),
              
              // Items Section
              ..._buildItemsSection(sale, thermalSize),
              
              // Totals Section
              ..._buildTotalsSection(sale, thermalSize, includeGST),
              
              // Footer Section
              if (includeFooter) ..._buildFooter(thermalSize),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'invoice_${sale.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  // Header Section optimized for both sizes
  static List<pw.Widget> _buildHeader(ThermalSize thermalSize, pw.ImageProvider? logoImage) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    
    return [
      // Company Logo container with proper aspect ratio
      pw.Container(
        width: double.infinity,
        height: is58mm ? 100 : (isWide ? 140 : 120), // Taller box for better logo display
        padding: pw.EdgeInsets.symmetric(
          horizontal: is58mm ? 4 : 6,
          vertical: is58mm ? 8 : 10,
        ), // Asymmetric padding for better fit
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 2),
          borderRadius: pw.BorderRadius.circular(8),
          color: PdfColors.white,
        ),
        child: pw.Center(
          child: logoImage != null 
            ? pw.Container(
                width: double.infinity,
                height: double.infinity,
                child: pw.Image(
                  logoImage,
                  fit: pw.BoxFit.contain, // Changed from fill to contain for better aspect ratio
                  alignment: pw.Alignment.center,
                ),
              )
            : pw.Container(
                constraints: pw.BoxConstraints(
                  maxWidth: double.infinity,
                  maxHeight: is58mm ? 40 : (isWide ? 65 : 50),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Royal',
                      style: pw.TextStyle(
                        fontSize: is58mm ? 16 : (isWide ? 24 : 20),
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'garden',
                      style: pw.TextStyle(
                        fontSize: is58mm ? 14 : (isWide ? 20 : 17),
                        fontWeight: pw.FontWeight.normal,
                        letterSpacing: 1.5,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (!is58mm) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'TANGERANG',
                        style: pw.TextStyle(
                          fontSize: isWide ? 8 : 7,
                          fontWeight: pw.FontWeight.normal,
                          letterSpacing: 1.0,
                          color: PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
        ),
      ),
      pw.SizedBox(height: is58mm ? 6 : 10),
    ];
  }

  // Invoice Information Section optimized for 58mm
  static List<pw.Widget> _buildInvoiceInfo(Sale sale, ThermalSize thermalSize) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    
    return [
      // Invoice Title
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.symmetric(
          vertical: is58mm ? 4 : 6, 
          horizontal: is58mm ? 8 : 12
        ),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'INVOICE',
          style: pw.TextStyle(
            fontSize: is58mm ? 10 : (isWide ? 14 : 12),
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.SizedBox(height: is58mm ? 4 : 8),
      
      // Invoice Details - always use column layout for 58mm
      pw.Container(
        width: double.infinity,
        child: is58mm || !isWide
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('ID:', sale.id, thermalSize),
                  _buildInfoRow('Date:', DateFormat(is58mm ? 'dd/MM/yy HH:mm' : 'dd/MM/yyyy HH:mm').format(sale.date), thermalSize),
                  if (sale.customerName.isNotEmpty)
                    _buildInfoRow('Customer:', _truncateText(sale.customerName, is58mm ? 15 : 20), thermalSize),
                  if (sale.customerPhone.isNotEmpty)
                    _buildInfoRow('Phone:', sale.customerPhone, thermalSize),
                  _buildInfoRow('Payment:', sale.payment.name.toUpperCase(), thermalSize),
                ],
              )
            : pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Invoice ID:', sale.id, thermalSize),
                        _buildInfoRow('Date:', DateFormat('dd/MM/yyyy').format(sale.date), thermalSize),
                        _buildInfoRow('Time:', DateFormat('HH:mm:ss').format(sale.date), thermalSize),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (sale.customerName.isNotEmpty)
                          _buildInfoRow('Customer:', sale.customerName, thermalSize),
                        if (sale.customerPhone.isNotEmpty)
                          _buildInfoRow('Phone:', sale.customerPhone, thermalSize),
                        _buildInfoRow('Payment:', sale.payment.name.toUpperCase(), thermalSize),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      pw.SizedBox(height: is58mm ? 6 : 10),
    ];
  }

  // Items Section optimized for long item names and 58mm
  static List<pw.Widget> _buildItemsSection(Sale sale, ThermalSize thermalSize) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    final double fontSize = is58mm ? 7 : (isWide ? 9 : 8);
    final double headerFontSize = is58mm ? 8 : (isWide ? 10 : 9);
    
    return [
      // Items Header
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey800,
          borderRadius: pw.BorderRadius.circular(2),
        ),
        padding: pw.EdgeInsets.symmetric(
          vertical: is58mm ? 3 : 4, 
          horizontal: is58mm ? 4 : 6
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: is58mm ? 3 : (isWide ? 6 : 4),
              child: pw.Text(
                'ITEM',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.Container(
              width: is58mm ? 20 : (isWide ? 30 : 25),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'QTY',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              width: is58mm ? 30 : (isWide ? 40 : 35),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'RATE',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Container(
              width: is58mm ? 35 : (isWide ? 45 : 40),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'AMT',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      
      // Items List
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Column(
          children: [
            ...sale.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemRow(item, index, thermalSize);
            }).toList(),
          ],
        ),
      ),
      pw.SizedBox(height: is58mm ? 4 : 8),
    ];
  }

  // Individual Item Row optimized for 58mm and long names
  static pw.Widget _buildItemRow(SaleItem item, int index, ThermalSize thermalSize) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    final product = Hive.box<Product>(Boxes.products).get(item.productId);
    final productName = product?.name ?? 'Unknown Product';
    final qty = item.qty.toStringAsFixed(product?.unit == UnitType.kg ? 1 : 0);
    final unitLabel = item.unitLabel.isNotEmpty ? item.unitLabel : (product?.unit.name ?? '');
    
    // Force 15 character limit per line
    String firstLine = '';
    String secondLine = '';
    
    if (productName.length <= 15) {
      firstLine = productName;
    } else {
      firstLine = productName.substring(0, 15);
      if (productName.length > 30) {
        secondLine = productName.substring(15, 30) + '..';
      } else {
        secondLine = productName.substring(15);
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: index % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(
        vertical: secondLine.isNotEmpty ? (is58mm ? 4 : 8) : (is58mm ? 3 : 6), 
        horizontal: is58mm ? 4 : 6
      ),
      child: is58mm ? 
      // 58mm: Two-line layout for better readability
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Product name line
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  firstLine + (secondLine.isNotEmpty ? '\n' + secondLine : ''),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1),
          // Quantity, rate, amount line
          pw.Row(
            children: [
              if (unitLabel.isNotEmpty) ...[
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    unitLabel,
                    style: pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ] else 
                pw.Expanded(flex: 2, child: pw.Container()),
              pw.Container(
                width: 20,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  qty,
                  style: pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                width: 30,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${item.sellingPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Container(
                width: 35,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${item.subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ) :
      // 80mm: Single-line layout
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: isWide ? 6 : 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  firstLine,
                  style: pw.TextStyle(
                    fontSize: isWide ? 9 : 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (secondLine.isNotEmpty)
                  pw.Text(
                    secondLine,
                    style: pw.TextStyle(
                      fontSize: isWide ? 9 : 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (unitLabel.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Unit: $unitLabel',
                    style: pw.TextStyle(
                      fontSize: isWide ? 7 : 6,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Container(
            width: isWide ? 30 : 25,
            alignment: pw.Alignment.center,
            child: pw.Text(
              qty,
              style: pw.TextStyle(fontSize: isWide ? 9 : 8),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: isWide ? 40 : 35,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Rs.${item.sellingPrice.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: isWide ? 9 : 8),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(
            width: isWide ? 45 : 40,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Rs.${item.subtotal.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: isWide ? 9 : 8,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Totals Section optimized for 58mm
  static List<pw.Widget> _buildTotalsSection(Sale sale, ThermalSize thermalSize, bool includeGST) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    final subtotal = sale.items.fold(0.0, (a, b) => a + b.subtotal);
    final gstAmount = includeGST ? (sale.totalAmount * 0.18) : 0.0;
    
    // Font sizes based on printer width
    final double normalFontSize = is58mm ? 8 : (isWide ? 10 : 9);
    final double totalFontSize = is58mm ? 9 : (isWide ? 12 : 10);
    
    return [
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        padding: pw.EdgeInsets.all(is58mm ? 4 : 8),
        child: pw.Column(
          children: [
            // Subtotal
            _buildCompactTotalRow('Subtotal:', subtotal.toStringAsFixed(2), normalFontSize),
            
            if (sale.discount > 0) ...[
              pw.SizedBox(height: is58mm ? 1 : 2),
              _buildCompactTotalRow('Discount:', '-${sale.discount.toStringAsFixed(2)}', 
                  normalFontSize, valueColor: PdfColors.red),
            ],
            
            if (includeGST && gstAmount > 0) ...[
              pw.SizedBox(height: is58mm ? 1 : 2),
              _buildCompactTotalRow('GST (18%):', gstAmount.toStringAsFixed(2), normalFontSize),
            ],
            
            pw.SizedBox(height: is58mm ? 2 : 4),
            pw.Container(
              width: double.infinity,
              height: 0.5,
              color: PdfColors.grey600,
            ),
            pw.SizedBox(height: is58mm ? 2 : 4),
            
            // Total amount - optimized for small width
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  is58mm ? 'TOTAL:' : 'TOTAL AMOUNT:',
                  style: pw.TextStyle(
                    fontSize: totalFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Rs.${sale.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: totalFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            
            // Amount in words - only for wider printers
            if (isWide) ...[
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  'Amount in Words: ${_convertToWords(sale.totalAmount.toInt())} Rupees Only',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: is58mm ? 6 : 10),
    ];
  }

  // Footer Section optimized for 58mm
  static List<pw.Widget> _buildFooter(ThermalSize thermalSize) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    
    return [
      // Thank you message
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.symmetric(vertical: is58mm ? 4 : 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              is58mm ? 'THANK YOU!' : 'THANK YOU FOR YOUR BUSINESS!',
              style: pw.TextStyle(
                fontSize: is58mm ? 8 : (isWide ? 10 : 9),
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if (isWide) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Visit us again for fresh flowers and plants',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      
      pw.SizedBox(height: is58mm ? 4 : 8),
      
      // Timestamp
      pw.Text(
        'Printed: ${DateFormat(is58mm ? 'dd/MM/yy HH:mm' : 'dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
        style: pw.TextStyle(fontSize: is58mm ? 5 : (isWide ? 7 : 6), color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
      
      pw.SizedBox(height: is58mm ? 6 : 10),
    ];
  }

  // Helper Methods
  static pw.Widget _buildInfoRow(String label, String value, ThermalSize thermalSize) {
    final bool isWide = thermalSize == ThermalSize.mm80;
    final bool is58mm = thermalSize == ThermalSize.mm58;
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: is58mm ? 40 : (isWide ? 70 : 50),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: is58mm ? 7 : (isWide ? 9 : 8),
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: is58mm ? 7 : (isWide ? 9 : 8),
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact total row helper
  static pw.Widget _buildCompactTotalRow(
    String label, 
    String value, 
    double fontSize, 
    {PdfColor? valueColor}
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          'Rs.$value',
          style: pw.TextStyle(
            fontSize: fontSize,
            color: valueColor ?? PdfColors.black,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Text truncation helper
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Simple number to words converter (for amounts)
  static String _convertToWords(int amount) {
    if (amount == 0) return "Zero";
    if (amount > 99999) return "Amount too large";
    
    final ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    final teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    
    String result = "";
    
    if (amount >= 1000) {
      int thousands = amount ~/ 1000;
      result += ones[thousands] + " Thousand ";
      amount %= 1000;
    }
    
    if (amount >= 100) {
      int hundreds = amount ~/ 100;
      result += ones[hundreds] + " Hundred ";
      amount %= 100;
    }
    
    if (amount >= 20) {
      int tensPlace = amount ~/ 10;
      result += tens[tensPlace] + " ";
      amount %= 10;
    } else if (amount >= 10) {
      result += teens[amount - 10] + " ";
      return result.trim();
    }
    
    if (amount > 0) {
      result += ones[amount];
    }
    
    return result.trim();
  }
}

// Enum for thermal printer sizes
enum ThermalSize {
  mm58,
  mm80,
}

// Usage function
Future<void> generateInvoicePdf(Sale sale) async {
  await PdfService.generateInvoice(
    sale,
    thermalSize: ThermalSize.mm58, // or ThermalSize.mm80
    includeHeader: true,
    includeFooter: true,
    includeGST: false, // Set to true if you need GST calculation
  );
}