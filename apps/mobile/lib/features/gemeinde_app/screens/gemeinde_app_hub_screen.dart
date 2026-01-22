import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../events/services/events_service.dart';
import '../../news/screens/news_screen.dart';
import '../../news/services/news_service.dart';
import '../../posts/models/post.dart';
import '../../posts/screens/posts_screen.dart';
import '../../posts/services/posts_service.dart';

class GemeindeAppHubScreen extends StatelessWidget {
  const GemeindeAppHubScreen({
    super.key,
    required this.eventsService,
    required this.newsService,
    this.postsService,
  });

  final EventsService eventsService;
  final NewsService newsService;
  final PostsService? postsService;

  @override
  Widget build(BuildContext context) {
    final postsService = this.postsService ?? PostsService();
    final items = [
      _HubItem(
        title: 'Events',
        icon: Icons.event,
        onTap: () {
          AppRouterScope.of(context).push(
            EventsScreen(eventsService: eventsService),
          );
        },
      ),
      _HubItem(
        title: 'Online Flohmarkt',
        icon: Icons.storefront,
        onTap: () => _openPosts(
          context,
          category: PostCategory.flohmarkt,
          postsService: postsService,
        ),
      ),
      _HubItem(
        title: 'Umzug/Entrümpelung',
        icon: Icons.local_shipping,
        onTap: () => _openPosts(
          context,
          category: PostCategory.umzugEntruempelung,
          postsService: postsService,
        ),
      ),
      _HubItem(
        title: 'Senioren Hilfe',
        icon: Icons.volunteer_activism,
        onTap: () => _openPosts(
          context,
          category: PostCategory.seniorenHilfe,
          postsService: postsService,
        ),
      ),
      _HubItem(
        title: 'Café Treff',
        icon: Icons.local_cafe,
        onTap: () => _openPosts(
          context,
          category: PostCategory.cafeTreff,
          postsService: postsService,
        ),
      ),
      _HubItem(
        title: 'Kinderspielen (3j-5j)',
        icon: Icons.child_friendly,
        onTap: () => _openPosts(
          context,
          category: PostCategory.kinderSpielen,
          postsService: postsService,
        ),
      ),
      _HubItem(
        title: 'News / Aktuelles in der Umgebung',
        icon: Icons.newspaper,
        onTap: () {
          AppRouterScope.of(context).push(
            NewsScreen(newsService: newsService),
          );
        },
      ),
      _HubItem(
        title: 'Warnungen',
        icon: Icons.warning_amber,
        onTap: () => _openPlaceholder(
          context,
          title: 'Warnungen',
          description: 'Warnmeldungen werden hier angezeigt.',
        ),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _HubTile(item: item);
      },
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    AppRouterScope.of(context).push(
      PlaceholderScreen(title: title, description: description),
    );
  }

  void _openPosts(
    BuildContext context, {
    required PostCategory category,
    required PostsService postsService,
  }) {
    AppRouterScope.of(context).push(
      PostsScreen(
        category: category,
        postsService: postsService,
      ),
    );
  }
}

class _HubItem {
  const _HubItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.item});

  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
