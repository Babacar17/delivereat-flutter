import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/restaurant_provider.dart';

class CategoryChipList extends StatefulWidget {
  final List<Category> categories;
  const CategoryChipList({super.key, required this.categories});

  @override
  State<CategoryChipList> createState() => _CategoryChipListState();
}

class _CategoryChipListState extends State<CategoryChipList> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final selected = _selectedId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${category.emoji} ${category.name}'),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedId = selected ? null : category.id);
                context.read<RestaurantProvider>().setCategory(_selectedId);
              },
            ),
          );
        },
      ),
    );
  }
}
