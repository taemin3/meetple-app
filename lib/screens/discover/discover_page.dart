import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_navigation.dart';
import '../../app/app_routes.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/meeting_style.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/map/nearby_meeting_map.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/tag_chip.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository = const MockCategoryRepository(),
    this.refreshToken = 0,
    this.onMeetingChanged,
    this.openRequest,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final int refreshToken;
  final VoidCallback? onMeetingChanged;
  final DiscoverOpenRequest? openRequest;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const _initialCoordinate = NearbyMapCoordinate(
    latitude: 37.5283,
    longitude: 126.9326,
  );
  static const _defaultSearchZoom = 14.0;
  static const _defaultSearchRadiusMeters = 5000;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  NearbyMeetingMapController? _mapController;
  NearbyMapCoordinate _searchCenter = _initialCoordinate;
  NearbyMapCoordinate _pendingCenter = _initialCoordinate;
  double _searchZoom = _defaultSearchZoom;
  double _pendingZoom = _defaultSearchZoom;
  int _searchRadiusMeters = _defaultSearchRadiusMeters;
  List<String> _categories = const ['전체'];
  List<Meeting> _meetings = const [];
  Meeting? _selectedMeeting;
  Object? _loadError;
  String _selectedCategory = '전체';
  String _searchText = '';
  String? _locationNotice;
  bool _isLoading = true;
  bool _isLocating = false;
  bool _isSheetCollapsed = false;
  bool _showSearchAreaButton = false;
  bool _requestedInitialLocation = false;
  int _requestGeneration = 0;
  int _categoryRequestGeneration = 0;
  int? _handledOpenRequestId;

  bool get _isLiveMapEnabled =>
      AppConfig.hasNaverMapClientId && isNearbyMeetingMapSupported;

  List<Meeting> get _visibleMeetings {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return _meetings;
    }

    return _meetings.where((meeting) {
      return meeting.title.toLowerCase().contains(query) ||
          meeting.area.toLowerCase().contains(query) ||
          meeting.category.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _applyOpenRequest(reload: false);
    unawaited(_loadCategories());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          _loadMeetingsAt(
            _searchCenter,
            zoom: _defaultSearchZoom,
          ),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository ||
        oldWidget.refreshToken != widget.refreshToken) {
      unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
    }
    if (oldWidget.categoryRepository != widget.categoryRepository) {
      unawaited(_loadCategories());
    }
    if (oldWidget.openRequest?.id != widget.openRequest?.id) {
      _applyOpenRequest(reload: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedSheetHeight =
            (constraints.maxHeight * 0.39).clamp(270.0, 310.0);
        const collapsedSheetHeight = 78.0;
        final sheetHeight =
            _isSheetCollapsed ? collapsedSheetHeight : expandedSheetHeight;
        final sheetBottom = _isSheetCollapsed
            ? collapsedSheetHeight - expandedSheetHeight
            : 0.0;
        final visibleMeetings = _visibleMeetings;
        final globalSearchKeyword = _searchText.trim();

        return Stack(
          children: [
            Positioned.fill(
              child: NearbyMeetingMap(
                enabled: _isLiveMapEnabled,
                initialCoordinate: _initialCoordinate,
                meetings: visibleMeetings,
                selectedMeeting: _selectedMeeting,
                onMapReady: _handleMapReady,
                onMapTapped: _clearSelectedMeeting,
                onMeetingTapped: _selectMeeting,
                onMeetingGroupTapped: _selectMeetingGroup,
                onCameraIdle: _handleCameraIdle,
                onLocationPermissionDenied: _handleLocationPermissionDenied,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MapSearchRow(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                          _selectedMeeting = null;
                        });
                      },
                      onFilterPressed: _openFilterSummary,
                    ),
                    const SizedBox(height: 12),
                    CategoryFilterRow(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onSelected: _selectCategory,
                    ),
                    if (globalSearchKeyword.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GlobalMeetingSearchEntry(
                        keyword: globalSearchKeyword,
                        onTap: _openGlobalMeetingSearch,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showSearchAreaButton && globalSearchKeyword.isEmpty)
              Positioned(
                top: 130,
                left: 24,
                right: 24,
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () => _loadMeetingsAt(
                      _pendingCenter,
                      zoom: _pendingZoom,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                      shadowColor: const Color(0x3517151F),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      '이 지역에서 다시 검색',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              )
            else if (_locationNotice != null && globalSearchKeyword.isEmpty)
              Positioned(
                top: 130,
                left: 20,
                right: 20,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2417151F),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        _locationNotice!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              right: 16,
              bottom: sheetHeight + 18,
              child: Column(
                children: [
                  MapRoundButton(
                    tooltip: '현재 위치',
                    icon: _isLocating ? null : Icons.my_location_rounded,
                    loading: _isLocating,
                    onPressed: _isLocating ? null : _moveToCurrentLocation,
                  ),
                  const SizedBox(height: 10),
                  MapRoundButton(
                    tooltip: '목록으로 보기',
                    icon: Icons.format_list_bulleted_rounded,
                    onPressed: visibleMeetings.isEmpty
                        ? null
                        : () => _openMeetingList(visibleMeetings),
                  ),
                ],
              ),
            ),
            if (_selectedMeeting != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: 16,
                right: 76,
                bottom: sheetHeight + 18,
                child: MeetingMapPreviewCard(
                  meeting: _selectedMeeting!,
                  onTap: () => _openMeetingDetail(_selectedMeeting!),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: sheetBottom,
              height: expandedSheetHeight,
              child: NearbyMeetingSheet(
                meetings: visibleMeetings,
                isLoading: _isLoading,
                error: _loadError,
                collapsed: _isSheetCollapsed,
                onCollapsedChanged: _setSheetCollapsed,
                onRetry: () =>
                    _loadMeetingsAt(_searchCenter, zoom: _searchZoom),
                onViewAll: visibleMeetings.isEmpty
                    ? null
                    : () => _openMeetingList(visibleMeetings),
                onMeetingTap: _openMeetingDetail,
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMapReady(NearbyMeetingMapController controller) {
    _mapController = controller;
    if (!_requestedInitialLocation && _isLiveMapEnabled) {
      _requestedInitialLocation = true;
      unawaited(_moveToCurrentLocation(showFailureMessage: false));
    }
  }

  Future<void> _openMeetingDetail(Meeting meeting) async {
    final result = await AppRoutes.openMeetingDetail<Object>(
      context,
      meeting,
      meetingRepository: widget.meetingRepository,
    );
    if (result != null && mounted) {
      final onMeetingChanged = widget.onMeetingChanged;
      if (onMeetingChanged != null) {
        onMeetingChanged();
      } else {
        await _loadMeetingsAt(_searchCenter, zoom: _searchZoom);
      }
    }
  }

  Future<void> _openGlobalMeetingSearch() async {
    final keyword = _searchText.trim();
    if (keyword.isEmpty) {
      return;
    }

    _searchFocusNode.unfocus();
    final categories =
        _selectedCategory == '전체' || _categories.contains(_selectedCategory)
            ? _categories
            : [..._categories, _selectedCategory];
    await AppRoutes.openGlobalMeetingSearch<Object>(
      context,
      keyword: keyword,
      originLatitude: _searchCenter.latitude,
      originLongitude: _searchCenter.longitude,
      categories: List.unmodifiable(categories),
      initialCategory: _selectedCategory == '전체' ? null : _selectedCategory,
      meetingRepository: widget.meetingRepository,
      categoryRepository: widget.categoryRepository,
      onMeetingChanged: _handleMeetingChangedFromGlobalSearch,
    );
  }

  void _handleMeetingChangedFromGlobalSearch() {
    final onMeetingChanged = widget.onMeetingChanged;
    if (onMeetingChanged != null) {
      onMeetingChanged();
    } else {
      unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
    }
  }

  void _handleCameraIdle(NearbyMapCoordinate coordinate, double zoom) {
    final movedMeters = _distanceMeters(_searchCenter, coordinate);
    final zoomChanged = (_searchZoom - zoom).abs() >= 0.15;
    setState(() {
      _pendingCenter = coordinate;
      _pendingZoom = zoom;
      _showSearchAreaButton = movedMeters > 350 || zoomChanged;
    });
  }

  void _handleLocationPermissionDenied(bool isForeverDenied) {
    if (!mounted) {
      return;
    }

    setState(() {
      _locationNotice = isForeverDenied
          ? '위치 권한이 꺼져 있어 기본 지역을 보여드려요.'
          : '위치 권한을 허용하면 내 주변 모임을 볼 수 있어요.';
    });
  }

  Future<void> _moveToCurrentLocation({
    bool showFailureMessage = true,
  }) async {
    final controller = _mapController;
    if (controller == null || !_isLiveMapEnabled) {
      if (showFailureMessage) {
        _showMessage('지도 설정 후 현재 위치를 사용할 수 있어요.');
      }
      return;
    }

    setState(() => _isLocating = true);
    final coordinate = await controller.requestCurrentLocation();
    if (!mounted) {
      return;
    }

    if (coordinate == null) {
      setState(() {
        _isLocating = false;
        _locationNotice ??= '현재 위치를 확인할 수 없어 기본 지역을 보여드려요.';
      });
      if (showFailureMessage) {
        _showMessage('위치 서비스와 위치 권한을 확인해주세요.');
      }
      return;
    }

    setState(() {
      _isLocating = false;
      _locationNotice = null;
      _searchCenter = coordinate;
      _pendingCenter = coordinate;
      _showSearchAreaButton = false;
    });
    await controller.moveTo(coordinate, zoom: _defaultSearchZoom);
    await _loadMeetingsAt(coordinate, zoom: _defaultSearchZoom);
  }

  Future<void> _loadMeetingsAt(
    NearbyMapCoordinate coordinate, {
    double? zoom,
  }) async {
    final generation = ++_requestGeneration;
    final effectiveZoom = zoom ?? _searchZoom;
    final radiusMeters = _searchRadiusForZoom(effectiveZoom);
    setState(() {
      _isLoading = true;
      _loadError = null;
      _searchCenter = coordinate;
      _pendingCenter = coordinate;
      _searchZoom = effectiveZoom;
      _pendingZoom = effectiveZoom;
      _searchRadiusMeters = radiusMeters;
      _showSearchAreaButton = false;
      _selectedMeeting = null;
    });

    try {
      final meetings = await widget.meetingRepository.findNearby(
        NearbyMeetingQuery(
          latitude: coordinate.latitude,
          longitude: coordinate.longitude,
          radiusMeters: radiusMeters,
          category: _selectedCategory == '전체' ? null : _selectedCategory,
        ),
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _meetings = const [];
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }

    setState(() => _selectedCategory = category);
    unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
  }

  void _applyOpenRequest({required bool reload}) {
    final request = widget.openRequest;
    if (request == null || request.id == _handledOpenRequestId) {
      return;
    }

    _handledOpenRequestId = request.id;
    final category = request.category?.trim();
    _selectedCategory = category == null || category.isEmpty ? '전체' : category;
    _searchController.clear();
    _searchText = '';
    _selectedMeeting = null;
    _isSheetCollapsed = false;

    if (request.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }

    if (reload) {
      unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
    }
  }

  Future<void> _loadCategories() async {
    final generation = ++_categoryRequestGeneration;
    try {
      final categories = await widget.categoryRepository.findAll();
      if (!mounted || generation != _categoryRequestGeneration) {
        return;
      }

      final names = categories
          .map((category) => category.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final availableCategories = ['전체', ...names];
      final shouldResetCategory =
          !availableCategories.contains(_selectedCategory);
      setState(() {
        _categories = availableCategories;
        if (shouldResetCategory) {
          _selectedCategory = '전체';
        }
      });
      if (shouldResetCategory) {
        unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
      }
    } catch (_) {
      if (!mounted || generation != _categoryRequestGeneration) {
        return;
      }
      final shouldResetCategory = _selectedCategory != '전체';
      setState(() {
        _categories = const ['전체'];
        _selectedCategory = '전체';
      });
      if (shouldResetCategory) {
        unawaited(_loadMeetingsAt(_searchCenter, zoom: _searchZoom));
      }
    }
  }

  void _selectMeeting(Meeting meeting) {
    setState(() => _selectedMeeting = meeting);
  }

  void _selectMeetingGroup(List<Meeting> meetings) {
    if (meetings.isEmpty) {
      return;
    }
    if (meetings.length == 1) {
      _selectMeeting(meetings.single);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meetings.length}개의 모임이 있어요',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '확인할 모임을 선택해 주세요.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: meetings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final meeting = meetings[index];
                      return MeetingListTile(
                        meeting: meeting,
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          _selectMeeting(meeting);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSheetCollapsed(bool collapsed) {
    if (_isSheetCollapsed == collapsed) {
      return;
    }
    setState(() => _isSheetCollapsed = collapsed);
  }

  void _clearSelectedMeeting() {
    if (_selectedMeeting != null) {
      setState(() => _selectedMeeting = null);
    }
  }

  void _openFilterSummary() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '탐색 범위',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '현재 지도 크기에 맞춰 약 ${_formatSearchRadius(_searchRadiusMeters)} '
                  '안의 모임을 찾습니다. 지도를 넓게 보면 검색 범위도 최대 50km까지 늘어납니다.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMeetingList(List<Meeting> meetings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        '내 주변 모임',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: meetings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final meeting = meetings[index];
                      return MeetingListTile(
                        meeting: meeting,
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          unawaited(_openMeetingDetail(meeting));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _distanceMeters(
    NearbyMapCoordinate from,
    NearbyMapCoordinate to,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(to.latitude - from.latitude);
    final longitudeDelta = _toRadians(to.longitude - from.longitude);
    final fromLatitude = _toRadians(from.latitude);
    final toLatitude = _toRadians(to.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
            math.cos(fromLatitude) *
                math.cos(toLatitude) *
                math.sin(longitudeDelta / 2) *
                math.sin(longitudeDelta / 2);

    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  int _searchRadiusForZoom(double zoom) {
    final radius =
        _defaultSearchRadiusMeters * math.pow(2, _defaultSearchZoom - zoom);
    return radius.round().clamp(1000, 50000);
  }

  String _formatSearchRadius(int radiusMeters) {
    if (radiusMeters < 1000) {
      return '${radiusMeters}m';
    }
    final kilometers = radiusMeters / 1000;
    return kilometers == kilometers.roundToDouble()
        ? '${kilometers.toInt()}km'
        : '${kilometers.toStringAsFixed(1)}km';
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class MapSearchRow extends StatelessWidget {
  const MapSearchRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onFilterPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A17151F),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              key: const Key('discover-search-field'),
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                hintText: '모임, 장소, 카테고리 검색',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 3,
          shadowColor: const Color(0x2617151F),
          child: IconButton(
            onPressed: onFilterPressed,
            tooltip: '필터',
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class GlobalMeetingSearchEntry extends StatelessWidget {
  const GlobalMeetingSearchEntry({
    super.key,
    required this.keyword,
    required this.onTap,
  });

  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('discover-global-search-entry'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: const Color(0x2617151F),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.public_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '전국에서 ‘$keyword’ 검색',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            GestureDetector(
              onTap: () => onSelected(category),
              child: TagChip(
                label: category,
                selected: selectedCategory == category,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String tooltip;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0x2E17151F),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

class MeetingMapPreviewCard extends StatelessWidget {
  const MeetingMapPreviewCard({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = meetingAccent(meeting);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: const Color(0x3017151F),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: MeetingPhoto(
                  meeting: meeting,
                  height: 62,
                  borderRadius: 14,
                  showIcon: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${meeting.date} · ${meeting.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        CategoryPill(
                          label: meeting.category,
                          color: accent,
                        ),
                        const Spacer(),
                        Text(
                          '${meeting.joined} / ${meeting.capacity}명',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyMeetingSheet extends StatelessWidget {
  const NearbyMeetingSheet({
    super.key,
    required this.meetings,
    required this.isLoading,
    required this.error,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.onRetry,
    required this.onViewAll,
    required this.onMeetingTap,
  });

  final List<Meeting> meetings;
  final bool isLoading;
  final Object? error;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChanged;
  final VoidCallback onRetry;
  final VoidCallback? onViewAll;
  final ValueChanged<Meeting> onMeetingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2617151F),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCollapsedChanged(!collapsed),
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 80) {
                onCollapsedChanged(true);
              } else if (velocity < -80) {
                onCollapsedChanged(false);
              }
            },
            child: Column(
              children: [
                const SizedBox(height: 9),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 9, 12, 7),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '내 주변 모임 🔥',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        collapsed
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                      ),
                      if (!collapsed)
                        TextButton(
                          onPressed: onViewAll,
                          child: const Text('전체보기'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!collapsed) ...[
            if (isLoading && meetings.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent()),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && meetings.isEmpty) {
      return const _NearbyMeetingSkeletonList();
    }

    if (error != null && meetings.isEmpty) {
      return AppErrorView(
        message: '주변 모임을 불러오지 못했습니다.',
        onRetry: onRetry,
      );
    }

    if (meetings.isEmpty) {
      return const AppEmptyView(message: '조건에 맞는 주변 모임이 없습니다.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      scrollDirection: Axis.horizontal,
      itemCount: meetings.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return MapMeetingCard(
          key: ValueKey(
            'nearby-meeting-card-${meeting.id ?? 'index-$index'}',
          ),
          meeting: meeting,
          onTap: () => onMeetingTap(meeting),
        );
      },
    );
  }
}

class _NearbyMeetingSkeletonList extends StatelessWidget {
  const _NearbyMeetingSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('nearby-meeting-skeleton-list'),
      container: true,
      liveRegion: true,
      label: '내 주변 모임을 불러오는 중입니다.',
      child: ExcludeSemantics(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _MapMeetingSkeletonCard(
              key: ValueKey('nearby-meeting-skeleton-$index'),
            );
          },
        ),
      ),
    );
  }
}

class _MapMeetingSkeletonCard extends StatelessWidget {
  const _MapMeetingSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 161,
          margin: const EdgeInsets.fromLTRB(1, 2, 1, 7),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0EDF7)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height: 76,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 9, 8, 0),
                child: SkeletonBox(width: 118, height: 14),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 9, 8, 0),
                child: Row(
                  children: [
                    SkeletonBox(width: 48, height: 20),
                    Spacer(),
                    SkeletonBox(width: 38, height: 11),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 9, 8, 0),
                child: SkeletonBox(width: 124, height: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapMeetingCard extends StatelessWidget {
  const MapMeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = meetingAccent(meeting);

    return SizedBox(
      width: 164,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 168,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 2, 1, 7),
            child: Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x3017151F),
              surfaceTintColor: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFF0EDF7)),
              ),
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MeetingPhoto(
                      meeting: meeting,
                      height: 76,
                      borderRadius: 0,
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        meeting.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          CategoryPill(label: meeting.category, color: color),
                          const Spacer(),
                          Text(
                            '${meeting.joined}/${meeting.capacity}명',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${meeting.date} · ${meeting.area} · ${meeting.distance}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MeetingListTile extends StatelessWidget {
  const MeetingListTile({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: MeetingPhoto(
                  meeting: meeting,
                  height: 82,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meeting.date} · ${meeting.time}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meeting.area} · ${meeting.distance}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${meeting.joined} / ${meeting.capacity}명 참여',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
