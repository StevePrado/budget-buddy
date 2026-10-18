import 'package:flutter/material.dart';

// Color palette for BudgetBuddy (Dark Navy Theme)
// Teammates: Use these colors everywhere instead of hardcoded colors!
class AppColors {
  AppColors._();

  // Background colors
  static const background = Color(0xFF0A1128); // Main app background
  static const surface = Color(0xFF111B3A); // Cards, nav bar, dialogs
  static const surfaceHigh = Color(0xFF1A2650); // Input boxes, chips, search bars
  static const border = Color(0xFF26346B); // Card borders and dividers

  // Main brand colors
  static const primary = Color(0xFF4C8DFF); // Main action buttons and active icons
  static const primaryDark = Color(0xFF2F5FD0); // Button pressed state
  static const secondary = Color(0xFF8B7CFF); // Badges and secondary highlights

  // Status colors
  static const success = Color(0xFF2DD4A7); // Remaining budget, under budget
  static const warning = Color(0xFFFFC53D); // Near limit warning
  static const danger = Color(0xFFFF5C72); // Over budget, delete actions, errors

  // Text colors
  static const textPrimary = Color(0xFFF2F5FF); // Main screen titles and headings
  static const textSecondary = Color(0xFF9AA6D1); // Subtitles and field labels
  static const textMuted = Color(0xFF65719E); // Inactive items and muted notes
}
