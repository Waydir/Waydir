import 'package:flutter/material.dart';
import 'app_theme.dart';

@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  final TextStyle badge;
  final TextStyle micro;
  final TextStyle caption;
  final TextStyle captionSmall;
  final TextStyle sectionLabel;
  final TextStyle keyCap;
  final TextStyle code;
  final TextStyle row;
  final TextStyle rowEmphasis;
  final TextStyle muted;
  final TextStyle fieldLabel;
  final TextStyle body;
  final TextStyle bodyEmphasis;
  final TextStyle bodyMuted;
  final TextStyle dialogTitle;
  final TextStyle heading;
  final TextStyle pageTitle;

  const AppTextStyles({
    required this.badge,
    required this.micro,
    required this.caption,
    required this.captionSmall,
    required this.sectionLabel,
    required this.keyCap,
    required this.code,
    required this.row,
    required this.rowEmphasis,
    required this.muted,
    required this.fieldLabel,
    required this.body,
    required this.bodyEmphasis,
    required this.bodyMuted,
    required this.dialogTitle,
    required this.heading,
    required this.pageTitle,
  });

  static const _systemFont = 'system-ui';

  static AppTextStyles forBrightness(Brightness brightness) {
    return AppTextStyles(
      badge: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
        fontFamily: _systemFont,
      ),
      micro: TextStyle(
        fontSize: 10,
        color: AppColors.fgMuted,
        fontStyle: FontStyle.italic,
        fontFamily: _systemFont,
      ),
      caption: TextStyle(
        fontSize: 11,
        height: 1.2,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      captionSmall: TextStyle(
        fontSize: 12,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      sectionLabel: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      keyCap: TextStyle(
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w500,
        color: AppColors.fg,
        fontFamily: 'monospace',
      ),
      code: TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: AppColors.fg,
        fontFamily: 'monospace',
      ),
      row: TextStyle(
        fontSize: 13,
        height: 1.3,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      rowEmphasis: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      muted: TextStyle(
        fontSize: 13,
        height: 1.3,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      fieldLabel: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      body: TextStyle(
        fontSize: 14,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      bodyEmphasis: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      bodyMuted: TextStyle(
        fontSize: 14,
        color: AppColors.fgMuted,
        fontFamily: _systemFont,
      ),
      dialogTitle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      heading: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
      pageTitle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.fg,
        fontFamily: _systemFont,
      ),
    );
  }

  @override
  AppTextStyles copyWith({
    TextStyle? badge,
    TextStyle? micro,
    TextStyle? caption,
    TextStyle? captionSmall,
    TextStyle? sectionLabel,
    TextStyle? keyCap,
    TextStyle? code,
    TextStyle? row,
    TextStyle? rowEmphasis,
    TextStyle? muted,
    TextStyle? fieldLabel,
    TextStyle? body,
    TextStyle? bodyEmphasis,
    TextStyle? bodyMuted,
    TextStyle? dialogTitle,
    TextStyle? heading,
    TextStyle? pageTitle,
  }) {
    return AppTextStyles(
      badge: badge ?? this.badge,
      micro: micro ?? this.micro,
      caption: caption ?? this.caption,
      captionSmall: captionSmall ?? this.captionSmall,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      keyCap: keyCap ?? this.keyCap,
      code: code ?? this.code,
      row: row ?? this.row,
      rowEmphasis: rowEmphasis ?? this.rowEmphasis,
      muted: muted ?? this.muted,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      body: body ?? this.body,
      bodyEmphasis: bodyEmphasis ?? this.bodyEmphasis,
      bodyMuted: bodyMuted ?? this.bodyMuted,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      heading: heading ?? this.heading,
      pageTitle: pageTitle ?? this.pageTitle,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      badge: TextStyle.lerp(badge, other.badge, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      captionSmall: TextStyle.lerp(captionSmall, other.captionSmall, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      keyCap: TextStyle.lerp(keyCap, other.keyCap, t)!,
      code: TextStyle.lerp(code, other.code, t)!,
      row: TextStyle.lerp(row, other.row, t)!,
      rowEmphasis: TextStyle.lerp(rowEmphasis, other.rowEmphasis, t)!,
      muted: TextStyle.lerp(muted, other.muted, t)!,
      fieldLabel: TextStyle.lerp(fieldLabel, other.fieldLabel, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyEmphasis: TextStyle.lerp(bodyEmphasis, other.bodyEmphasis, t)!,
      bodyMuted: TextStyle.lerp(bodyMuted, other.bodyMuted, t)!,
      dialogTitle: TextStyle.lerp(dialogTitle, other.dialogTitle, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t)!,
    );
  }
}

extension AppTextStylesGetter on BuildContext {
  AppTextStyles get txt => Theme.of(this).extension<AppTextStyles>()!;
}
