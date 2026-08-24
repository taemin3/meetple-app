import 'package:flutter/material.dart';

class CenteredPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CenteredPageAppBar({
    super.key,
    required this.title,
    this.backButtonKey,
    this.onBack,
    this.backEnabled = true,
    this.actions,
    this.backgroundColor,
  });

  final String title;
  final Key? backButtonKey;
  final VoidCallback? onBack;
  final bool backEnabled;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      leading: IconButton(
        key: backButtonKey,
        tooltip: '뒤로가기',
        onPressed: backEnabled
            ? onBack ?? () => Navigator.of(context).maybePop()
            : null,
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: actions,
    );
  }
}
