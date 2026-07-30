import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class SegmentedCountFilterItem<T> {
  const SegmentedCountFilterItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class SegmentedCountFilterBar<T> extends StatelessWidget {
  const SegmentedCountFilterBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.countFor,
    required this.onSelected,
  });

  final List<SegmentedCountFilterItem<T>> items;
  final T selectedValue;
  final int Function(T value) countFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onSelected(item.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selectedValue == item.value
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${item.label} ${countFor(item.value)}',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedValue == item.value
                              ? Colors.white
                              : AppColors.ink,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
