import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/boxes.dart';
import '../edit_invoice_screen.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});
  
  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _dailyAnchor = DateTime.now();
  DateTime _monthlyAnchor = DateTime.now();
  DateTime _yearlyAnchor = DateTime.now();
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _isAdmin = context.read<AuthService>().isAdmin;
    if (!_isAdmin) {
      _tab.index = 0;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  DateTime get _currentAnchor {
    switch (_tab.index) {
      case 0: return _dailyAnchor;
      case 1: return _monthlyAnchor;
      case 2: return _yearlyAnchor;
      default: return _dailyAnchor;
    }
  }

  void _updateCurrentAnchor(DateTime newValue) {
    switch (_tab.index) {
      case 0: 
        setState(() => _dailyAnchor = newValue);
        break;
      case 1: 
        setState(() => _monthlyAnchor = newValue);
        break;
      case 2: 
        setState(() => _yearlyAnchor = newValue);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sales = Hive.box<Sale>(Boxes.sales).values.toList();
    final expenses = Hive.box<Expense>(Boxes.expenses).values.toList();
    
    return Column(
      children: [
        // Professional Header with Date Navigation
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              )
            ],
          ),
          child: Column(
            children: [
              // Date Navigation Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        tooltip: 'Previous',
                        icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
                        onPressed: () => _updateCurrentAnchor(_previous(_currentAnchor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: TextButton.icon(
                          onPressed: _pickPeriod,
                          icon: Icon(Icons.calendar_today, 
                            color: theme.colorScheme.primary, size: 20),
                          label: Text(
                            _tab.index == 0
                                ? DateFormat('dd MMM yyyy').format(_dailyAnchor)
                                : _tab.index == 1
                                    ? DateFormat('MMMM yyyy').format(_monthlyAnchor)
                                    : DateFormat('yyyy').format(_yearlyAnchor),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        tooltip: 'Next',
                        icon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                        onPressed: () => _updateCurrentAnchor(_next(_currentAnchor)),
                      ),
                    ),
                  ],
                ),
              ),
              // Professional Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  labelColor: Colors.white, // Make selected tab text white for contrast
                  unselectedLabelColor: theme.colorScheme.onSurface, // Make unselected tab text visible
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: _isAdmin ? const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'Yearly'),
                  ] : const [
                    Tab(text: 'Daily'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: _isAdmin ? [
              _buildDaily(sales, expenses),
              _buildMonthly(sales, expenses),
              _buildYearly(sales, expenses),
            ] : [
              _buildDaily(sales, expenses),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(String title, String value, IconData icon, {bool isNet = false}) {
    final theme = Theme.of(context);
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
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNet 
                    ? (value.contains('-') ? Colors.red.shade50 : Colors.green.shade50)
                    : theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isNet 
                    ? (value.contains('-') ? Colors.red.shade700 : Colors.green.shade700)
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isNet && value.contains('-') 
                          ? Colors.red.shade700 
                          : theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data will appear here once transactions are recorded',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaily(List<Sale> sales, List<Expense> expenses) {
    final cur = NumberFormat.simpleCurrency(locale: 'en_IN');
    final daySales = sales.where((s) => _isSameDay(s.date, _dailyAnchor)).toList();
    final dayExpenses = expenses.where((e) => _isSameDay(e.date, _dailyAnchor)).toList();
    
    final revenue = daySales.fold(0.0, (a, s) => a + s.totalAmount);
    final grossProfit = daySales.fold(0.0, (a, s) => a + s.profit);
    final totalExpenses = dayExpenses.fold(0.0, (a, e) => a + e.amount);
    final netProfit = grossProfit - totalExpenses;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Daily Overview',
            subtitle: DateFormat('EEEE, MMMM d, yyyy').format(_dailyAnchor),
          ),
          
          _card('Total Revenue', cur.format(revenue), Icons.trending_up),
          _card('Gross Profit', cur.format(grossProfit), Icons.account_balance_wallet),
          _card('Total Expenses', cur.format(totalExpenses), Icons.money_off_outlined),
          _card('Net Profit', cur.format(netProfit), Icons.analytics, isNet: true),
          _card('Total Invoices', '${daySales.length}', Icons.receipt_long_outlined),
          
          if (daySales.isNotEmpty) ...[
            _sectionHeader('Today\'s Transactions'),
            ...daySales.map((sale) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                    offset: const Offset(0, 1),
                    blurRadius: 8,
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(
                  'Invoice #${sale.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  DateFormat('hh:mm a').format(sale.date),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                trailing: Text(
                  cur.format(sale.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditInvoiceScreen(sale: sale, isViewOnly: true),
                    ),
                  );
                },
              ),
            )).toList(),
          ],
          
          if (daySales.isEmpty && dayExpenses.isEmpty) _empty(),
        ],
      ),
    );
  }

  Widget _buildMonthly(List<Sale> sales, List<Expense> expenses) {
    final cur = NumberFormat.simpleCurrency(locale: 'en_IN');
    final m = DateTime(_monthlyAnchor.year, _monthlyAnchor.month);
    final mSales = sales.where((s) => _isSameMonth(s.date, m)).toList();
    final mExpenses = expenses.where((e) => _isSameMonth(e.date, m)).toList();
    
    final revenue = mSales.fold(0.0, (a, s) => a + s.totalAmount);
    final grossProfit = mSales.fold(0.0, (a, s) => a + s.profit);
    final totalExpenses = mExpenses.fold(0.0, (a, e) => a + e.amount);
    final netProfit = grossProfit - totalExpenses;
    
    final productStats = <String, Map<String, dynamic>>{};
    for (final sale in mSales) {
      for (final item in sale.items) {
        final productName = item.productName;
        if (productStats.containsKey(productName)) {
          productStats[productName]!['totalQuantity'] = 
              (productStats[productName]!['totalQuantity'] as double) + item.quantity;
          productStats[productName]!['totalRevenue'] = 
              (productStats[productName]!['totalRevenue'] as double) + item.totalAmount;
          productStats[productName]!['totalProfit'] = 
              (productStats[productName]!['totalProfit'] as double) + item.profit;
        } else {
          productStats[productName] = {
            'productName': productName,
            'totalQuantity': item.quantity,
            'totalRevenue': item.totalAmount,
            'totalProfit': item.profit,
          };
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Monthly Overview',
            subtitle: DateFormat('MMMM yyyy').format(_monthlyAnchor),
          ),
          
          _card('Total Revenue', cur.format(revenue), Icons.trending_up),
          _card('Gross Profit', cur.format(grossProfit), Icons.account_balance_wallet),
          _card('Total Expenses', cur.format(totalExpenses), Icons.money_off_outlined),
          _card('Net Profit', cur.format(netProfit), Icons.analytics, isNet: true),
          _card('Total Invoices', '${mSales.length}', Icons.receipt_long_outlined),

          if (productStats.isNotEmpty) ...[
            _sectionHeader('Product Performance'),
            ...productStats.entries.map((entry) {
              final stats = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stats['productName'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              'Quantity Sold',
                              '${(stats['totalQuantity'] ?? 0.0).toStringAsFixed(1)}',
                              Icons.shopping_cart_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              'Revenue',
                              cur.format(stats['totalRevenue'] ?? 0.0),
                              Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMetric(
                        'Profit',
                        cur.format(stats['totalProfit'] ?? 0.0),
                        Icons.trending_up,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],

          if (mSales.isEmpty && mExpenses.isEmpty) _empty(),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearly(List<Sale> sales, List<Expense> expenses) {
    final cur = NumberFormat.simpleCurrency(locale: 'en_IN');
    final y = _yearlyAnchor.year;
    final ySales = sales.where((s) => s.date.year == y).toList();
    final yExpenses = expenses.where((e) => e.date.year == y).toList();
    
    final revenue = ySales.fold(0.0, (a, s) => a + s.totalAmount);
    final grossProfit = ySales.fold(0.0, (a, s) => a + s.profit);
    final totalExpenses = yExpenses.fold(0.0, (a, e) => a + e.amount);
    final netProfit = grossProfit - totalExpenses;
    
    final productStats = <String, Map<String, dynamic>>{};
    for (final sale in ySales) {
      for (final item in sale.items) {
        final productName = item.productName;
        if (productStats.containsKey(productName)) {
          productStats[productName]!['totalQuantity'] = 
              (productStats[productName]!['totalQuantity'] as double) + item.quantity;
          productStats[productName]!['totalRevenue'] = 
              (productStats[productName]!['totalRevenue'] as double) + item.totalAmount;
          productStats[productName]!['totalProfit'] = 
              (productStats[productName]!['totalProfit'] as double) + item.profit;
        } else {
          productStats[productName] = {
            'productName': productName,
            'totalQuantity': item.quantity,
            'totalRevenue': item.totalAmount,
            'totalProfit': item.profit,
          };
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Yearly Overview',
            subtitle: '${_yearlyAnchor.year}',
          ),
          
          _card('Total Revenue', cur.format(revenue), Icons.trending_up),
          _card('Gross Profit', cur.format(grossProfit), Icons.account_balance_wallet),
          _card('Total Expenses', cur.format(totalExpenses), Icons.money_off_outlined),
          _card('Net Profit', cur.format(netProfit), Icons.analytics, isNet: true),
          _card('Total Invoices', '${ySales.length}', Icons.receipt_long_outlined),

          if (productStats.isNotEmpty) ...[
            _sectionHeader('Annual Product Performance'),
            ...productStats.entries.map((entry) {
              final stats = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stats['productName'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              'Quantity Sold',
                              '${(stats['totalQuantity'] ?? 0.0).toStringAsFixed(1)}',
                              Icons.shopping_cart_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              'Revenue',
                              cur.format(stats['totalRevenue'] ?? 0.0),
                              Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMetric(
                        'Profit',
                        cur.format(stats['totalProfit'] ?? 0.0),
                        Icons.trending_up,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],

          if (ySales.isEmpty && yExpenses.isEmpty) _empty(),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => 
      a.year == b.year && a.month == b.month && a.day == b.day;
      
  bool _isSameMonth(DateTime a, DateTime m) => 
      a.year == m.year && a.month == m.month;

  DateTime _previous(DateTime d) {
    if (_tab.index == 0) {
      return d.subtract(const Duration(days: 1));
    } else if (_tab.index == 1) {
      final y = d.year;
      final m = d.month == 1 ? 12 : d.month - 1;
      final ny = d.month == 1 ? y - 1 : y;
      return DateTime(ny, m, 1);
    } else {
      return DateTime(d.year - 1, 1, 1);
    }
  }

  DateTime _next(DateTime d) {
    if (_tab.index == 0) {
      return d.add(const Duration(days: 1));
    } else if (_tab.index == 1) {
      final y = d.year;
      final m = d.month == 12 ? 1 : d.month + 1;
      final ny = d.month == 12 ? y + 1 : y;
      return DateTime(ny, m, 1);
    } else {
      return DateTime(d.year + 1, 1, 1);
    }
  }

  Future<void> _pickPeriod() async {
    if (_tab.index == 0) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _dailyAnchor,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) _updateCurrentAnchor(picked);
    } else if (_tab.index == 1 && _isAdmin) {
      final picked = await _showMonthYearPicker(
        context: context,
        initialYear: _monthlyAnchor.year,
        initialMonth: _monthlyAnchor.month,
      );
      if (picked != null) _updateCurrentAnchor(picked);
    } else if (_tab.index == 2 && _isAdmin) {
      final selected = await showDialog<int>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Select year'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: DateTime(_yearlyAnchor.year),
                selectedDate: DateTime(_yearlyAnchor.year),
                onChanged: (date) => Navigator.of(ctx).pop(date.year),
              ),
            ),
          );
        },
      );
      if (selected != null) _updateCurrentAnchor(DateTime(selected, 1, 1));
    }
  }

  Future<DateTime?> _showMonthYearPicker({
    required BuildContext context,
    required int initialYear,
    required int initialMonth,
  }) async {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        int selectedYear = initialYear;
        int selectedMonth = initialMonth;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select month and year'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: YearPicker(
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: DateTime(selectedYear),
                        selectedDate: DateTime(selectedYear),
                        onChanged: (date) {
                          setStateDialog(() {
                            selectedYear = date.year;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        final m = i + 1;
                        final isSelected = m == selectedMonth;
                        return ChoiceChip(
                          label: Text(DateFormat('MMM').format(DateTime(2000, m, 1))),
                          selected: isSelected,
                          onSelected: (_) {
                            setStateDialog(() {
                              selectedMonth = m;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(DateTime(selectedYear, selectedMonth, 1));
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
