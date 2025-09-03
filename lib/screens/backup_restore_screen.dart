import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import '../services/drive_backup_service.dart';
import '../services/drive_sync_service.dart';
import '../services/boxes.dart';
import '../models/models.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  List<DriveFileEntry> _backupFiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshBackups();
  }

  Future<void> _refreshBackups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (DriveBackupService.instance.currentUser == null) {
        setState(() {
          _backupFiles = [];
          _isLoading = false;
        });
        return;
      }

      final files = await DriveBackupService.instance.listBackups();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'backup_$timestamp.json';

      // Collect data from all boxes
      final data = {
        'products': Hive.box<Product>(Boxes.products).values.map((e) => e.toJson()).toList(),
        'sales': Hive.box<Sale>(Boxes.sales).values.map((e) => e.toJson()).toList(),
        'expenses': Hive.box<Expense>(Boxes.expenses).values.map((e) => e.toJson()).toList(),
        'employees': Hive.box<Employee>(Boxes.employees).values.map((e) => e.toJson()).toList(),
      };

      await DriveBackupService.instance.uploadJson(filename: filename, json: data);
      await _refreshBackups();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Backup created successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to create backup: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(DriveFileEntry file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text('Restore data from ${file.name}? This will replace all current data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await DriveBackupService.instance.downloadJson(file.id);

      // Clear existing data
      await Hive.box<Product>(Boxes.products).clear();
      await Hive.box<Sale>(Boxes.sales).clear();
      await Hive.box<Expense>(Boxes.expenses).clear();
      await Hive.box<Employee>(Boxes.employees).clear();

      // Restore data
      if (data['products'] != null) {
        await Hive.box<Product>(Boxes.products).addAll(
          (data['products'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)),
        );
      }
      if (data['sales'] != null) {
        await Hive.box<Sale>(Boxes.sales).addAll(
          (data['sales'] as List).map((e) => Sale.fromJson(e as Map<String, dynamic>)),
        );
      }
      if (data['expenses'] != null) {
        await Hive.box<Expense>(Boxes.expenses).addAll(
          (data['expenses'] as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)),
        );
      }
      if (data['employees'] != null) {
        await Hive.box<Employee>(Boxes.employees).addAll(
          (data['employees'] as List).map((e) => Employee.fromJson(e as Map<String, dynamic>)),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Data restored successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to restore backup: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = DriveBackupService.instance.currentUser;
    final isConnected = user != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Backup & Restore'),
        elevation: 0,
        actions: [
          if (isConnected) ...[
            ValueListenableBuilder(
              valueListenable: Hive.box('settings').listenable(),
              builder: (context, box, child) {
                final autoSync = DriveSyncService.instance.isAutoSyncEnabled;
                return IconButton(
                  onPressed: () async {
                    if (autoSync) {
                      await DriveSyncService.instance.disableAutoSync();
                    } else {
                      await DriveSyncService.instance.enableAutoSync();
                    }
                    setState(() {}); // Refresh UI
                  },
                  icon: Icon(
                    autoSync ? Icons.sync : Icons.sync_disabled,
                    color: autoSync ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                  tooltip: autoSync ? 'Auto sync enabled' : 'Auto sync disabled',
                );
              },
            ),
            IconButton(
              onPressed: _isLoading ? null : _refreshBackups,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh backups',
            ),
          ],
        ],
      ),
      floatingActionButton: isConnected
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _createBackup,
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isConnected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Not connected to Google Drive',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect to enable cloud backup and restore',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          try {
                            await DriveBackupService.instance.signIn();
                            await _refreshBackups();
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Connect to Google Drive'),
                      ),
                    ],
                  ),
                )
              : _backupFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.backup_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No backups yet',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first backup using the button below',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 80,
                      ),
                      itemCount: _backupFiles.length,
                      itemBuilder: (context, index) {
                        final file = _backupFiles[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.backup,
                                color: theme.primaryColor,
                              ),
                            ),
                            title: Text(file.name),
                            subtitle: file.modifiedTime != null
                                ? Text(
                                    'Modified: ${file.modifiedTime!.toLocal().toString().split('.').first}',
                                  )
                                : null,
                            trailing: IconButton(
                              onPressed: () => _restoreBackup(file),
                              icon: const Icon(Icons.restore),
                              tooltip: 'Restore this backup',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
