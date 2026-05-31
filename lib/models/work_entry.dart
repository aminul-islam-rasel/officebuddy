import 'package:hive/hive.dart';

part 'work_entry.g.dart';

@HiveType(typeId: 0)
class WorkEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String projectName;

  @HiveField(3)
  final double workedHours;

  @HiveField(4)
  final String details;

  @HiveField(5)
  final DateTime createdAt;

  WorkEntry({
    required this.id,
    required this.date,
    required this.projectName,
    required this.workedHours,
    required this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'projectName': projectName,
      'workedHours': workedHours,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      projectName: json['projectName'],
      workedHours: (json['workedHours'] as num).toDouble(),
      details: json['details'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  WorkEntry copyWith({
    String? id,
    DateTime? date,
    String? projectName,
    double? workedHours,
    String? details,
    DateTime? createdAt,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      projectName: projectName ?? this.projectName,
      workedHours: workedHours ?? this.workedHours,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WorkEntry(id: $id, date: $date, projectName: $projectName, workedHours: $workedHours, details: $details, createdAt: $createdAt)';
  }
}
