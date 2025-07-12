import 'package:cloud_firestore/cloud_firestore.dart';

class FridgeItemModel {
  final String id;
  final String fridgeId;
  final String name;
  final String category;
  final String imageUrl; // URL to the stored image
  final DateTime expiryDate; // Estimated expiry date (can't be changed)
  final DateTime reminderDate; // Custom reminder date (can be changed)
  final String status; // "fresh", "almost_expiry", "expired", "used"
  final String createdBy; // User ID who added this item
  final DateTime createdAt;
  final String compartment; // "freezer" or "chiller"

  FridgeItemModel({
    required this.id,
    required this.fridgeId,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.expiryDate,
    required this.reminderDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.compartment,
  });

  factory FridgeItemModel.fromMap(Map<String, dynamic> map, String id) {
    return FridgeItemModel(
      id: id,
      fridgeId: map['fridgeId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      reminderDate: (map['reminderDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'fresh',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      compartment: map['compartment'] ?? 'chiller',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fridgeId': fridgeId,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate,
      'reminderDate': reminderDate,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'compartment': compartment,
    };
  }

  FridgeItemModel copyWith({
    String? fridgeId,
    String? name,
    String? category,
    String? imageUrl,
    DateTime? expiryDate,
    DateTime? reminderDate,
    String? status,
    String? createdBy,
    String? compartment,
  }) {
    return FridgeItemModel(
      id: id,
      fridgeId: fridgeId ?? this.fridgeId,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderDate: reminderDate ?? this.reminderDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      compartment: compartment ?? this.compartment,
    );
  }
}
