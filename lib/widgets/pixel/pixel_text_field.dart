import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Trường nhập pixel: nhãn nằm trên field, lỗi hiển thị inline ngay dưới field.
///
/// Dùng `TextFormField` để `validator` hoạt động bên trong `Form`.
class PixelTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final String? suffixGlyph;
  final VoidCallback? onSuffixTap;
  final bool obscureToggle;

  const PixelTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.suffixGlyph,
    this.onSuffixTap,
    this.obscureToggle = false,
  });

  @override
  State<PixelTextField> createState() => _PixelTextFieldState();
}

class _PixelTextFieldState extends State<PixelTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    Widget? suffix;
    if (widget.obscureToggle) {
      suffix = IconButton(
        key: const ValueKey('pixel-obscure-toggle'),
        tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        onPressed: () => setState(() => _hidden = !_hidden),
        iconSize: 20,
        icon: AppIcon(
          name: _hidden ? 'eye' : 'eyeOff',
          size: 20,
          color: palette.inkMuted,
        ),
      );
    } else if (widget.suffixGlyph != null) {
      suffix = IconButton(
        onPressed: widget.onSuffixTap,
        iconSize: 16,
        icon: AppIcon(name: widget.suffixGlyph!, size: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: text.labelLarge?.copyWith(color: palette.ink),
        ),
        const SizedBox(height: 6),
        Semantics(
          textField: true,
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            maxLines: widget.obscureToggle ? 1 : widget.maxLines,
            obscureText: widget.obscureToggle && _hidden,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            textCapitalization: widget.textCapitalization,
            style: text.bodyLarge,
            cursorColor: palette.mintInk,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              helperText: widget.helperText,
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ),
        // errorText của TextFormField đã hiển thị inline; live region giúp
        // screen reader đọc lại khi lỗi xuất hiện sau khi submit.
        if (widget.errorText != null)
          Semantics(
            liveRegion: true,
            label: 'Có lỗi dữ liệu',
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
