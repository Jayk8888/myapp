import 'package:flutter/material.dart';

class Confession {
  final String id;
  final String text;
  final int likes;
  final int dislikes;
  final String authorId;
  final Color color;

  const Confession({
    required this.id,
    required this.text,
    required this.likes,
    required this.dislikes,
    required this.authorId,
    required this.color,
  });
}

