part of '../meeting_detail_page.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onParticipationPressed,
    required this.participationLabel,
    this.isBusy = false,
  });

  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onParticipationPressed;
  final String participationLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1417151F),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 56,
              child: OutlinedButton(
                key: const Key('meeting-detail-bottom-favorite-button'),
                onPressed: onFavoritePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.line),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: isBusy ? '처리 중...' : participationLabel,
                onPressed: onParticipationPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostDetailBottomBar extends StatelessWidget {
  const HostDetailBottomBar({
    super.key,
    required this.onEditPressed,
    required this.onManagePressed,
  });

  final VoidCallback? onEditPressed;
  final VoidCallback? onManagePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              height: 56,
              child: SecondaryButton(
                label: '수정',
                onPressed: onEditPressed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: '참여 신청 관리',
                onPressed: onManagePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailUnavailableBottomBar extends StatelessWidget {
  const DetailUnavailableBottomBar({
    super.key,
    required this.label,
    this.actionLabel,
    this.onPressed,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
