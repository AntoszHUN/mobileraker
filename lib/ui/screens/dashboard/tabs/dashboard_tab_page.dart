/*
 * Copyright (c) 2024. Patrick Schmidt.
 * All rights reserved.
 */

// ignore_for_file: avoid-passing-async-when-sync-expected

import 'dart:ui';

import 'package:common/data/model/hive/dashboard_component.dart';
import 'package:common/data/model/hive/dashboard_tab.dart';
import 'package:common/service/payment_service.dart';
import 'package:common/ui/components/supporter_only_feature.dart';
import 'package:common/ui/components/warning_card.dart';
import 'package:common/ui/theme/theme_pack.dart';
import 'package:common/util/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../components/dashboard_card.dart';
import '../../../components/pull_to_refresh_printer.dart';

class DashboardTabPage extends ConsumerStatefulWidget {
  const DashboardTabPage({
    super.key,
    required this.machineUUID,
    required this.tab,
    this.staticWidgets = const [],
    this.isEditing = false,
    this.onReorder,
    this.onAddComponent,
    this.onRemoveComponent,
    this.onRemove,
    required this.onRequestedEdit,
  }) : assert(
            !isEditing || onReorder != null && onAddComponent != null && onRemoveComponent != null && onRemove != null,
            'If editing is enabled, all callbacks must be provided');

  final String machineUUID;

  final DashboardTab tab;

  final bool isEditing;

  final List<Widget> staticWidgets;

  /// Callback when a component of the tab should be reordered
  final void Function(DashboardTab tab, int oldIndex, int newIndex)? onReorder;

  /// Callback when the add widget button is pressed
  final void Function(DashboardTab tab)? onAddComponent;

  /// Callback when a component of the tab should be removed
  final void Function(DashboardTab tab, DashboardComponent component)? onRemoveComponent;

  /// Callback when the tab should be removed
  final void Function(DashboardTab tab)? onRemove;

  final void Function() onRequestedEdit;

  @override
  ConsumerState<DashboardTabPage> createState() => DashboardTabPageState();
}

class DashboardTabPageState extends ConsumerState<DashboardTabPage> {
  @override
  Widget build(BuildContext context) {
    logger.i('Rebuilding tab card page for ${widget.tab.name} (${widget.tab.uuid})');

    final components = widget.tab.components;

    // final childs = components.mapIndex(_buildCard).toList();

    var scroll = CustomScrollView(
      key: PageStorageKey<String>(widget.tab.uuid),
      slivers: <Widget>[
        if (widget.isEditing)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: WarningCard(
                leadingIcon: const Icon(Icons.dashboard_customize),
                margin: EdgeInsets.zero,
                title: const Text('pages.customizing_dashboard.editing_card.title').tr(),
                subtitle: const Text('pages.customizing_dashboard.editing_card.body').tr(),
              ),
            ),
          ),
        if (widget.isEditing && !ref.watch(isSupporterProvider))
          SliverPadding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            sliver: SliverToBoxAdapter(
              child: WarningCard(
                margin: EdgeInsets.zero,
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SupporterOnlyFeature(
                    text: const Text('components.supporter_only_feature.custom_dashboard').tr(),
                  ),
                ),
              ),
            ),
          ),
        if (!widget.isEditing) ...[
          SliverList.list(children: widget.staticWidgets),
          SliverList.builder(
            itemBuilder: (BuildContext context, int index) {
              // return childs[index];
              final component = components[index];

              return KeyedSubtree(
                key: ValueKey('$index-not-editing'),
                //TODO: It might be beneficial to move the GeastureHandler to the actual card widget...
                child: GestureDetector(
                  onLongPress: widget.onRequestedEdit,
                  child: DasboardCard(type: component.type, machineUUID: widget.machineUUID),
                ),
              );
            },
            itemCount: components.length,
          ),
        ],
        if (widget.isEditing)
          SliverReorderableList(
            onReorderStart: _onReorderStart,
            onReorderEnd: _onReorderEnd,
            onReorder: (oldIndex, newIndex) {
              if (!widget.isEditing) return;
              widget.onReorder!(widget.tab, oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              logger.i('Proxy Decorator: $index, $animation, $child#${identityHashCode(child)}');
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext ctx, Widget? c) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(1, 0.85, animValue)!;
                  return Transform.scale(scale: elevation, child: c);
                },
                child: child,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              // return childs[index];
              final component = components[index];

              return _CardWhileEditing(
                key: ValueKey('$index-editing'),
                index: index,
                child: DasboardCard.preview(type: component.type),
                onRemovedTap: () {
                  widget.onRemoveComponent!(widget.tab, widget.tab.components[index]);
                },
              );
            },
            itemCount: components.length,
          ),
        if (widget.isEditing)
          SliverPadding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 40),
            sliver: SliverToBoxAdapter(
              child: _EditingSuffix(
                onAddComponent: () => widget.onAddComponent!(widget.tab),
                onRemoveComponent: () => widget.onRemove!(widget.tab),
              ),
            ),
          ),
      ],
    );

    if (widget.isEditing) {
      return scroll;
    }

    // Only offer pull to refresh when not editing
    return PullToRefreshPrinter(child: scroll);
  }

  Widget _buildCard(DashboardComponent component, int index) {
    if (widget.isEditing) {
      return _CardWhileEditing(
        key: ValueKey('$index-editing'),
        index: index,
        child: DasboardCard.preview(type: component.type),
        onRemovedTap: () {
          widget.onRemoveComponent!(widget.tab, widget.tab.components[index]);
        },
      );
    }

    return KeyedSubtree(
      key: ValueKey('$index-not-editing'),
      //TODO: It might be beneficial to move the GeastureHandler to the actual card widget...
      child: GestureDetector(
        onLongPress: widget.onRequestedEdit,
        child: DasboardCard(type: component.type, machineUUID: widget.machineUUID),
      ),
    );
  }

  void _onReorderStart(int index) {
    logger.i('Reorder Start: $index');
    // _selectedIndex = index;
  }

  void _onReorderEnd(int newIndex) {
    logger.i('Reorder End: $newIndex');
    // _selectedIndex = null;
  }
}

