import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../database/hive_database.dart';
import '../models/work_entry.dart';
import '../pdf/pdf_generator.dart';

class WorkProvider with ChangeNotifier {
  List<WorkEntry> _workEntries = [];
  bool _isLoading = false;

  List<WorkEntry> get workEntries => _workEntries;
  bool get isLoading => _isLoading;

  // Getters for analytics
  double get totalMonthlyHours {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _workEntries
        .where((entry) =>
            entry.date
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, entry) => sum + entry.workedHours);
  }

  int get totalProjects =>
      _workEntries.map((e) => e.projectName).toSet().length;

  List<String> get availableProjects {
    final projects = _workEntries.map((e) => e.projectName).toSet().toList();
    projects.sort();
    return projects;
  }

  int get todayEntries {
    final today = DateTime.now();
    return _workEntries
        .where((entry) =>
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day)
        .length;
  }

  Map<String, double> get projectHours {
    final map = <String, double>{};
    for (final entry in _workEntries) {
      map[entry.projectName] =
          (map[entry.projectName] ?? 0) + entry.workedHours;
    }
    return map;
  }

  Map<DateTime, double> get dailyHours {
    final map = <DateTime, double>{};
    for (final entry in _workEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      map[date] = (map[date] ?? 0) + entry.workedHours;
    }
    return map;
  }

  WorkProvider() {
    loadWorkEntries();
  }

  Future<void> loadWorkEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = HiveDatabase.workEntryBox;
      _workEntries = box.values.toList();
      _workEntries.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading work entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkEntry(WorkEntry entry) async {
    try {
      final box = HiveDatabase.workEntryBox;
      await box.put(entry.id, entry);
      _workEntries.insert(0, entry);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding work entry: $e');
      rethrow;
    }
  }

  Future<void> updateWorkEntry(WorkEntry entry) async {
    try {
      final box = HiveDatabase.workEntryBox;
      await box.put(entry.id, entry);
      final index = _workEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _workEntries[index] = entry;
        _workEntries.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating work entry: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkEntry(String id) async {
    try {
      final box = HiveDatabase.workEntryBox;
      await box.delete(id);
      _workEntries.removeWhere((entry) => entry.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting work entry: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final box = HiveDatabase.workEntryBox;
      await box.clear();
      _workEntries.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  List<WorkEntry> getEntriesForMonth(int year, int month) {
    return _workEntries
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .toList();
  }

  List<WorkEntry> getEntriesForRange(DateTime start, DateTime end) {
    // normalization to include the whole end day
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return _workEntries.where((entry) {
      return entry.date.isAfter(normalizedStart.subtract(const Duration(seconds: 1))) &&
             entry.date.isBefore(normalizedEnd.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<WorkEntry> searchEntries(String query) {
    if (query.isEmpty) return _workEntries;

    return _workEntries
        .where((entry) =>
            entry.projectName.toLowerCase().contains(query.toLowerCase()) ||
            entry.details.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<String> exportData() async {
    try {
      // Get current month entries for export
      final now = DateTime.now();
      final entries = getEntriesForMonth(now.year, now.month);

      if (entries.isEmpty) {
        throw Exception('No work entries found for the current month');
      }

      // Generate PDF using existing PDF generator
      final pdf = await PDFGenerator.generateRangePDF(
        entries: entries,
        title: 'Monthly Work Report',
        subtitle: '${getMonthName(now.month)} ${now.year}',
      );

      final bytes = await pdf.save();

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'worklog_export_${now.year}_${now.month}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Verify file was created and has content
      if (!await file.exists()) {
        throw Exception('PDF file was not created');
      }

      final fileLength = await file.length();
      if (fileLength == 0) {
        throw Exception('PDF file is empty');
      }

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('Export error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to export data: $e');
    }
  }

  Future<String> createBackup() async {
    try {
      final entries = _workEntries.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(entries);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'officebuddy_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      debugPrint('Backup error: $e');
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> restoreBackup(String jsonContent) async {
    try {
      final dynamic decodedData = jsonDecode(jsonContent);
      List<dynamic> jsonData;
      
      if (decodedData is List) {
        jsonData = decodedData;
      } else if (decodedData is Map && decodedData.containsKey('entries')) {
        jsonData = decodedData['entries'];
      } else {
        throw Exception('Invalid backup format');
      }

      final box = HiveDatabase.workEntryBox;
      
      for (var item in jsonData) {
        try {
          final entry = WorkEntry.fromJson(Map<String, dynamic>.from(item));
          await box.put(entry.id, entry);
        } catch (e) {
          debugPrint('Skipping invalid entry: $item, error: $e');
        }
      }
      
      await loadWorkEntries();
    } catch (e) {
      debugPrint('Restore error: $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  Future<int> importData() async {
    try {
      // For now, we'll throw an exception indicating this needs file picker
      throw Exception(
          'Import functionality requires file picker - not yet implemented');
    } catch (e) {
      debugPrint('Import error: $e');
      throw Exception('Failed to import data: $e');
    }
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  List<WorkEntry> getEntriesForProject(String projectName) {
    return _workEntries
        .where((entry) => entry.projectName == projectName)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
