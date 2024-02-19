/*
 * Copyright (c) 2023-2024. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/model/hive/machine.dart';
import 'package:common/service/app_router.dart';
import 'package:common/service/machine_service.dart';
import 'package:common/service/selected_machine_service.dart';
import 'package:common/service/ui/theme_service.dart';
import 'package:common/util/extensions/async_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'nav_drawer_controller.dart';

const double baseIconSize = 20;
const basePadding = EdgeInsets.only(left: 16, right: 16);

class NavigationDrawerWidget extends ConsumerWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);

    return Drawer(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _NavHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    const _PrinterSelection(),
                    if ((ref.watch(allMachinesProvider.select(
                              (value) => value.valueOrNull?.length,
                            )) ??
                            0) >
                        1) ...[
                      _DrawerItem(
                        text: 'pages.overview.title'.tr(),
                        icon: FlutterIcons.view_dashboard_mco,
                        routeName: '/overview',
                      ),
                      const Divider(),
                    ],
                    _DrawerItem(
                      text: 'pages.dashboard.title'.tr(),
                      icon: FlutterIcons.printer_3d_nozzle_mco,
                      routeName: '/',
                    ),
                    _DrawerItem(
                      text: 'pages.console.title'.tr(),
                      icon: Icons.terminal,
                      routeName: '/console',
                    ),
                    _DrawerItem(
                      text: 'pages.files.title'.tr(),
                      icon: Icons.file_present,
                      routeName: '/files',
                    ),
                    const Divider(),
                    _DrawerItem(
                      text: 'pages.setting.title'.tr(),
                      icon: Icons.engineering_outlined,
                      routeName: '/setting',
                    ),
                    _DrawerItem(
                      text: 'pages.paywall.title'.tr(),
                      icon: FlutterIcons.hand_holding_heart_faw5s,
                      routeName: '/paywall',
                    ),
                    if (kDebugMode) ...[
                      const Divider(),
                      const _DrawerItem(
                        text: 'Spoolman',
                        icon: Icons.local_library,
                        routeName: '/spoolman',
                      ),
                    ],
                    const Divider(),
                    _DrawerItem(
                      text: tr('pages.faq.title'),
                      icon: Icons.help,
                      routeName: '/faq',
                    ),
                    _DrawerItem(
                      text: tr('pages.changelog.title'),
                      icon: Icons.history,
                      routeName: '/changelog',
                    ),
                    if (kDebugMode)
                      const _DrawerItem(
                        text: 'DEV',
                        icon: FlutterIcons.build_mdi,
                        routeName: '/dev',
                      ),
                    const _DrawerItem(
                      text: 'Tools',
                      icon: FlutterIcons.toolbox_faw5s,
                      routeName: '/tool',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: RichText(
              text: TextSpan(
                style: themeData.textTheme.bodySmall!.copyWith(color: themeData.colorScheme.onSurface),
                text: 'components.nav_drawer.footer'.tr(),
                children: [
                  TextSpan(
                    text: ' GitHub ',
                    style: TextStyle(color: themeData.colorScheme.secondary),
                    children: const [
                      WidgetSpan(
                        child: Icon(FlutterIcons.github_alt_faw, size: 18),
                      ),
                    ],
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const String url = 'https://github.com/Clon1998/mobileraker';
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                  ),
                  const TextSpan(text: '\n\n'),
                  TextSpan(
                    text: tr('pages.setting.imprint'),
                    style: TextStyle(color: themeData.colorScheme.secondary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => ref.read(navDrawerControllerProvider.notifier).pushingTo('/imprint'),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  } // Note always the first is the currently selected!
}

class _NavHeader extends ConsumerWidget {
  const _NavHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var themePack = ref.watch(activeThemeProvider).requireValue.themePack;
    var brandingIcon = (themeData.brightness == Brightness.light) ? themePack.brandingIcon : themePack.brandingIconDark;
    var background = (themeData.brightness == Brightness.light)
        ? themeData.colorScheme.primary
        : themeData.colorScheme.primaryContainer;
    var onBackground = (themeData.brightness == Brightness.light)
        ? themeData.colorScheme.onPrimary
        : themeData.colorScheme.onPrimaryContainer;

    var selectedMachine = ref.watch(selectedMachineProvider);
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
      decoration: BoxDecoration(color: background),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (selectedMachine.hasValue && selectedMachine.value != null) {
                ref.read(navDrawerControllerProvider.notifier).pushingTo(
                      '/printer/edit',
                      arguments: selectedMachine.requireValue!,
                    );
              } else {
                ref.read(navDrawerControllerProvider.notifier).pushingTo('/printer/add');
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      (brandingIcon == null)
                          ? SvgPicture.asset(
                              'assets/vector/mr_logo.svg',
                              width: 60,
                              height: 60,
                            )
                          : Image(height: 60, width: 60, image: brandingIcon),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedMachine.valueOrNull?.name ?? 'NO PRINTER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: themeData.textTheme.titleLarge?.copyWith(color: onBackground),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedMachine.valueOrNull?.httpUri.host ?? 'Add printer first',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: themeData.textTheme.titleSmall?.copyWith(color: onBackground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Tooltip(
                    message: 'components.nav_drawer.printer_settings'.tr(),
                    child: Icon(
                      FlutterIcons.settings_mdi,
                      color: onBackground,
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(
              'components.nav_drawer.manage_printers',
              style: TextStyle(color: onBackground),
            ).tr(),
            trailing: AnimatedRotation(
              duration: kThemeAnimationDuration,
              curve: Curves.easeInOutCubic,
              turns: ref.watch(navDrawerControllerProvider) ? 0 : 0.5,
              child: Icon(Icons.expand_less, color: onBackground),
            ),
            onTap: ref.read(navDrawerControllerProvider.notifier).toggleManagePrintersExpanded,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends ConsumerWidget {
  const _DrawerItem({
    required this.text,
    required this.icon,
    required this.routeName,
  });

  final String text;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var selectedTileColor = (themeData.brightness == Brightness.light)
        ? themeData.colorScheme.surfaceVariant
        : themeData.colorScheme.primaryContainer.withOpacity(.1);

    return ListTile(
      selected: ref.watch(goRouterProvider).location == routeName,
      selectedTileColor: selectedTileColor,
      selectedColor: themeData.colorScheme.secondary,
      textColor: themeData.colorScheme.onBackground,
      leading: Icon(icon),
      title: Text(text),
      onTap: () => ref.read(navDrawerControllerProvider.notifier).navigateTo(routeName),
    );
  }
}

class _PrinterSelection extends ConsumerWidget {
  const _PrinterSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var isExpanded = ref.watch(navDrawerControllerProvider);
    var selMachine = ref.watch(selectedMachineProvider);

    return AnimatedSwitcher(
      duration: kThemeAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: (isExpanded)
          ? Column(
              children: [
                if (selMachine.valueOrNull != null) _MachineTile(machine: selMachine.requireValue!, isSelected: true),
                ...ref
                    .watch(allMachinesProvider.selectAs((data) => data.where(
                          (element) => element.uuid != selMachine.valueOrNull?.uuid,
                        )))
                    .maybeWhen(
                      orElse: () => [
                        ListTile(
                          title: FadingText(
                            'components.nav_drawer.fetching_printers'.tr(),
                          ),
                          contentPadding: basePadding,
                        ),
                      ],
                      data: (data) {
                        return List.generate(data.length, (index) {
                          Machine curPS = data.elementAt(index);
                          return _MachineTile(machine: curPS);
                        });
                      },
                    ),
                ListTile(
                  title: const Text('pages.printer_add.title').tr(),
                  contentPadding: basePadding,
                  textColor: themeData.colorScheme.onBackground,
                  iconColor: themeData.colorScheme.onBackground,
                  trailing: const Icon(Icons.add, size: baseIconSize),
                  onTap: () => ref.read(navDrawerControllerProvider.notifier).pushingTo('/printer/add'),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _MachineTile extends ConsumerWidget {
  const _MachineTile({
    Key? key,
    required this.machine,
    this.isSelected = false,
  }) : super(key: key);

  final Machine machine;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeData = Theme.of(context);
    var selectedTileColor = (themeData.brightness == Brightness.light)
        ? themeData.colorScheme.surfaceVariant
        : themeData.colorScheme.primaryContainer.withOpacity(.1);

    return ListTile(
      title: Text(machine.name, maxLines: 1),
      trailing: Icon(
        isSelected ? Icons.check : Icons.arrow_forward_ios_sharp,
        size: baseIconSize,
      ),
      selectedTileColor: selectedTileColor,
      selectedColor: themeData.colorScheme.secondary,
      textColor: themeData.colorScheme.onBackground,
      iconColor: themeData.colorScheme.onBackground,
      contentPadding: basePadding,
      selected: isSelected,
      onTap: isSelected
          ? null
          : () {
              Navigator.pop(context);
              ref.read(selectedMachineServiceProvider).selectMachine(machine);
            },
      onLongPress: () => ref.read(navDrawerControllerProvider.notifier).pushingTo('/printer/edit', arguments: machine),
    );
  }
}