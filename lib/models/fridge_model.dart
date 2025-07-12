import 'package:cloud_firestore/cloud_firestore.dart';

class FridgeModel {
  final String id;
  final String name;
  final String type; // "chiller", "freezer", or "both"
  final String ownerId;
  final List<String>
  contributors; // List of user UIDs who can access this fridge
  final DateTime createdAt;

  FridgeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.contributors,
    required this.createdAt,
  });

  factory FridgeModel.fromMap(Map<String, dynamic> map, String id) {
    return FridgeModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'both',
      ownerId: map['ownerId'] ?? '',
      contributors: List<String>.from(map['contributors'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'ownerId': ownerId,
      'contributors': contributors,
      'createdAt': createdAt,
    };
  }

  FridgeModel copyWith({
    String? name,
    String? type,
    String? ownerId,
    List<String>? contributors,
  }) {
    return FridgeModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      contributors: contributors ?? this.contributors,
      createdAt: createdAt,
    );
  }
}
