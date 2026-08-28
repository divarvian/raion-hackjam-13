import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color? fixedBackgroundColor;

  const AppAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 20,
    this.fixedBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: fixedBackgroundColor ?? _getBackgroundColor(name),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              _getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0].toUpperCase()}';
  }

  Color _getBackgroundColor(String fullName) {
    final bgColors = [
      const Color(0xFFE94545), // Red
      const Color(0xFF3276FF), // Blue
      const Color(0xFF1CB068), // Green
      const Color(0xFF5A5A5A), // Dark Grey
      const Color(0xFFF09A0A), // Orange
      const Color(0xFF9C27B0), // Purple
    ];
    int hash = 0;
    for (int i = 0; i < fullName.length; i++) {
      hash += fullName.codeUnitAt(i);
    }
    return bgColors[hash % bgColors.length];
  }
}
