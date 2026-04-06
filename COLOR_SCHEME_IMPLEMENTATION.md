# Unified Color Scheme Implementation

## Overview
Successfully implemented a centralized, consistent color scheme across the entire Fix My Campus app. All screens now use the same green color palette through a centralized `AppColors` class.

## Color Palette
- **Primary Green**: `#91C788` - Main brand color for buttons, AppBars, and primary elements
- **Dark Green**: `#52734D` - Text and dark elements
- **Light Green**: `#DDFFBC` - Light backgrounds and accents
- **Cream Background**: `#FEFFDE` - Main background color

## Semantic Colors
- **Status Pending**: `#FFA726` (Orange)
- **Status Under Work**: `#29B6F6` (Blue)
- **Status Fixed**: `#4CAF50` (Green)
- **Priority High**: `#E53935` (Red)
- **Priority Medium**: `#FFA726` (Orange)
- **Priority Low**: `#4CAF50` (Green)

## Files Created
1. **lib/core/constants/app_colors.dart** - Centralized color constants class

## Files Updated
1. **lib/main.dart** - Updated theme to use AppColors.primary
2. **lib/Screen/login.dart** - All hardcoded colors replaced with AppColors
3. **lib/Screen/register.dart** - All hardcoded colors replaced with AppColors
4. **lib/Screen/admin_dashboard.dart** - Status and priority colors use AppColors
5. **lib/Screen/complaint_register.dart** - Background and accent colors use AppColors
6. **lib/Screen/complaint_detail_screen.dart** - Complete redesign with AppColors
7. **lib/Screen/admin_map_view.dart** - Map markers and dialogs use AppColors
8. **lib/Screen/splash_screen.dart** - Splash screen uses AppColors.primary
9. **lib/Screen/user_complaints_screen.dart** - Status colors use AppColors
10. **lib/Screen/fixed_complaints_history.dart** - All colors use AppColors
11. **lib/mapScreen.dart** - Map UI uses AppColors

## Benefits
✅ Consistent color scheme across entire app
✅ Easy to maintain - change colors in one place
✅ Professional appearance with unified branding
✅ Semantic color usage for status and priority indicators
✅ Improved code readability and maintainability

## Usage
Import the colors in any file:
```dart
import 'package:fix_my_campus/core/constants/app_colors.dart';

// Use in widgets
backgroundColor: AppColors.primary,
color: AppColors.dark,
```

## Color Reference
- `AppColors.primary` - Main green (#91C788)
- `AppColors.dark` - Dark green (#52734D)
- `AppColors.light` - Light green (#DDFFBC)
- `AppColors.background` - Cream (#FEFFDE)
- `AppColors.statusPending` - Orange
- `AppColors.statusUnderWork` - Blue
- `AppColors.statusFixed` - Green
- `AppColors.priorityHigh` - Red
- `AppColors.priorityMedium` - Orange
- `AppColors.priorityLow` - Green
