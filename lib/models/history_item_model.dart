import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryItemModel {
  final String id;
  final String fridgeId;
  final String name;
  final String category;
  final String imageUrl;
  final String? fileId; // ImageKit file ID for deletion
  final DateTime expiryDate;
  final DateTime reminderDate;
  final String status; // "used"
  final String createdBy;
  final DateTime createdAt;
  final String compartment;
  final DateTime usedAt; // Time of use
  HistoryItemModel({
    required this.id,
    required this.fridgeId,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.fileId,
    required this.expiryDate,
    required this.reminderDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.compartment,
    required this.usedAt,
  });

  factory HistoryItemModel.fromMap(Map<String, dynamic> map, String id) {
    return HistoryItemModel(
      id: id,
      fridgeId: map['fridgeId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      fileId: map['fileId'],
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      reminderDate: (map['reminderDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'used',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      compartment: map['compartment'] ?? 'chiller',
      usedAt: (map['usedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fridgeId': fridgeId,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'fileId': fileId,
      'expiryDate': expiryDate,
      'reminderDate': reminderDate,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'compartment': compartment,
      'usedAt': usedAt,
    };
  }

  HistoryItemModel copyWith({
    String? fridgeId,
    String? name,
    String? category,
    String? imageUrl,
    String? fileId,
    DateTime? expiryDate,
    DateTime? reminderDate,
    String? status,
    String? createdBy,
    String? compartment,
    DateTime? usedAt,
  }) {
    return HistoryItemModel(
      id: id,
      fridgeId: fridgeId ?? this.fridgeId,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      fileId: fileId ?? this.fileId,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderDate: reminderDate ?? this.reminderDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      compartment: compartment ?? this.compartment,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}
