import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/action_button.dart' show ActionButton;
import 'package:kalinka/browse_item_actions.dart' show BrowseItemActions;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart'
    show BrowseItemsSourceDesc, BrowseItemsState, browseItemsProvider;
import 'package:kalinka/constants.dart' show KalinkaConstants;
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/data_model.dart';
import 'package:kalinka/shimmer_effect.dart' show Shimmer;
import 'package:kalinka/providers/url_resolver.dart';

class HeroTile extends ConsumerStatefulWidget {
  final BrowseItemsSourceDesc sourceDesc;
  final void Function(BrowseItem)? onTap;
  final CardSize cardSize;

  const HeroTile({
    super.key,
    required this.sourceDesc,
    this.onTap,
    this.cardSize = CardSize.small,
  });

  @override
  ConsumerState<HeroTile> createState() => _HeroTileState();
}

class _HeroTileState extends ConsumerState<HeroTile> {
  PageController? _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  bool _isScrollingForward = true; // Track scroll direction

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (itemCount <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController?.hasClients == true) {
        // Determine next index based on direction
        if (_isScrollingForward) {
          if (_currentIndex < itemCount - 1) {
            _currentIndex++;
          } else {
            // Reached the end, start going backwards
            _isScrollingForward = false;
            _currentIndex--;
          }
        } else {
          if (_currentIndex > 0) {
            _currentIndex--;
          } else {
            // Reached the beginning, start going forwards
            _isScrollingForward = true;
            _currentIndex++;
          }
        }

        _pageController?.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _restartAutoScroll(int itemCount) {
    // Determine appropriate direction based on current position
    if (_currentIndex == 0) {
      _isScrollingForward = true;
    } else if (_currentIndex == itemCount - 1) {
      _isScrollingForward = false;
    }
    // If we're in the middle, keep current direction
    _startAutoScroll(itemCount);
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(browseItemsProvider(widget.sourceDesc));
    final state = asyncValue.valueOrNull;

    if (state == null || asyncValue.isLoading) {
      return const SizedBox.shrink();
    }

    final browseItem = widget.sourceDesc.sourceItem;
    final aspectRatio = 1.0;
    final cardSize = calculateCardSize(
        context, browseItem.catalog?.previewConfig?.cardSize ?? CardSize.small);

    final imageSize = Size(cardSize, cardSize / aspectRatio);
    final widgetHeight =
        imageSize.height - KalinkaConstants.kContentVerticalPadding;

    if (state.totalCount == 0) {
      return _buildEmptyState(context, state, widgetHeight);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
        vertical: KalinkaConstants.kContentVerticalPadding,
      ),
      child: Container(
        height: widgetHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildCarousel(context, state, imageSize),
        ),
      ),
    );
  }

  Widget _buildCarousel(
      BuildContext context, BrowseItemsState state, Size imageSize) {
    final sourceItem = widget.sourceDesc.sourceItem;
    final itemCount = state.totalCount
        .clamp(0, sourceItem.catalog?.previewConfig?.itemsCount ?? 5);

    final notifier = ref.read(browseItemsProvider(widget.sourceDesc).notifier);

    assert(itemCount > 0, 'Item count must be greater than 0');

    // Start auto-scroll when we have items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll(itemCount);
    });

    return GestureDetector(
      onPanStart: (_) => _stopAutoScroll(),
      onPanEnd: (_) => _restartAutoScroll(itemCount),
      child: PageView.builder(
        controller: _pageController,
        itemCount: itemCount,
        onPageChanged: (index) {
          setState(() {
            // Update direction based on manual page change
            if (index > _currentIndex) {
              _isScrollingForward = true;
            } else if (index < _currentIndex) {
              _isScrollingForward = false;
            }
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final item = state.getItem(index);

          if (item == null) {
            Future.microtask(() => notifier.ensureIndexLoaded(index));
          }

          if (item == null || item.image?.large == null) {
            return HeroTilePlaceholder(browseItem: sourceItem);
          }

          return CachedNetworkImage(
            imageUrl: ref.read(urlResolverProvider).abs(item.image!.large!),
            imageBuilder: (context, imageProvider) =>
                _buildCarouselItem(context, item, imageProvider, imageSize),
            fit: BoxFit.contain,
            cacheManager: KalinkaMusicCacheManager.instance,
            placeholder: (context, url) =>
                HeroTilePlaceholder(browseItem: sourceItem),
            errorWidget: (context, url, error) =>
                HeroTilePlaceholder(browseItem: sourceItem),
          );
        },
      ),
    );
  }

  Widget _buildCarouselItem(BuildContext context, BrowseItem item,
      ImageProvider imageProvider, Size imageSize) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHigh,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Row(
        children: [
          // Left side: Image container (33% width max)
          Container(
            height: imageSize.height,
            width: imageSize.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Right side: Content (67% width)
          _buildCardTextContent(context, item),
        ],
      ),
    );
  }

  Widget _buildCardTextContent(BuildContext context, BrowseItem item) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: KalinkaConstants.kContentHorizontalPadding,
            vertical: KalinkaConstants.kContentVerticalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and subtitle section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name ?? 'Unknown',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subname != null || item.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.subname ?? item.description ?? '',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons section
            const SizedBox(height: 12),
            Row(
              children: [
                _buildEnqueueButton(context, item),
                const Spacer(),
                _buildPlayButton(context, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, BrowseItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      icon:
          Icon(Icons.play_arrow_rounded, size: 36, color: colorScheme.surface),
      onPressed: () => BrowseItemActions.replaceAndPlay(context, ref, item, 0),
      style: IconButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.surface,
          shadowColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
          elevation: 2,
          padding: const EdgeInsets.all(8),
          fixedSize: const Size(56, 56)),
      tooltip: 'Play',
    );
  }

  Widget _buildEnqueueButton(BuildContext context, BrowseItem item) {
    return ActionButton(
      onPressed: () {
        BrowseItemActions.addToQueueAction(context, ref, item);
      },
      icon: Icons.queue_music_rounded,
      tooltip: 'Enqueue',
    );
  }

  Widget _buildEmptyState(
      BuildContext context, BrowseItemsState state, double widgetHeight) {
    final browseItem = widget.sourceDesc.sourceItem;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: widgetHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No items available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (browseItem.name != null) ...[
                const SizedBox(height: 4),
                Text(
                  browseItem.name!,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

double calculateCardSize(BuildContext context, CardSize cardSizeSelection) {
  final size = MediaQuery.sizeOf(context) +
      Offset(
          -2 *
              (KalinkaConstants.kScreenContentHorizontalPadding -
                  KalinkaConstants.kSpaceBetweenTiles),
          0);
  final double screenCardSizeRatio =
      cardSizeSelection == CardSize.large ? 2.0 : 2.5;
  final double cardSize = (size.shortestSide / screenCardSizeRatio)
      .clamp(300 / screenCardSizeRatio, 500 / screenCardSizeRatio);
  return cardSize;
}

class HeroTilePlaceholder extends StatelessWidget {
  final BrowseItem browseItem;
  const HeroTilePlaceholder({super.key, required this.browseItem});

  @override
  Widget build(BuildContext context) {
    final aspectRatio = 1.0;
    final cardSize = calculateCardSize(
        context, browseItem.catalog?.previewConfig?.cardSize ?? CardSize.small);

    final imageSize = Size(cardSize, cardSize / aspectRatio);
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlightColor = Theme.of(context).colorScheme.surfaceBright;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
      ),
      child: Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            // Left side: Image placeholder
            Container(
              width: imageSize.width,
              height: imageSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: baseColor.withValues(alpha: 0.5),
              ),
            ),

            // Right side: Content placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: KalinkaConstants.kContentHorizontalPadding,
                    vertical: KalinkaConstants.kContentVerticalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and subtitle section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title placeholder
                          Container(
                            height: 18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: baseColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle placeholder
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: baseColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons section
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Play button placeholder
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: baseColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        // Enqueue button placeholder
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: baseColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
