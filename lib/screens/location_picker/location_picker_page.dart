import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/location_repository.dart';
import '../../models/location_search_result.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    required this.locationRepository,
  });

  final LocationRepository locationRepository;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _queryController = TextEditingController();

  List<LocationSearchResult> _results = const [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Object? _error;
  int _searchGeneration = 0;
  int _reverseGeneration = 0;
  LocationSearchResult? _selectedLocation;
  NaverMapController? _mapController;
  NMarker? _selectedMarker;
  bool _isResolvingLocation = false;
  Object? _reverseError;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          '장소 선택',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _SearchField(
              controller: _queryController,
              isSearching: _isSearching,
              onSubmitted: _search,
            ),
            const SizedBox(height: 18),
            if (_selectedLocation != null) ...[
              _SelectedLocationPreview(
                location: _selectedLocation!,
                isMapEnabled: AppConfig.hasNaverMapClientId,
                isResolvingLocation: _isResolvingLocation,
                reverseError: _reverseError,
                onMapReady: _handleMapReady,
                onMapTapped: _moveSelectedPin,
                onConfirm: _isResolvingLocation ? null : _confirmLocation,
              ),
              const SizedBox(height: 18),
            ],
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const _LocationStatus(
        icon: Icons.search,
        title: '장소를 검색하는 중입니다.',
      );
    }

    final error = _error;
    if (error != null) {
      return _LocationStatus(
        icon: Icons.error_outline,
        title: _errorMessage(error),
        actionLabel: '다시 검색',
        onAction: _search,
      );
    }

    if (!_hasSearched) {
      return const _LocationStatus(
        icon: Icons.place_outlined,
        title: '모임 장소를 검색해주세요.',
      );
    }

    if (_results.isEmpty) {
      return const _LocationStatus(
        icon: Icons.search_off,
        title: '검색 결과가 없습니다.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _results.length; index++) ...[
          _LocationResultCard(
            key: Key('location_picker_result_$index'),
            result: _results[index],
            onTap: () => _selectLocation(_results[index]),
          ),
          if (index != _results.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isSearching) {
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });

    List<LocationSearchResult> results = const [];
    Object? error;
    try {
      results = await widget.locationRepository.search(query, display: 5);
    } on Object catch (caughtError) {
      error = caughtError;
    }

    if (!mounted || generation != _searchGeneration) {
      return;
    }

    setState(() {
      _isSearching = false;
      _results = results;
      _error = error;
    });
  }

  Future<void> _selectLocation(LocationSearchResult location) async {
    setState(() {
      _selectedLocation = location;
      _selectedMarker = null;
      _isResolvingLocation = false;
      _reverseError = null;
    });

    await _moveCameraTo(location);
    await _updateMarker(location);
  }

  void _handleMapReady(NaverMapController controller) {
    _mapController = controller;
    final selectedLocation = _selectedLocation;
    if (selectedLocation != null) {
      _updateMarker(selectedLocation);
    }
  }

  Future<void> _moveSelectedPin(NLatLng latLng) async {
    final selectedLocation = _selectedLocation;
    if (selectedLocation == null) {
      return;
    }

    final movedLocation = selectedLocation.copyWith(
      id: 'map:selected:${latLng.latitude},${latLng.longitude}',
      type: 'COORDINATE',
      name: '지도에서 선택한 위치',
      category: '',
      address: '주소를 확인하는 중입니다.',
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
    setState(() {
      _selectedLocation = movedLocation;
      _isResolvingLocation = true;
      _reverseError = null;
    });

    await _updateMarker(movedLocation);

    final generation = ++_reverseGeneration;
    LocationSearchResult? resolvedLocation;
    Object? reverseError;
    try {
      resolvedLocation = await widget.locationRepository.reverse(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    } on Object catch (caughtError) {
      reverseError = caughtError;
    }

    if (!mounted || generation != _reverseGeneration) {
      return;
    }

    final nextLocation = (resolvedLocation ?? movedLocation).copyWith(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: resolvedLocation?.address ?? '주소를 찾지 못했습니다. 좌표를 확인해주세요.',
    );

    setState(() {
      _selectedLocation = nextLocation;
      _isResolvingLocation = false;
      _reverseError = reverseError;
    });

    await _updateMarker(nextLocation);
  }

  Future<void> _moveCameraTo(LocationSearchResult location) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(location.latitude, location.longitude),
        zoom: 16,
      ),
    );
  }

  Future<void> _updateMarker(LocationSearchResult location) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final position = NLatLng(location.latitude, location.longitude);
    final caption = NOverlayCaption(text: location.name);
    final marker = _selectedMarker;
    if (marker == null) {
      final newMarker = NMarker(
        id: 'selected_location_marker',
        position: position,
        caption: caption,
      );
      _selectedMarker = newMarker;
      await controller.addOverlay(newMarker);
      return;
    }

    marker
      ..setPosition(position)
      ..setCaption(caption);
  }

  void _confirmLocation() {
    final selectedLocation = _selectedLocation;
    if (selectedLocation == null) {
      return;
    }

    Navigator.of(context).pop(selectedLocation);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return '장소를 불러오지 못했습니다.';
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('location_picker_query'),
            controller: controller,
            enabled: !isSearching,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmitted(),
            decoration: const InputDecoration(
              hintText: '장소명 또는 주소 검색',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: IconButton.filled(
            key: const Key('location_picker_search'),
            onPressed: isSearching ? null : onSubmitted,
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: '검색',
          ),
        ),
      ],
    );
  }
}

