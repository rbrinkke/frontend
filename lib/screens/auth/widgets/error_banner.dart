import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String? error;

  const ErrorBanner({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: error != null
          ? Material(
              color: Colors.redAccent,
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
