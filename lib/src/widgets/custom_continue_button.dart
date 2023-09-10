import 'package:flutter/material.dart';

class CustomContinueButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final bool isDisabled;
  final bool isLoading;
  final TextStyle? style;

  const CustomContinueButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.isDisabled = false,
    this.isLoading = false,
    this.style,
    this.padding = const EdgeInsets.all(10),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size(300, 60),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: padding,
      ),
      onPressed: () {
        if (isDisabled) return;
        onTap();
      },
      child: isLoading
          ? const CircularProgressIndicator()
          : Text(
              title,
              style: style ??
                  Theme.of(context).textTheme.headline6?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30),
            ),
    );
  }
}
