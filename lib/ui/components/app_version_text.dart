/*
 * Copyright (c) 2023. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/util/extensions/object_extension.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/ui/screens/setting/setting_controller.dart';

class AppVersionText extends ConsumerWidget {
  const AppVersionText({Key? key, this.prefix, this.textStyle}) : super(key: key);

  final String? prefix;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var version = ref.watch(versionInfoProvider).maybeWhen(
          orElse: () => 'unavailable',
          data: (d) => '${d.version}-${d.buildNumber}',
        );

    return Text(
      prefix?.let((it) => '$it $version') ?? version,
      style: textStyle ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}
