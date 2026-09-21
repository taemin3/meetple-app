import 'package:flutter/foundation.dart';

import '../data/repositories/meeting_repository.dart';

/// Shares bookmark state between cards backed by the same repository.
class MeetingBookmarkStore extends ChangeNotifier {
  MeetingBookmarkStore._(this.repository);

  static final Expando<MeetingBookmarkStore> _stores =
      Expando<MeetingBookmarkStore>('meeting bookmarks');

  static MeetingBookmarkStore forRepository(MeetingRepository repository) {
    return _stores[repository] ??= MeetingBookmarkStore._(repository);
  }

  static void reset(MeetingRepository repository) {
    final store = _stores[repository];
    if (store == null) return;
    store._version++;
    store._loadGeneration++;
    store._load = null;
    store._bookmarkedIds = null;
    store.notifyListeners();
  }

  final MeetingRepository repository;
  Set<int>? _bookmarkedIds;
  Future<void>? _load;
  int _loadGeneration = 0;
  int _version = 0;
  final Set<int> _busyIds = {};

  bool get isLoaded => _bookmarkedIds != null;
  bool isBookmarked(int id) => _bookmarkedIds?.contains(id) ?? false;
  bool isBusy(int id) => _busyIds.contains(id);

  void recordBookmarkChange(int id, bool bookmarked) {
    _version++;
    if (_bookmarkedIds != null) {
      _setLocal(id, bookmarked);
      return;
    }
    final pendingLoad = _load;
    if (pendingLoad != null) {
      final generation = _loadGeneration;
      pendingLoad
          .then(
            (_) => generation == _loadGeneration ? refresh() : null,
            onError: (Object _) =>
                generation == _loadGeneration ? refresh() : null,
          )
          .catchError((Object _) {});
    }
  }

  Future<void> load() {
    if (isLoaded) return Future<void>.value();
    return _load ??= _fetch(++_loadGeneration);
  }

  Future<void> refresh() {
    if (_load != null) return _load!;
    return _load = _fetch(++_loadGeneration);
  }

  Future<void> _fetch(int generation) async {
    final version = _version;
    try {
      final meetings = await repository.getBookmarkedMeetings();
      if (version == _version && generation == _loadGeneration) {
        _bookmarkedIds = {
          for (final meeting in meetings)
            if (meeting.id case final id?) id,
        };
        notifyListeners();
      }
    } finally {
      if (generation == _loadGeneration) _load = null;
    }
  }

  Future<void> toggle(int id) async {
    if (!isLoaded || _busyIds.contains(id)) return;
    final next = !isBookmarked(id);
    _busyIds.add(id);
    _version++;
    _setLocal(id, next);
    try {
      if (next) {
        final engagement = await repository.getEngagement(id);
        if (engagement.isHost) {
          throw StateError('Host cannot bookmark own meeting.');
        }
      }
      await repository.setBookmarked(id, next);
    } catch (_) {
      _version++;
      _setLocal(id, !next);
      rethrow;
    } finally {
      _busyIds.remove(id);
      notifyListeners();
    }
  }

  void _setLocal(int id, bool bookmarked) {
    if (bookmarked) {
      _bookmarkedIds!.add(id);
    } else {
      _bookmarkedIds!.remove(id);
    }
    notifyListeners();
  }
}
