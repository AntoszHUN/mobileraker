// Generic AsyncValueWidget to work with values of type T
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/logger.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget(
      {Key? key,
      required this.value,
      required this.data,
      this.skipLoadingOnRefresh = false,
      this.skipLoadingOnReload = false})
      : super(key: key);

  // input async value
  final AsyncValue<T> value;

  // output builder function
  final Widget Function(T) data;

  final bool skipLoadingOnRefresh;
  final bool skipLoadingOnReload;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: this.skipLoadingOnRefresh,
      skipLoadingOnReload: this.skipLoadingOnReload,
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        logger.e('Error in Widget', e, StackTrace.current);
        throw e;
      },
    );
  }
}
