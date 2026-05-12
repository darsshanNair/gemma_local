import 'package:flutter/material.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';

enum TodoCategory { general, work, personal, health, finances }

extension TodoCategoryX on TodoCategory {
  String get displayName {
    return switch (this) {
      TodoCategory.general => 'General',
      TodoCategory.work => 'Work',
      TodoCategory.personal => 'Personal',
      TodoCategory.health => 'Health',
      TodoCategory.finances => 'Finances',
    };
  }

  Color get color {
    return switch (this) {
      TodoCategory.general => AppColors.blue,
      TodoCategory.work => AppColors.purple,
      TodoCategory.personal => AppColors.amber,
      TodoCategory.health => AppColors.pink,
      TodoCategory.finances => AppColors.green,
    };
  }
}
