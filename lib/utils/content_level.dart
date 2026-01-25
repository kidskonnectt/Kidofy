import 'package:kidsapp/models/mock_data.dart';

/// Canonical content level values used across the app/admin.
///
/// Keep these strings in sync with admin panel dropdown and DB values.
class ContentLevels {
  static const preschool = 'Preschool';
  static const younger = 'Younger';
  // Removed Older and Choose for me as per request

  static const values = <String>[preschool, younger];

  /// Computes an effective age using the stored age + birth month.
  ///
  /// The DB currently stores only `age` (years) and optional `birthMonth`.
  /// Without birth year, we can only safely auto-upgrade at the Preschool
  /// boundary.
  static int effectiveAge({required int age, int? birthMonth, DateTime? now}) {
    if (birthMonth == null) return age;
    final today = now ?? DateTime.now();

    // If a kid was created as 4, after their birthday month passes they
    // should be treated as 5+ (Younger). This enables the requested
    // "auto transfer into younger" behavior.
    if (age == 4 && today.month >= birthMonth) return 5;

    return age;
  }

  static String fromAge(int age) {
    if (age <= 4) return preschool;
    return younger; // All ages > 4 go to Younger
  }

  static String fromAgeAndBirthMonth(
    int age,
    int? birthMonth, {
    DateTime? now,
  }) {
    final eff = effectiveAge(age: age, birthMonth: birthMonth, now: now);
    return fromAge(eff);
  }

  static String normalize(
    String? level, {
    required int fallbackAge,
    int? fallbackBirthMonth,
  }) {
    final s = (level ?? '').trim();
    if (s.isEmpty) {
      return fromAgeAndBirthMonth(fallbackAge, fallbackBirthMonth);
    }

    final lower = s.toLowerCase();
    if (lower == preschool.toLowerCase()) return preschool;
    if (lower == younger.toLowerCase()) return younger;

    // Legacy values that must be removed from UI/authoring.
    if (lower == 'older') return younger;
    if (lower.replaceAll(' ', '') == 'chooseforme') {
      return fromAgeAndBirthMonth(fallbackAge, fallbackBirthMonth);
    }

    // Fallback for legacy "Older" or "Choose for me" -> map to Younger usually or re-calculate from age
    // But per instructions: "auto transfer into younger automatically by seeing age"
    return fromAgeAndBirthMonth(fallbackAge, fallbackBirthMonth);
  }

  /// Normalize the content level stored on a video.
  /// Legacy `Older` content is merged into `Younger`.
  static String normalizeVideoLevel(String? level) {
    final s = (level ?? '').trim();
    if (s.isEmpty) return '';
    final lower = s.toLowerCase();
    if (lower == preschool.toLowerCase()) return preschool;
    if (lower == younger.toLowerCase()) return younger;
    if (lower == 'older') return younger;
    if (lower == 'all') return 'All';
    return '';
  }

  static bool isVideoAllowedForProfile(Video video, Profile profile) {
    final normalizedVideoLevel = normalizeVideoLevel(video.contentLevel);
    if (normalizedVideoLevel.isEmpty) return true;
    if (normalizedVideoLevel.toLowerCase() == 'all') return true;

    final profileLevel = normalize(
      profile.contentType,
      fallbackAge: profile.age,
      fallbackBirthMonth: profile.birthMonth,
    );

    // Logic:
    // If Profile == Preschool -> Only Preschool videos
    // If Profile == Younger -> Preschool AND Younger videos

    if (profileLevel == preschool) {
      return normalizedVideoLevel.toLowerCase() == preschool.toLowerCase();
    } else {
      // Profile is Younger (or fallback to Younger)
      // Allow Preschool or Younger
      final lowerVideo = normalizedVideoLevel.toLowerCase();
      return lowerVideo == preschool.toLowerCase() ||
          lowerVideo == younger.toLowerCase();
    }
  }
}
