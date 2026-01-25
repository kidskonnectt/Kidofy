import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategorySelector extends StatefulWidget {
  final Function(String) onCategorySelected;
  final String selectedCategoryId;

  const CategorySelector({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategoryId,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // Reduced height (medium size)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MockData.categories.length,
        // improve scrolling speed assumption by relying on default physics which are already platform specific and good.
        // To strictly "make the animation very slow make it fast" usually means ensuring lightweight items or custom physics.
        // Default BouncingScrollPhysics or ClampingScrollPhysics are generally fast.
        // However, user specifically asked for "fast" animation. We can try setting physics.
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final category = MockData.categories[index];
          final isSelected = widget.selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () => widget.onCategorySelected(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150), // Faseter animation
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ), // Adjusted padding
              decoration: BoxDecoration(
                color: isSelected ? Color(category.color) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Color(category.color).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.iconUrl != null && category.iconUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: CachedNetworkImage(
                        imageUrl: category.iconUrl!,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          _getIconForCategory(category.id),
                          color: isSelected
                              ? Colors.white
                              : Color(category.color),
                          size: 20,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _getIconForCategory(category.id),
                      color: isSelected ? Colors.white : Color(category.color),
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    category.id == '0'
                        ? category.name
                        : '${category.id}: ${category.name}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: Duration(milliseconds: index * 100));
        },
      ),
    );
  }

  IconData _getIconForCategory(String id) {
    switch (id) {
      case '1':
        return Icons.tv;
      case '2':
        return Icons.music_note;
      case '3':
        return Icons.school;
      case '0':
        return Icons.explore;
      case '5':
        return Icons.videogame_asset;
      case '6':
        return Icons.palette;
      case '7':
        return Icons.science;
      case '8':
        return Icons.construction;
      default:
        return Icons.star;
    }
  }
}
