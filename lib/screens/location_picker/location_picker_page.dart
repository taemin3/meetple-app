import 'package:flutter/material.dart';

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
            onTap: () => Navigator.of(context).pop(_results[index]),
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
