import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:floralbill/models/sale.dart';
import 'package:floralbill/models/product.dart';
import 'package:floralbill/services/boxes.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class ThermalPrinterService {
  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      print('Error getting bonded devices: $e');
      return [];
    }
  }

  Future<void> connect(BluetoothInfo device) async {
    try {
      await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      print('Error disconnecting printer: $e');
    }
  }

  Future<bool> get isConnected async {
    try {
      final result = await PrintBluetoothThermal.connectionStatus;
      return result;
    } catch (e) {
      print('Error checking printer connection: $e');
      return false;
    }
  }

  Future<void> printInvoice(Sale sale) async {
    try {
      // Try to print to any available paired device
      await _attemptPrintToPairedDevice(sale);
    } catch (e) {
      print('Printing error: $e');
      // Don't rethrow - just log the error and continue
    }
  }

  Future<void> _attemptPrintToPairedDevice(Sale sale) async {
    try {
      // Get paired devices
      final devices = await getBondedDevices();
      
      if (devices.isEmpty) {
        print('No paired thermal printers found');
        return;
      }

      // Try to connect to the first available device if not already connected
      bool connected = await isConnected;
      if (!connected && devices.isNotEmpty) {
        try {
          await connect(devices.first);
          connected = await isConnected;
        } catch (e) {
          print('Failed to connect to paired device: $e');
        }
      }

      if (!connected) {
        print('Could not establish connection to thermal printer');
        return;
      }

      // Print using ESC/POS commands with logo
      List<int> ticket = await _generateTicketWithLogo(sale);
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      print("Print result: $result");
    } catch (e) {
      print('Error during printing: $e');
      rethrow;
    }
  }

  Future<List<int>> _generateTicketWithLogo(Sale sale) async {
  List<int> bytes = [];

  // Using default profile for 58mm paper
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm58, profile);

  bytes += generator.reset();

  // Currency symbol - fallback to Rs. if printer doesn't support ₹
  const String currencySymbol = '₹'; // Can change to 'Rs.' if needed

  // Replace logo with bold, bigger "Royal Garden" heading
  bytes += generator.text(
    'Royal Garden',
    styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    linesAfter: 1,
  );

  // Business contact info - centered
    bytes += generator.text('FourLane Byepass,Mangattukavala',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Thodupuzha, 685585',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('9562291843, 9446932750',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('INVOICE',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('');



    // Invoice details
    bytes += generator.text('ID: ${sale.id}');
    bytes += generator.text('Date: ${DateFormat('dd/MM/yy HH:mm').format(sale.date)}');
    
    if (sale.customerName.isNotEmpty) {
      bytes += generator.text('Customer: ${sale.customerName}');
    }
    if (sale.customerPhone.isNotEmpty) {
      bytes += generator.text('Phone: ${sale.customerPhone}');
    }
    bytes += generator.text('Payment: ${sale.payment.name.toUpperCase()}');
    bytes += generator.text('');

    // Items header - adjusted for 58mm paper (32 characters width)
    bytes += generator.text('================================');
    bytes += generator.text('ITEM          QTY        AMT');
    bytes += generator.text('================================');

    // Print items with better formatting for 58mm paper
    for (var item in sale.items) {
      final product = Hive.box<Product>(Boxes.products).get(item.productId);
      final productName = product?.name ?? 'Unknown Product';
      final qty = item.qty.toStringAsFixed(product?.unit == UnitType.kg ? 1 : 0);
      final unitLabel = item.unitLabel.isNotEmpty ? item.unitLabel : (product?.unit.name ?? '');

      String qtyStr = '$qty ${unitLabel.isNotEmpty ? unitLabel : ''}'.trim();
      String amtStr = '$currencySymbol${item.subtotal.toStringAsFixed(2)}';
      
      // For 58mm paper, we have about 32 characters width
      // Product name: 13 chars, Qty: 9 chars, Amount: 10 chars
      if (productName.length <= 13) {
        // Short name - fits on one line
        String itemLine = productName.padRight(14) + qtyStr.padRight(9) + amtStr;
        bytes += generator.text(itemLine);
      } else {
        // Long name - split intelligently at word boundaries
        List<String> words = productName.split(' ');
        String firstLine = '';
        String secondLine = '';
        
        // Build first line with as many words as possible (max 13 chars)
        for (String word in words) {
          if ((firstLine + word).length <= 13) {
            firstLine += (firstLine.isEmpty ? '' : ' ') + word;
          } else {
            // Add remaining words to second line
            secondLine += (secondLine.isEmpty ? '' : ' ') + word;
          }
        }
        
        // If second line is empty, use simple truncation
        if (secondLine.isEmpty) {
          firstLine = productName.substring(0, 13);
          secondLine = productName.substring(13);
        }
        
        // Print first line
        bytes += generator.text(firstLine);
        
        // Print second line with qty and amount
        String qtyAmtLine = secondLine.padRight(14) + qtyStr.padRight(9) + amtStr;
        bytes += generator.text(qtyAmtLine);
      }
    }

    // Totals - better alignment for 58mm paper
    bytes += generator.text('================================');
    
    String subtotalAmount = '$currencySymbol${sale.items.fold(0.0, (a, b) => a + b.subtotal).toStringAsFixed(2)}';
    String subtotalLine = 'Subtotal:' + subtotalAmount.padLeft(24);
    bytes += generator.text(subtotalLine);
    
    if (sale.discount > 0) {
      String discountAmount = '-$currencySymbol${sale.discount.toStringAsFixed(2)}';
      String discountLine = 'Discount:' + discountAmount.padLeft(24);
      bytes += generator.text(discountLine);
    }
    
    bytes += generator.text('================================');
    
    String totalAmount = '$currencySymbol${sale.totalAmount.toStringAsFixed(2)}';
    String totalLine = 'TOTAL:' + totalAmount.padLeft(26);
    bytes += generator.text(totalLine, styles: PosStyles(bold: true));
    bytes += generator.text('');

    // Footer
    bytes += generator.text('THANK YOU!', 
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('');
    // bytes += generator.text('      Royal Garden', 
    //     styles: PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(3);
    
    return bytes;
  }
}
