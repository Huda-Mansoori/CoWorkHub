// Availability results: stateless resource cards with a parent-owned Book callback.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/resource.dart';
import 'app_ui.dart';
import 'resource_card.dart';

class AvailabilityResults extends StatelessWidget {
  final List<Resource>? results;
  final double available;
  final int? resourceId;
  final bool busy;
  final ValueChanged<Resource> onBook;
  const AvailabilityResults({
    super.key,
    required this.results,
    required this.available,
    this.resourceId,
    required this.busy,
    required this.onBook,
  });
  @override
  Widget build(BuildContext context) {
    final columns = math.max(1, (available / 300).floor());
    final cardWidth = (available - (columns - 1) * 20) / columns;
    if (results == null) {
      return const ListState(
        title: 'Find an available workspace',
        detail:
            'Choose your dates, times and attendees, then check availability.',
        icon: Icons.event_available_outlined,
      );
    }
    if (results!.isEmpty) {
      return const ListState(
        title: 'No resources available',
        detail: 'Try another time or a smaller group.',
        icon: Icons.event_busy_outlined,
      );
    }
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final resource in results!)
          SizedBox(
            width: cardWidth,
            child: ResourceCard(
              resource: resource,
              selected: resourceId == resource.id,
              disabled: busy,
              onBook: () => onBook(resource),
            ),
          ),
      ],
    );
  }
}
