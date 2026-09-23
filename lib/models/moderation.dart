enum ReportTargetType {
  member('MEMBER'),
  meeting('MEETING'),
  chatMessage('CHAT_MESSAGE');

  const ReportTargetType(this.apiValue);
  final String apiValue;
}

enum ReportReason {
  spam('SPAM', '스팸'),
  abuseOrHarassment('ABUSE_OR_HARASSMENT', '욕설 또는 괴롭힘'),
  inappropriateContent('INAPPROPRIATE_CONTENT', '부적절한 콘텐츠'),
  fraudOrFalseInformation('FRAUD_OR_FALSE_INFORMATION', '사기 또는 허위 정보'),
  other('OTHER', '기타');

  const ReportReason(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class PublicMemberProfile {
  const PublicMemberProfile({
    required this.memberId,
    required this.nickname,
    this.profileImageUrl,
    this.introduction,
  });

  final int memberId;
  final String nickname;
  final String? profileImageUrl;
  final String? introduction;
}
