import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_image_upload_repository.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/meeting_list_card.dart';

class GlobalMeetingSearchPage extends StatefulWidget {
  const GlobalMeetingSearchPage({
    super.key,
    required this.meetingRepository,
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.imageUploadRepository = const MockImageUploadRepository(),
    required this.initialKeyword,
    required this.originLatitude,
    required this.originLongitude,
    this.categories = const ['전체'],
    this.initialCategory,
    this.onMeetingChanged,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;
  final String initialKeyword;
  final double originLatitude;
  final double originLongitude;
  final List<String> categories;
  final String? initialCategory;
  final VoidCallback? onMeetingChanged;

  @override
  State<GlobalMeetingSearchPage> createState() =>
      _GlobalMeetingSearchPageState();
}

class _GlobalMeetingSearchPageState extends State<GlobalMeetingSearchPage> {
  static const _pageSize = 20;

  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  List<Meeting> _meetings = const [];
  late List<String> _categories;
  late String _submittedKeyword;
  late String _selectedCategory;
  Object? _loadError;
  Object? _loadMoreError;
  int _totalElements = 0;
  int _nextPage = 0;
  int _requestGeneration = 0;
  int _categoryRequestGeneration = 0;
  bool _hasNextPage = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _submittedKeyword = widget.initialKeyword.trim();
    _searchController = TextEditingController(text: _submittedKeyword);
    _categories = _resolveInitialCategories();
    _selectedCategory = _resolveInitialCategory();
    _scrollController.addListener(_handleScroll);
    unawaited(_loadCategories());
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _categoryRequestGeneration += 1;
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _resolveInitialCategory() {
    final category = widget.initialCategory?.trim();
    if (category != null &&
        category.isNotEmpty &&
        _categories.contains(category)) {
      return category;
    }
    return '전체';
  }

  List<String> _resolveInitialCategories() {
    final categories = <String>{
      '전체',
      ...widget.categories.map((category) => category.trim()).where(
            (category) => category.isNotEmpty && category != '전체',
          ),
    };
    final initialCategory = widget.initialCategory?.trim();
    if (initialCategory != null && initialCategory.isNotEmpty) {
      categories.add(initialCategory);
    }
    return categories.toList(growable: false);
  }

  Future<void> _loadCategories() async {
    final generation = ++_categoryRequestGeneration;
    try {
      final categories = await widget.categoryRepository.findAll();
      if (!mounted || generation != _categoryRequestGeneration) {
        return;
      }

      final availableCategories = <String>{
        '전체',
        ...categories.map((category) => category.name.trim()).where(
              (category) => category.isNotEmpty && category != '전체',
            ),
      }.toList(growable: false);
      final shouldResetCategory =
          !availableCategories.contains(_selectedCategory);
      setState(() {
        _categories = availableCategories;
        if (shouldResetCategory) {
          _selectedCategory = '전체';
        }
      });
      if (shouldResetCategory) {
        unawaited(_loadFirstPage());
      }
    } catch (_) {
      // Keep the categories received from the previous screen when loading fails.
    }
  }

  Future<void> _loadFirstPage() async {
    final keyword = _submittedKeyword.trim();
    if (keyword.isEmpty) {
      setState(() {
        _meetings = const [];
        _totalElements = 0;
        _hasNextPage = false;
        _isLoading = false;
        _loadError = null;
        _loadMoreError = null;
      });
      return;
    }

    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _loadMoreError = null;
    });

    try {
      final result = await _searchPage(0);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _meetings = result.meetings;
        _totalElements = result.totalElements;
        _nextPage = result.page + 1;
        _hasNextPage = result.hasNext;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _meetings = const [];
        _totalElements = 0;
        _hasNextPage = false;
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _isLoadingMore || !_hasNextPage) {
      return;
    }

    final generation = _requestGeneration;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });
    try {
      final result = await _searchPage(_nextPage);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _meetings = [..._meetings, ...result.meetings];
        _totalElements = result.totalElements;
        _nextPage = result.page + 1;
        _hasNextPage = result.hasNext;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = error;
      });
    }
  }

  Future<MeetingSearchPage> _searchPage(int page) {
    return widget.meetingRepository.searchMeetings(
      MeetingSearchQuery(
        keyword: _submittedKeyword,
        category: _selectedCategory == '전체' ? null : _selectedCategory,
        latitude: widget.originLatitude,
        longitude: widget.originLongitude,
        page: page,
        size: _pageSize,
      ),
    );
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 280) {
      unawaited(_loadNextPage());
    }
  }

  void _submitSearch(String value) {
    final keyword = value.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    if (keyword == _submittedKeyword && _loadError == null) {
      return;
    }
    setState(() => _submittedKeyword = keyword);
    unawaited(_loadFirstPage());
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }
    setState(() => _selectedCategory = category);
    unawaited(_loadFirstPage());
  }

  Future<void> _openMeetingDetail(Meeting meeting) async {
    final result = await AppRoutes.openMeetingDetail<Object>(
      context,
      meeting,
      meetingRepository: widget.meetingRepository,
      categoryRepository: widget.categoryRepository,
      locationRepository: widget.locationRepository,
      imageUploadRepository: widget.imageUploadRepository,
    );
    if (result != null && mounted) {
      widget.onMeetingChanged?.call();
      await _loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('global-meeting-search-page'),
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '뒤로 가기',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('global-search-field'),
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        hintText: '전국 모임 검색',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _submitSearch('');
                                },
                                tooltip: '검색어 지우기',
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    key: ValueKey('global-search-category-$category'),
                    label: Text(category == '전체' ? '전체' : category),
                    selected: selected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.line,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_submittedKeyword.isNotEmpty &&
                !_isLoading &&
                _loadError == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '‘$_submittedKeyword’ 검색 결과 $_totalElements개',
                        key: const Key('global-search-result-count'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '가까운 순',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_submittedKeyword.isEmpty) {
      return const AppEmptyView(
        message: '검색어를 입력하고 키보드의 검색 버튼을 눌러주세요.',
        height: double.infinity,
      );
    }
    if (_isLoading) {
      return const AppLoadingView(
        message: '전국 모임을 검색하고 있습니다.',
        height: double.infinity,
      );
    }
    if (_loadError != null) {
      return AppErrorView(
        message: '전국 모임 검색 결과를 불러오지 못했습니다.',
        height: double.infinity,
        onRetry: _loadFirstPage,
      );
    }
    if (_meetings.isEmpty) {
      return AppEmptyView(
        message: '전국에서 ‘$_submittedKeyword’ 모임을 찾지 못했어요.',
        height: double.infinity,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        key: const Key('global-search-list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _meetings.length +
            ((_isLoadingMore || _loadMoreError != null) ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _meetings.length) {
            if (_loadMoreError != null) {
              return TextButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다음 결과 다시 불러오기'),
              );
            }
            return const Padding(
              key: Key('global-search-loading-more'),
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final meeting = _meetings[index];
          return MeetingListCard(
            key: ValueKey('global-search-meeting-${meeting.id ?? index}'),
            meeting: meeting,
            onTap: () => _openMeetingDetail(meeting),
            trailing: Text(
              meeting.distance,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}
