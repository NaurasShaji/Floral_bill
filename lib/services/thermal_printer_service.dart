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

    // Items header
    bytes += generator.text('================================');
    bytes += generator.text('ITEM               QTY     AMT');
    bytes += generator.text('================================');

    // Print items
    for (var item in sale.items) {
      final product = Hive.box<Product>(Boxes.products).get(item.productId);
      final productName = product?.name ?? 'Unknown Product';
      final qty = item.qty.toStringAsFixed(product?.unit == UnitType.kg ? 1 : 0);
      final unitLabel = item.unitLabel.isNotEmpty ? item.unitLabel : (product?.unit.name ?? '');

      // Format product name to fit 58mm width (32 chars)
      String formattedName = productName.length > 18 ? '${productName.substring(0, 18)}...' : productName;
      bytes += generator.text(formattedName);
      
      // Format quantity, rate and amount in one line
      String qtyStr = '$qty ${unitLabel.isNotEmpty ? unitLabel : ''}'.trim();
      String rateStr = 'Rs.${item.sellingPrice.toStringAsFixed(2)}';
      String amtStr = 'Rs.${item.subtotal.toStringAsFixed(2)}';
      
      // Create properly spaced line for 32 char width
      String itemLine = qtyStr.padRight(8) + rateStr.padLeft(10) + amtStr.padLeft(14);
      if (itemLine.length > 32) {
        itemLine = qtyStr.padRight(6) + rateStr.padLeft(8) + amtStr.padLeft(12);
      }
      bytes += generator.text(itemLine);
      bytes += generator.text('');
    }

    // Totals
    bytes += generator.text('================================');
    
    String subtotalAmount = 'Rs.${sale.items.fold(0.0, (a, b) => a + b.subtotal).toStringAsFixed(2)}';
    String subtotalLine = 'Subtotal:'.padRight(20) + subtotalAmount.padLeft(12);
    bytes += generator.text(subtotalLine);
    
    if (sale.discount > 0) {
      String discountAmount = '-Rs.${sale.discount.toStringAsFixed(2)}';
      String discountLine = 'Discount:'.padRight(20) + discountAmount.padLeft(12);
      bytes += generator.text(discountLine);
    }
    
    bytes += generator.text('================================');
    
    String totalAmount = 'Rs.${sale.totalAmount.toStringAsFixed(2)}';
    String totalLine = 'TOTAL:'.padRight(20) + totalAmount.padLeft(12);
    bytes += generator.text(totalLine, styles: PosStyles(bold: true));
    bytes += generator.text('');

    // Footer
    bytes += generator.text('THANK YOU!', 
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Visit again for fresh flowers and plants', 
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('');
    // bytes += generator.text('      Royal Garden', 
    //     styles: PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(3);
    
    return bytes;
  }
}
