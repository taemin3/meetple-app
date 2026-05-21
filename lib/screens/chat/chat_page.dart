import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/icon_tile.dart';
import '../../widgets/surface_panel.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: SurfacePanel(
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.directions_run,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '한강 러닝 5km',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '승인된 참가자 5명',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: const [
              ChatBubble(
                sender: '민준',
                text: '오늘은 여의나루역 2번 출구에서 만나요.',
                mine: false,
              ),
              ChatBubble(
                sender: '나',
                text: '좋아요. 10분 전에 도착할게요.',
                mine: true,
              ),
              ChatBubble(
                sender: '서연',
                text: '스터디 자료는 채팅방에 올려둘게요.',
                mine: false,
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: '메시지 입력'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {},
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.mine,
  });

  final String sender;
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.ink,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
