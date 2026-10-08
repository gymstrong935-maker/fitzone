import 'package:flutter/material.dart';

class CommunityPost {
  const CommunityPost({
    required this.user,
    required this.initials,
    required this.from,
    required this.to,
    required this.workout,
    required this.time,
    required this.likes,
    required this.liked,
  });

  final String user;
  final String initials;

  /// Colores del degradado del avatar.
  final Color from;
  final Color to;
  final String workout;
  final String time;
  final int likes;
  final bool liked;
}

const List<CommunityPost> kPosts = <CommunityPost>[
  CommunityPost(
    user: 'Carlos M.',
    initials: 'CM',
    from: Color(0xFF3B82F6), // azul
    to: Color(0xFF06B6D4), // cian
    workout: 'Press de Banca 100 kg × 5',
    time: 'Hace 2 horas',
    likes: 24,
    liked: false,
  ),
  CommunityPost(
    user: 'Ana S.',
    initials: 'AS',
    from: Color(0xFFEC4899), // rosa
    to: Color(0xFFA855F7), // morado
    workout: '¡Primera semana completa! 💪',
    time: 'Hace 5 horas',
    likes: 18,
    liked: true,
  ),
  CommunityPost(
    user: 'Miguel R.',
    initials: 'MR',
    from: Color(0xFFF97316), // naranja
    to: Color(0xFFEF4444), // rojo
    workout: 'Nuevo PR en sentadilla: 140 kg',
    time: 'Hace 1 día',
    likes: 32,
    liked: false,
  ),
];