class _EditingSuffix extends StatelessWidget {
  const _EditingSuffix({
    super.key,
    required this.onAddComponent,
    required this.onRemoveComponent,
  });

  final void Function() onAddComponent;
  final void Function() onRemoveComponent;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onAddComponent,
          child: Container(
            // width: MediaQuery.sizeOf(context).width - 32,
            height: 128,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: themeData.colorScheme.primaryContainer.withOpacity(0.25),
              border: Border.all(color: themeData.colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.add),
                const SizedBox(width: 8.0),
                const Text('pages.customizing_dashboard.add_card').tr(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: <Widget>[
            //     FilledButton(onPressed: () => null, child: const Text('<<')),
            //     FilledButton(onPressed: () => null, child: const Text('>>')),
            //   ],
            // ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: themeData.extension<CustomColors>()!.danger,
                foregroundColor: themeData.extension<CustomColors>()!.onDanger,
              ),
              onPressed: onRemoveComponent,
              child: const Text('pages.customizing_dashboard.remove_page').tr(),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardWhileEditing extends HookWidget {
  const _CardWhileEditing({
    super.key,
    required this.child,
    required this.index,
    this.onRemovedTap,
    this.onEditTap,
  });

  final Widget child;
  final int index;
  final void Function()? onRemovedTap;
  final void Function()? onEditTap;

  @override
  Widget build(BuildContext context) {
    var tapped = useState(false);
    var animationController = useAnimationController(duration: kThemeAnimationDuration);
    // animationController.forward();

    final ignoreActions = useListenableSelector(animationController, () => animationController.isAnimating);

    var tgt = ReorderableDelayedDragStartListener(
      index: index,
      enabled: !tapped.value,
      child: AbsorbPointer(child: child),
    );

    return GestureDetector(
      onTap: () async {
        if (ignoreActions) return;
        if (tapped.value) {
          await animationController.reverse();
        } else {
          animationController.forward();
        }
        tapped.value = !tapped.value;

        logger.i('Tapped: $index - ${!tapped.value} - ${tapped.value}');
      },
      child: Stack(
        children: [
          tgt,
          if (tapped.value)
            Positioned.fill(
              child: FadeTransition(
                opacity: animationController.drive(CurveTween(curve: Curves.linear)),
                child: Card(
                  color: Colors.black.withOpacity(0.75),
                  // margin: EdgeInsets.all(4.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        //TODO: Add ability to edit indepth details/Card specific settings or something like "Show while printing"...
                        // IconButton(
                        //   onPressed: onEditTap,
                        //   icon: const Icon(Icons.edit),
                        //   iconSize: 45,
                        //   color: Colors.white,
                        // ),
                        // const SizedBox(width: 24.0),
                        IconButton(
                          onPressed: onRemovedTap,
                          icon: const Icon(Icons.delete),
                          iconSize: 45,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
