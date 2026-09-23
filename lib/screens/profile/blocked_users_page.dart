import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/moderation_repository.dart';
import '../../models/moderation.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({
    super.key,
    required this.repository,
    this.onChanged,
  });
  final ModerationRepository repository;
  final VoidCallback? onChanged;

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<List<BlockedMember>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.getBlockedMembers();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Column(children: [
          const AppPageHeader(title: '차단한 사용자 관리'),
          Expanded(
              child: FutureBuilder<List<BlockedMember>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState != ConnectionState.done) {
                return const AppLoadingView(message: '차단 목록을 불러오는 중입니다.');
              }
              if (snapshot.hasError) {
                return AppErrorView(
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : '차단 목록을 불러오지 못했습니다.',
                  onRetry: _reload,
                );
              }
              final members = snapshot.data ?? const [];
              if (members.isEmpty) {
                return const AppEmptyView(message: '차단한 사용자가 없습니다.');
              }
              return ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    key: ValueKey('blocked-member-${member.memberId}'),
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(member.nickname),
                    trailing: OutlinedButton(
                        onPressed: () => _unblock(member),
                        child: const Text('차단 해제')),
                  );
                },
              );
            },
          )),
        ])),
      );

  void _reload() {
    setState(() {
      _future = widget.repository.getBlockedMembers();
    });
  }

  Future<void> _unblock(BlockedMember member) async {
    try {
      await widget.repository.unblockMember(member.memberId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('차단을 해제했습니다.')));
      widget.onChanged?.call();
      _reload();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(error is ApiException ? error.message : '차단을 해제하지 못했습니다.'),
        ));
      }
    }
  }
}
