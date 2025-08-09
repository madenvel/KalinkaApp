import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValueX,
        ConsumerWidget,
        StateNotifier,
        StateNotifierProvider,
        WidgetRef;
import 'package:kalinka/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/preview_section.dart';
import 'package:kalinka/source_attribution.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;

class SourceCollapseStateNotifier extends StateNotifier<Map<String, bool>> {
  SharedPreferencesWithCache? prefs;
  bool _isInitialized = false;

  SourceCollapseStateNotifier() : super({}) {
    _initializeState();
  }

  static const String kCollapsedKey = 'Kalinka.input_source.collapsed';

  Future<void> _initializeState() async {
    if (_isInitialized) return;

    try {
      prefs = await SharedPreferencesWithCache.create(
          cacheOptions: SharedPreferencesWithCacheOptions(allowList: {
        kCollapsedKey,
      }));

      final collapsedStateString = prefs?.getString(kCollapsedKey);
      if (collapsedStateString != null && collapsedStateString.isNotEmpty) {
        // Parse the stored JSON-like string back to Map<String, bool>
        final Map<String, String> queryParams =
            Uri.splitQueryString(collapsedStateString);
        final Map<String, bool> collapsedStateMap = queryParams
            .map((key, value) => MapEntry(key, value.toLowerCase() == 'true'));
        state = Map<String, bool>.from(collapsedStateMap);
      }

      _isInitialized = true;
    } catch (e) {
      // If there's an error reading from shared prefs, just use empty state
      _isInitialized = true;
    }
  }

  Future<void> _saveState() async {
    if (!_isInitialized || prefs == null) return;

    try {
      // Convert Map<String, bool> to a query string format for storage
      final String stateString = state.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${entry.value}')
          .join('&');
      await prefs!.setString(kCollapsedKey, stateString);
    } catch (e) {
      // Handle save errors gracefully
    }
  }

  Future<void> toggleCollapse(String sourceId) async {
    // Ensure initialization is complete before toggling
    await _initializeState();

    state = {
      ...state,
      sourceId: !(state[sourceId] ?? false),
    };

    // Save state after updating
    await _saveState();
  }

  bool isCollapsed(String sourceId) {
    return state[sourceId] ?? false;
  }
}

// Provider for managing collapsed states of source modules
final sourceCollapseStateProvider =
    StateNotifierProvider<SourceCollapseStateNotifier, Map<String, bool>>(
        (ref) {
  return SourceCollapseStateNotifier();
});

class SourceModule extends ConsumerWidget {
  final BrowseItem source;
  final VoidCallback? onShowMoreClicked;

  const SourceModule({super.key, required this.source, this.onShowMoreClicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapseState = ref.watch(sourceCollapseStateProvider);
    final isCollapsed = collapseState[source.id] ?? false;
    final desc = DefaultBrowseItemsSourceDesc(source);
    final asyncState = ref.watch(browseItemsProvider(desc));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildTitleBar(context, ref, isCollapsed),
          if (!isCollapsed)
            asyncState.when(
              data: (state) => _buildExpandedContent(context, ref, state, desc),
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading ${source.name}: $error',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, WidgetRef ref, bool isCollapsed) {
    return ListTile(
      leading: SourceAttribution(id: source.id, size: 36.0),
      title: Text(
        source.name ?? 'Unknown Source',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: source.catalog?.description != null
          ? Text(source.catalog!.description!)
          : null,
      trailing: IconButton(
        icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
        onPressed: () async {
          await ref
              .read(sourceCollapseStateProvider.notifier)
              .toggleCollapse(source.id);
        },
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, WidgetRef ref,
      BrowseItemsState state, BrowseItemsSourceDesc desc) {
    if (state.totalCount == 0) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No content available'),
      );
    }

    return Column(
      children: [
        ...List.generate(min(state.totalCount, 3), (index) {
          final item = state.getItem(index);
          if (item == null) {
            Future.microtask(() => ref
                .read(browseItemsProvider(desc).notifier)
                .ensureIndexLoaded(index));
            return PreviewSectionPlaceholder(browseItem: desc.sourceItem);
          }
          return PreviewSection(
            sourceDesc: DefaultBrowseItemsSourceDesc(item.copyWith(
              catalog: item.catalog?.copyWith(
                previewConfig: item.catalog?.previewConfig?.copyWith(
                  rowsCount: 1, // Force single row for grid preview
                ),
              ),
            )),
          );
        }),
        if (state.totalCount > 3) _buildShowMoreButton(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShowMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
          vertical: KalinkaConstants.kContentVerticalPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onShowMoreClicked,
          icon: const Icon(Icons.arrow_forward),
          label: Text('Show more from ${source.name}'),
        ),
      ),
    );
  }
}
