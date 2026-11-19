import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'app_ui.dart';
import '../theme/app_theme.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onBook, onEdit, onDelete;
  final bool selected, disabled;
  final Json? details;
  const ResourceCard({
    super.key,
    required this.resource,
    this.onBook,
    this.onEdit,
    this.onDelete,
    this.selected = false,
    this.disabled = false,
    this.details,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: selected ? Border.all(color: indigo, width: 2) : null,
    ),
    child: Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResourcePhoto(isDesk: resource.isDesk, id: resource.id, height: 180),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                resource.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (onBook == null) StatusBadge(resource.status),
            ],
          ),
          const SizedBox(height: 18),
          FactRow(Icons.location_on_outlined, resource.location),
          FactRow(
            Icons.chair_outlined,
            '${resource.capacity} ${resource.capacity == 1 ? 'seat' : 'seats'}',
          ),
          FactRow(
            Icons.payments_outlined,
            '${resource.rate.toStringAsFixed(2)} QAR / hour',
          ),
          if (details != null) ...[
            const Divider(height: 24),
            if (resource.isDesk)
              FactRow(
                Icons.desk_outlined,
                details!['deskType']?.toString() ?? 'Desk',
              )
            else ...[
              FactRow(
                Icons.slideshow_outlined,
                'Projector: ${details!['projector'] == true ? 'Yes' : 'No'}',
              ),
              FactRow(
                Icons.videocam_outlined,
                'Video conference: ${details!['videoConference'] == true ? 'Yes' : 'No'}',
              ),
            ],
          ],
          const SizedBox(height: 12),
          if (onBook != null)
            selected
                ? FilledButton.icon(
                    onPressed: disabled ? null : onBook,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Book'),
                  )
                : OutlinedButton.icon(
                    onPressed: disabled ? null : onBook,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Book'),
                  ),
          if (onEdit != null || onDelete != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: disabled ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: const BorderSide(color: danger),
                  ),
                  onPressed: disabled ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
