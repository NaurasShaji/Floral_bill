import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/employee.dart';
import '../../../services/boxes.dart';

class EmployeesListScreen extends StatelessWidget {
  const EmployeesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees List')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Employee>(Boxes.employees).listenable(),
        builder: (context, Box<Employee> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }
          final employees = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final e = employees[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(e.name),
                subtitle: Text(e.type == 'daily' ? 'Daily Wage' : 'Monthly Salary'),
                trailing: Text('₹${e.wage.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}
