import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/core/errors/app_exception.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/primary_button.dart';

/// Arabic, student-safe text for any error. Never shows a raw exception.
String friendlyError(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'resource-exhausted') return 'خلصت أسئلتك لليوم، بنكمل بكرة';
    final m = error.message;
    if (m != null && m.isNotEmpty && RegExp(r'[؀-ۿ]').hasMatch(m)) return m;
  }
  if (error is AppException) return error.message;
  return 'صار في مشكلة صغيرة. جرّب كمان مرة';
}

/// One widget for every async state: loading, error with retry, empty, data.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'ما في إشي هون لسا',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    // Keep showing data while a refresh is loading.
    if (value.hasValue && !value.hasError) {
      final d = value.requireValue;
      if (isEmpty?.call(d) ?? false) {
        return StateMessage(icon: emptyIcon, message: emptyMessage);
      }
      return data(d);
    }
    if (value.hasError) {
      return StateMessage(
        icon: Icons.wifi_tethering_error_rounded,
        message: friendlyError(value.error!),
        actionLabel: onRetry == null ? null : 'جرّب كمان مرة',
        onAction: onRetry,
      );
    }
    return const LoadingView();
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
        ),
      );
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: actionLabel!, onPressed: onAction, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
