import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/app_theme_extension.dart';

class BankTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final String? helperText;
  final String? errorText;

  const BankTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.helperText,
    this.errorText,
  });

  @override
  State<BankTextField> createState() => _BankTextFieldState();
}

class _BankTextFieldState extends State<BankTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            fillColor: bankTheme.inputFill,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
