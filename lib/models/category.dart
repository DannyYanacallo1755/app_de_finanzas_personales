import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<Category> defaults = [
    Category(id: 'food', name: 'Comida', icon: Icons.restaurant_rounded, color: Color(0xFFFF6B6B)),
    Category(id: 'home', name: 'Hogar', icon: Icons.home_rounded, color: Color(0xFF4ECDC4)),
    Category(id: 'transport', name: 'Transporte', icon: Icons.directions_car_rounded, color: Color(0xFF45B7D1)),
    Category(id: 'leisure', name: 'Ocio', icon: Icons.sports_esports_rounded, color: Color(0xFF96CEB4)),
    Category(id: 'health', name: 'Salud', icon: Icons.favorite_rounded, color: Color(0xFFFF8B94)),
    Category(id: 'clothing', name: 'Ropa', icon: Icons.shopping_bag_rounded, color: Color(0xFFA8E6CF)),
    Category(id: 'education', name: 'Educación', icon: Icons.school_rounded, color: Color(0xFFFFD93D)),
    Category(id: 'services', name: 'Servicios', icon: Icons.receipt_long_rounded, color: Color(0xFF6C5CE7)),
    Category(id: 'shopping', name: 'Compras', icon: Icons.shopping_cart_rounded, color: Color(0xFFFD79A8)),
    Category(id: 'other', name: 'Otros', icon: Icons.more_horiz_rounded, color: Color(0xFFB2BEC3)),
  ];

  static Category findById(String id) {
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => defaults.last,
    );
  }
}
