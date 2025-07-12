import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool isCompleted;
  final String category;
  final String userId;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isCompleted,
    required this.category,
    required this.userId,
    required this.createdAt,
  });

  // Create ShoppingItem from Firestore document
  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      isCompleted: data['isCompleted'] ?? false,
      category: data['category'] ?? 'Other',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'isCompleted': isCompleted,
      'category': category,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy ShoppingItem with modified properties
  ShoppingItem copyWith({
    String? name,
    int? quantity,
    bool? isCompleted,
    String? category,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      userId: userId,
      createdAt: createdAt,
    );
  }
}
