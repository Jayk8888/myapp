import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Confession {
  final String id;
  final String text;
  final int likes;
  final int dislikes;
  final String authorId;
  final Color color;
  final DateTime? createdAt;

  const Confession({
    required this.id,
    required this.text,
    required this.likes,
    required this.dislikes,
    required this.authorId,
    required this.color,
    this.createdAt,
  });

  Confession copyWith({String? text}) {
    return Confession(
      id: id,
      text: text ?? this.text,
      likes: likes,
      dislikes: dislikes,
      authorId: authorId,
      color: color,
      createdAt: createdAt,
    );
  }

  factory Confession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return Confession(
      id: doc.id,
      text: data['text'] as String? ?? '',
      likes: _asInt(data['likes']),
      dislikes: _asInt(data['dislikes']),
      authorId: data['authorId'] as String? ?? '',
      color: AppColors.cardColorForId(doc.id),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
