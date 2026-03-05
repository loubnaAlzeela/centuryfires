import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/app_error_type.dart';

class ErrorState extends StatelessWidget {
  final AppErrorType type;

  const ErrorState({super.key, this.type = AppErrorType.general});

  String _message(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
        return 'Please check your internet connection.';
      case AppErrorType.unauthorized:
        return 'You are not authorized to perform this action.';
      case AppErrorType.notFound:
        return 'Requested data not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _message(context),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGrey(context), fontSize: 14),
        ),
      ),
    );
  }
}
