import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../models/employee.dart';
import '../../../models/expense.dart';
import '../../../services/boxes.dart';

class MonthlySalaryScreen extends StatelessWidget {
  const MonthlySalaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(locale: 'en_IN');
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Monthly Salary Payments'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Employee>(Boxes.employees).listenable(),
        builder: (context, Box<Employee> empBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Expense>(Boxes.expenses).listenable(),
            builder: (context, Box<Expense> expBox, __) {
              final monthlyEmployees = empBox.values.where((e) => e.type == 'monthly').toList()
                ..sort((a, b) => a.name.compareTo(b.name));
                
              if (monthlyEmployees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Monthly Salary Employees',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add monthly salary employees to manage their payments',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);
              final monthEnd = DateTime(now.year, now.month + 1, 1);
              final monthPayments = expBox.values.where((ex) =>
                ex.category == 'Salary-Monthly' && 
                !ex.date.isBefore(monthStart) && 
                ex.date.isBefore(monthEnd)
              ).toList();

              return Column(
                children: [
                  // Summary Header Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                          offset: const Offset(0, 2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.payments_outlined,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Salary Overview',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMMM yyyy').format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryItem(
                                  'Total Employees',
                                  '${monthlyEmployees.length}',
                                  Icons.people_outlined,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryItem(
                                  'Paid This Month',
                                  '${monthPayments.length}',
                                  Icons.check_circle_outlined,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Employee List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: monthlyEmployees.length,
                      itemBuilder: (context, index) {
                        final e = monthlyEmployees[index];
                        final controller = TextEditingController(text: e.wage.toStringAsFixed(2));
                        final isPaidThisMonth = monthPayments.any((ex) => ex.description.contains(e.name));
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.onSurface.withOpacity(0.08),
                                offset: const Offset(0, 2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Employee Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isPaidThisMonth ? Colors.green.shade50 : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: isPaidThisMonth ? Colors.green.shade600 : Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Monthly Salary Employee',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPaidThisMonth ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPaidThisMonth ? Icons.check_circle : Icons.pending,
                                            size: 16,
                                            color: isPaidThisMonth ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPaidThisMonth ? 'Paid' : 'Pending',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isPaidThisMonth ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Payment Section
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.outline.withOpacity(0.2),
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: controller,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          enabled: !isPaidThisMonth,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.currency_rupee_outlined,
                                              color: isPaidThisMonth 
                                                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                                                  : Colors.green.shade600,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            hintText: 'Monthly salary amount',
                                            hintStyle: TextStyle(
                                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isPaidThisMonth 
                                                ? theme.colorScheme.onSurface.withOpacity(0.4)
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton.icon(
                                        onPressed: isPaidThisMonth ? null : () => _processPayment(
                                          context, 
                                          e, 
                                          controller, 
                                          expBox, 
                                          currency
                                        ),
                                        icon: Icon(isPaidThisMonth ? Icons.check : Icons.payment_outlined),
                                        label: Text(isPaidThisMonth ? 'Paid' : 'Pay Salary'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPaidThisMonth 
                                              ? Colors.grey.shade400 
                                              : Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey.shade300,
                                          disabledForegroundColor: Colors.grey.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    Employee employee,
    TextEditingController controller,
    Box<Expense> expBox,
    NumberFormat currency,
  ) async {
    final amount = double.tryParse(controller.text.trim());
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid salary amount'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payments, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Salary Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay monthly salary to ${employee.name}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    currency.format(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      final expense = Expense(
        id: const Uuid().v4(),
        date: DateTime.now(),
        category: 'Salary-Monthly',
        amount: amount,
        description: 'Monthly salary paid to ${employee.name}',
      );
      
      await expBox.put(expense.id, expense);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully paid ${currency.format(amount)} to ${employee.name}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
