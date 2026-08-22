enum LegalDocumentType {
  serviceTerms('SERVICE_TERMS'),
  privacyPolicy('PRIVACY_POLICY'),
  age14Confirmation('AGE_14_CONFIRMATION');

  const LegalDocumentType(this.wireName);

  final String wireName;

  static LegalDocumentType fromWireName(String value) {
    return LegalDocumentType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () =>
          throw FormatException('Unknown legal document type: $value'),
    );
  }
}

class LegalDocument {
  const LegalDocument({
    required this.type,
    required this.version,
    required this.title,
    required this.content,
    required this.effectiveAt,
  });

  final LegalDocumentType type;
  final String version;
  final String title;
  final String content;
  final DateTime effectiveAt;

  Map<String, dynamic> toSignupJson() => {
        'type': type.wireName,
        'version': version,
      };
}
