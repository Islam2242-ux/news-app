import 'package:flutter/material.dart';
import 'package:news_app/utils/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        // Gunakan warna Deep Sea Blue sebagai aksen pada chip
        backgroundColor: AppColors.primary.withOpacity(0.1),
        selectedColor: AppColors.primary, // Deep Sea Blue Solid saat terpilih
        checkmarkColor: AppColors.onPrimary, // Checkmark putih
        labelStyle: TextStyle(
          // Teks putih saat terpilih, Deep Blue saat tidak
          color: isSelected ? AppColors.onPrimary : AppColors.primary, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            // Border mengikuti warna Deep Blue
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.5), 
          ),
        ),
      ),
    );
  }
}