class _SelectedLocationPreview extends StatelessWidget {
  const _SelectedLocationPreview({
    required this.location,
    required this.isMapEnabled,
    required this.isResolvingLocation,
    required this.reverseError,
    required this.onMapReady,
    required this.onMapTapped,
    required this.onConfirm,
  });

  final LocationSearchResult location;
  final bool isMapEnabled;
  final bool isResolvingLocation;
  final Object? reverseError;
  final ValueChanged<NaverMapController> onMapReady;
  final ValueChanged<NLatLng> onMapTapped;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final position = NLatLng(location.latitude, location.longitude);

    return Container(
      key: const Key('location_picker_selected_preview'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: isMapEnabled
                ? NaverMap(
                    key: ValueKey('map_${location.id}'),
                    forceGesture: true,
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: position,
                        zoom: 16,
                      ),
                      indoorLevelPickerEnable: false,
                      locationButtonEnable: false,
                      scaleBarEnable: false,
                      logoAlign: NLogoAlign.leftBottom,
                      logoMargin: const EdgeInsets.all(8),
                      contentPadding: const EdgeInsets.only(bottom: 28),
                    ),
                    onMapReady: onMapReady,
                    onMapTapped: (_, latLng) => onMapTapped(latLng),
                  )
                : const _MapUnavailablePreview(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${location.latitude.toStringAsFixed(6)}, '
                            '${location.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isResolvingLocation || reverseError != null) ...[
                  const SizedBox(height: 12),
                  _ReverseStatus(
                    isResolving: isResolvingLocation,
                    hasError: reverseError != null,
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const Key('location_picker_confirm'),
                    onPressed: onConfirm,
                    child: const Text('이 위치 선택'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapUnavailablePreview extends StatelessWidget {
  const _MapUnavailablePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('location_picker_map_unavailable'),
      color: AppColors.softSurface,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: AppColors.primary,
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              '지도 미리보기 준비 중',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Client ID를 넣으면 네이버 지도가 표시됩니다.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReverseStatus extends StatelessWidget {
  const _ReverseStatus({
    required this.isResolving,
    required this.hasError,
  });

  final bool isResolving;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final color = hasError ? AppColors.error : AppColors.primary;
    final message =
        hasError ? '주소를 찾지 못했습니다. 좌표로 선택할 수 있어요.' : '핀 위치의 주소를 확인하고 있습니다.';

    return Row(
      children: [
        if (isResolving)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            Icons.info_outline,
            color: color,
            size: 16,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationResultCard extends StatelessWidget {
  const _LocationResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final LocationSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  result.isPlace
                      ? Icons.place_outlined
                      : Icons.location_city_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeBadge(label: result.isPlace ? '장소' : '주소'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (result.category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        result.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
