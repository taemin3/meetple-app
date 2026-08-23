import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/legal_document.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/centered_page_app_bar.dart';
import '../../widgets/surface_panel.dart';
import '../auth/auth_form_widgets.dart';

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  late Future<List<LegalDocument>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    _documentsFuture =
        widget.authRepository.getSignupLegalDocuments().then(_visibleDocuments);
  }

  void _reloadDocuments() {
    setState(_loadDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CenteredPageAppBar(
        title: '약관 및 정책',
        backButtonKey: Key('legal_documents_back'),
      ),
      backgroundColor: AppColors.canvas,
      body: FutureBuilder<List<LegalDocument>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(
              message: '약관 정보를 불러오는 중입니다.',
              height: 240,
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppErrorView(
              message: error is Exception
                  ? authErrorMessage(error)
                  : '약관 정보를 불러오지 못했습니다.',
              height: 240,
              onRetry: _reloadDocuments,
            );
          }

          final documents = snapshot.data ?? const <LegalDocument>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              SurfacePanel(
                child: Column(
                  children: [
                    for (var index = 0; index < documents.length; index++) ...[
                      _LegalDocumentTile(document: documents[index]),
                      if (index != documents.length - 1)
                        const Divider(height: 22, color: AppColors.line),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<LegalDocument> _visibleDocuments(List<LegalDocument> documents) {
    final documentsByType = {
      for (final document in documents) document.type: document,
    };
    final serviceTerms = documentsByType[LegalDocumentType.serviceTerms];
    final privacyPolicy = documentsByType[LegalDocumentType.privacyPolicy];
    if (serviceTerms == null || privacyPolicy == null) {
      throw const AuthException('약관 정보를 불러오지 못했습니다.');
    }
    return [serviceTerms, privacyPolicy];
  }
}

class _LegalDocumentTile extends StatelessWidget {
  const _LegalDocumentTile({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('legal_document_${document.type.wireName}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => LegalDocumentDetailPage(document: document),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '시행일 ${_formatDate(document.effectiveAt)} · 버전 ${document.version}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class LegalDocumentDetailPage extends StatelessWidget {
  const LegalDocumentDetailPage({
    super.key,
    required this.document,
  });

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CenteredPageAppBar(
        title: document.title,
        backButtonKey: const Key('legal_document_detail_back'),
      ),
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시행일 ${_formatDate(document.effectiveAt)} · 버전 ${document.version}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              document.content,
              key: const Key('legal_document_content'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}
