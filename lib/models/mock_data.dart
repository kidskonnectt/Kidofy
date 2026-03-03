import 'package:flutter/material.dart';

class Video {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String? videoUrl; // Added videoUrl
  final String duration;
  final String channelName;
  final String? channelAvatarUrl;
  final String categoryId;
  final bool isShorts;
  final String?
  contentLevel; // Preschool, Younger, Older (optional/back-compat)

  const Video({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.duration,
    required this.channelName,
    this.channelAvatarUrl,
    required this.categoryId,
    this.isShorts = false,
    this.contentLevel,
  });
}

class Category {
  final String id;
  final String name;
  final int color;
  final String? iconUrl;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.iconUrl,
  });
}

class MartVideo {
  final String id;
  final String videoUrl; // Bunny CDN 9:16 video path
  final String thumbnailUrl;
  final String productLink; // External product link for commission
  final String shopName; // Shop/Brand name
  final int views; // View count
  final int clicks; // Link click count
  final DateTime createdAt;

  const MartVideo({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.productLink,
    required this.shopName,
    this.views = 0,
    this.clicks = 0,
    required this.createdAt,
  });
}

class Profile {
  final String id;
  final String name;
  final String avatarUrl;
  final int age;
  final String contentType; // Preschool, Younger, Older
  final int? birthMonth; // 1-12

  Profile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.age,
    this.contentType = 'Preschool',
    this.birthMonth,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'age': age,
      'contentType': contentType,
      'birthMonth': birthMonth,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      age: json['age'] as int,
      contentType: json['contentType'] as String? ?? 'Preschool',
      birthMonth: json['birthMonth'] as int?,
    );
  }
}

class MockData {
  static String? parentPasscode;
  static String? parentSecurityQuestion = 'What is your child first name?';
  static String? parentSecurityAnswer;

  // Explore is always ID 0 (local virtual category meaning "All").
  static List<Category> categories = [
    const Category(id: '0', name: 'Explore', color: 0xFFFFD600),
  ];

  static List<Video> videos = [];

  static List<Video> snaps = [];

  static List<MartVideo> martVideos = [];

  static List<Profile> profiles = [];

  static ValueNotifier<Profile?> currentProfile = ValueNotifier(null);
}
