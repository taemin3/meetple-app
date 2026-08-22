import '../../models/legal_document.dart';

final mockSignupLegalDocuments = <LegalDocument>[
  LegalDocument(
    type: LegalDocumentType.serviceTerms,
    version: '2026-08-22',
    title: '서비스 이용약관',
    content: '밋플 서비스 이용에 필요한 기본 규칙과 회원의 권리·의무를 안내합니다.',
    effectiveAt: DateTime(2026, 8, 22),
  ),
  LegalDocument(
    type: LegalDocumentType.privacyPolicy,
    version: '2026-08-22',
    title: '개인정보 처리방침',
    content: '회원가입과 서비스 제공을 위해 처리하는 개인정보 항목과 보유 기간을 안내합니다.',
    effectiveAt: DateTime(2026, 8, 22),
  ),
  LegalDocument(
    type: LegalDocumentType.age14Confirmation,
    version: '2026-08-22',
    title: '만 14세 이상 확인',
    content: '회원가입을 진행하는 사용자는 만 14세 이상임을 확인합니다.',
    effectiveAt: DateTime(2026, 8, 22),
  ),
];
