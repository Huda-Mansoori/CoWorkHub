// Dashboard home: stateless navigation cards; the dashboard owns the selected destination.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class DashboardLink {
  final String title, button;
  final int page, image;
  final bool desk;
  final IconData icon;
  const DashboardLink({
    required this.title,
    required this.button,
    required this.page,
    required this.image,
    required this.desk,
    required this.icon,
  });
}

class DashboardHome extends StatelessWidget {
  final ValueChanged<int> navigate;
  const DashboardHome({super.key, required this.navigate});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final padding = box.maxWidth < 600 ? 20.0 : 32.0;
      final available = box.maxWidth - padding * 2;
      int columns = 1;
      if (available >= 900) {
        columns = 3;
      } else if (available >= 570) {
        columns = 2;
      }
      final width = (available - (columns - 1) * 20) / columns;
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          const PageHeading('Dashboard'),
          const SizedBox(height: 32),
          Text(
            'Welcome to CoWorkHub',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final item in [
                DashboardLink(
                  title: 'Resources',
                  button: 'View resources',
                  page: 1,
                  desk: false,
                  image: 1,
                  icon: Icons.meeting_room_outlined,
                ),
                DashboardLink(
                  title: 'Members',
                  button: 'View members',
                  page: 2,
                  desk: true,
                  image: 2,
                  icon: Icons.people_outline,
                ),
                DashboardLink(
                  title: 'Bookings',
                  button: 'View bookings',
                  page: 5,
                  desk: false,
                  image: 2,
                  icon: Icons.calendar_today_outlined,
                ),
              ])
                SizedBox(
                  width: width,
                  child: Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ResourcePhoto(
                          isDesk: item.desk,
                          id: item.image,
                          height: 180,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(item.icon, color: indigo),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => navigate(item.page),
                          child: Text(item.button),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Panel(
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: indigo,
                  size: 36,
                ),
                const Text(
                  'Find a workspace for your next booking.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                FilledButton.icon(
                  onPressed: () => navigate(3),
                  icon: const Icon(Icons.search),
                  label: const Text('Check availability'),
                ),
                OutlinedButton.icon(
                  onPressed: () => navigate(4),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('New booking'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
