class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'there';
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
