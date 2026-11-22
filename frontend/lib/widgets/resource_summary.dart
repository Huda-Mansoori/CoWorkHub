// Resource summary: stateless photograph, capacity and rate beside a booking form.
import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../theme/app_theme.dart';
import 'app_ui.dart';

class ResourceSummary extends StatelessWidget {
  final Resource r;
  const ResourceSummary(this.r, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResourcePhoto(isDesk: r is Desk, id: r.id, height: 190),
        const SizedBox(height: 22),
        Text(r.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 22),
        FactRow(Icons.location_on_outlined, r.location),
        FactRow(
          Icons.chair_outlined,
          '${r.capacity} ${r.capacity == 1 ? 'seat' : 'seats'}',
        ),
        FactRow(
          Icons.payments_outlined,
          '${r.hourlyRate.toStringAsFixed(2)} QAR / hour',
        ),
        const Divider(height: 28),
        const Text(
          'Final cost is calculated when the booking is saved.',
          style: TextStyle(color: secondaryInk),
        ),
      ],
    ),
  );
}
