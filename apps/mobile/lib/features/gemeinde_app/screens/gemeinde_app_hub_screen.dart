import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/tenant/tenant_settings_scope.dart';
import '../../citizen_posts/models/citizen_post.dart';
import '../../citizen_posts/screens/citizen_posts_list_screen.dart';
import 'category_sub_hub_screen.dart';

class GemeindeAppHubScreen extends StatelessWidget {
  const GemeindeAppHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = TenantSettingsScope.of(context);
    final items = <_HubItem>[];

    final meetingTypes = <CitizenPostType>[];
    final meetingTiles = <CategorySubTile>[];
    final meetingCreateOptions = <CategoryCreateOption>[];
    if (settingsStore.isFeatureEnabled('places')) {
      meetingTypes.add(CitizenPostType.cafeMeetup);
      meetingTiles.add(
        _categoryTile(
          context,
          title: 'Café-Treffen',
          icon: Icons.local_cafe,
          type: CitizenPostType.cafeMeetup,
        ),
      );
      meetingCreateOptions.add(
        const CategoryCreateOption(
          'Café-Treffen',
          CitizenPostType.cafeMeetup,
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('clubs')) {
      meetingTypes.add(CitizenPostType.kidsMeetup);
      meetingTiles.add(
        _categoryTile(
          context,
          title: 'Kinder-Treffen',
          icon: Icons.child_care,
          type: CitizenPostType.kidsMeetup,
        ),
      );
      meetingCreateOptions.add(
        const CategoryCreateOption(
          'Kinder-Treffen',
          CitizenPostType.kidsMeetup,
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('services')) {
      items.addAll([
        _HubItem(
          title: 'Beiträge & Markt',
          icon: Icons.storefront,
          onTap: () => _openCategory(
            context,
            CategorySubHubScreen(
              title: 'Beiträge & Markt',
              types: const [
                CitizenPostType.userPost,
                CitizenPostType.marketplace,
                CitizenPostType.giveaway,
                CitizenPostType.skillExchange,
              ],
              subTiles: [
                _categoryTile(
                  context,
                  title: 'Freier Beitrag',
                  icon: Icons.chat_bubble_outline,
                  type: CitizenPostType.userPost,
                ),
                _categoryTile(
                  context,
                  title: 'Marktplatz',
                  icon: Icons.storefront,
                  type: CitizenPostType.marketplace,
                ),
                _categoryTile(
                  context,
                  title: 'Verschenken',
                  icon: Icons.card_giftcard,
                  type: CitizenPostType.giveaway,
                ),
                _categoryTile(
                  context,
                  title: 'Talentbörse',
                  icon: Icons.handshake_outlined,
                  type: CitizenPostType.skillExchange,
                ),
              ],
              filterTypes: const [
                CitizenPostType.userPost,
                CitizenPostType.marketplace,
                CitizenPostType.giveaway,
                CitizenPostType.skillExchange,
              ],
              createOptions: const [
                CategoryCreateOption(
                  'Marktplatz',
                  CitizenPostType.marketplace,
                ),
                CategoryCreateOption(
                  'Verschenken',
                  CitizenPostType.giveaway,
                ),
                CategoryCreateOption(
                  'Talentbörse',
                  CitizenPostType.skillExchange,
                ),
              ],
            ),
          ),
        ),
        _HubItem(
          title: 'Hilfe & Ehrenamt',
          icon: Icons.volunteer_activism,
          onTap: () => _openCategory(
            context,
            CategorySubHubScreen(
              title: 'Hilfe & Ehrenamt',
              types: const [
                CitizenPostType.help,
                CitizenPostType.volunteering,
              ],
              subTiles: [
                _categoryTile(
                  context,
                  title: 'Hilfegesuch',
                  icon: Icons.help_outline,
                  type: CitizenPostType.help,
                ),
                _categoryTile(
                  context,
                  title: 'Hilfe anbieten',
                  icon: Icons.support_agent,
                  type: CitizenPostType.help,
                ),
                _categoryTile(
                  context,
                  title: 'Ehrenamt',
                  icon: Icons.volunteer_activism,
                  type: CitizenPostType.volunteering,
                ),
              ],
              filterTypes: const [
                CitizenPostType.help,
                CitizenPostType.volunteering,
              ],
              createOptions: const [
                CategoryCreateOption(
                  'Hilfe anbieten',
                  CitizenPostType.help,
                ),
                CategoryCreateOption(
                  'Ehrenamt',
                  CitizenPostType.volunteering,
                ),
              ],
            ),
          ),
        ),
        _HubItem(
          title: 'Treffen',
          icon: Icons.local_cafe,
          onTap: () => _openCategory(
            context,
            CategorySubHubScreen(
              title: 'Treffen',
              types: meetingTypes,
              subTiles: meetingTiles,
              filterTypes: meetingTypes,
              createOptions: meetingCreateOptions,
            ),
          ),
        ),
        _HubItem(
          title: 'Mobilität',
          icon: Icons.directions_car,
          onTap: () => _openCategory(
            context,
            CategorySubHubScreen(
              title: 'Mobilität',
              types: const [CitizenPostType.rideSharing],
              subTiles: [
                _categoryTile(
                  context,
                  title: 'Mitfahrgelegenheit',
                  icon: Icons.directions_car,
                  type: CitizenPostType.rideSharing,
                ),
              ],
              filterTypes: const [CitizenPostType.rideSharing],
              createOptions: const [
                CategoryCreateOption(
                  'Mitfahrgelegenheit',
                  CitizenPostType.rideSharing,
                ),
              ],
            ),
          ),
        ),
        _HubItem(
          title: 'Wohnen & Umzug',
          icon: Icons.local_shipping,
          onTap: () => _openCategory(
            context,
            CategorySubHubScreen(
              title: 'Wohnen & Umzug',
              types: const [CitizenPostType.movingClearance],
              subTiles: [
                _categoryTile(
                  context,
                  title: 'Umzug / Entrümpelung',
                  icon: Icons.local_shipping,
                  type: CitizenPostType.movingClearance,
                ),
              ],
              filterTypes: const [CitizenPostType.movingClearance],
              createOptions: const [
                CategoryCreateOption(
                  'Umzug / Entrümpelung',
                  CitizenPostType.movingClearance,
                ),
              ],
              extraActions: [
                CategorySubAction(
                  label: 'Suchen / Filter',
                  subtitle: 'Weitere Wohnangebote und Gesuche filtern.',
                  icon: Icons.search,
                  onTap: () => _openAllWithFilters(
                    context,
                    title: 'Wohnen & Umzug',
                    types: const [CitizenPostType.movingClearance],
                    filterTypes: const [
                      CitizenPostType.movingClearance,
                      CitizenPostType.apartmentSearch,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
    }
    if (meetingTypes.isEmpty) {
      items.removeWhere((item) => item.title == 'Treffen');
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('Für diese Gemeinde sind keine Module aktiviert.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
        return CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: 'GemeindeApp',
                  subtitle: 'Services und Beiträge aus deiner Gemeinde.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _HubTile(item: item);
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCategory(BuildContext context, CategorySubHubScreen screen) {
    AppRouterScope.of(context).push(screen);
  }

  CategorySubTile _categoryTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required CitizenPostType type,
  }) {
    return CategorySubTile(
      title: title,
      icon: icon,
      type: type,
      onTap: () {
        AppRouterScope.of(context).push(
          CitizenPostsListScreen(
            title: title,
            types: [type],
            postsService: AppServicesScope.of(context).citizenPostsService,
          ),
        );
      },
    );
  }

  void _openAllWithFilters(
    BuildContext context, {
    required String title,
    required List<CitizenPostType> types,
    required List<CitizenPostType> filterTypes,
  }) {
    AppRouterScope.of(context).push(
      CitizenPostsListScreen(
        title: title,
        types: types,
        filterTypes: filterTypes,
        postsService: AppServicesScope.of(context).citizenPostsService,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
