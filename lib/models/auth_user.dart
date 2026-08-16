class AuthUser {
  const AuthUser({
    required this.id,
    required this.nickname,
    required this.handle,
    required this.email,
    this.profileImageUrl,
    this.introduction,
    this.createdMeetingsCount = 0,
    this.joinedMeetingsCount = 0,
    this.likedMeetingsCount = 0,
  });

  final int id;
  final String nickname;
  final String handle;
  final String email;
  final String? profileImageUrl;
  final String? introduction;
  final int createdMeetingsCount;
  final int joinedMeetingsCount;
  final int likedMeetingsCount;

  AuthUser copyWith({
    int? id,
    String? nickname,
    String? handle,
    String? email,
    String? profileImageUrl,
    String? introduction,
    int? createdMeetingsCount,
    int? joinedMeetingsCount,
    int? likedMeetingsCount,
  }) {
    return AuthUser(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      handle: handle ?? this.handle,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      introduction: introduction ?? this.introduction,
      createdMeetingsCount: createdMeetingsCount ?? this.createdMeetingsCount,
      joinedMeetingsCount: joinedMeetingsCount ?? this.joinedMeetingsCount,
      likedMeetingsCount: likedMeetingsCount ?? this.likedMeetingsCount,
    );
  }
}
