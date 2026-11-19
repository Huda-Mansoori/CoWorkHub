import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

const defaultApiBase = String.fromEnvironment(
  'COWORK_API_BASE',
  defaultValue: 'http://localhost:8080/api',
);

String displayError(Object? error) {
  if (error is FormatException) return error.message;
  if (error is TimeoutException) {
    return 'The request timed out. Check the backend connection and try again.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

String dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String dateTimeLabel(DateTime date) => '${dateLabel(date)} ${timeLabel(date)}';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDDE0EC)),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  final String title;
  final Widget? action;
  const PageHeading(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: WrapAlignment.spaceBetween,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
      ?action,
    ],
  );
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const ErrorBanner(this.message, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDE9D94)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: danger)),
          ),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class ListState extends StatelessWidget {
  final bool loading;
  final String title;
  final String? detail, actionLabel;
  final VoidCallback? action;
  final IconData icon;
  const ListState({
    super.key,
    this.loading = false,
    required this.title,
    this.detail,
    this.actionLabel,
    this.action,
    this.icon = Icons.inbox_outlined,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 42, color: indigo),
            const SizedBox(height: 18),
            Semantics(
              liveRegion: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: const TextStyle(color: secondaryInk),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: action,
                child: Text(actionLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final positive = status == 'ACTIVE' || status == 'CONFIRMED';
    final label = switch (status) {
      'ACTIVE' => 'Active',
      'CONFIRMED' => 'Confirmed',
      'CANCELLED' => 'Cancelled',
      'OUT_OF_SERVICE' => 'Out of service',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE6F6E9) : const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: positive ? const Color(0xFF166534) : const Color(0xFF784810),
        ),
      ),
    );
  }
}

class ResourcePhoto extends StatelessWidget {
  final bool isDesk;
  final int id;
  final double? height;
  const ResourcePhoto({
    super.key,
    required this.isDesk,
    required this.id,
    this.height,
  });
  @override
  Widget build(BuildContext context) {
    final path = isDesk
        ? 'desk'
        : id.isOdd
        ? 'room-a'
        : 'room-b';
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.asset(
        'assets/images/$path.png',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 1000,
        semanticLabel: isDesk
            ? 'Illustrative desk workspace'
            : 'Illustrative meeting room',
        errorBuilder: (_, _, _) => SizedBox(
          height: height ?? 180,
          child: Icon(
            isDesk ? Icons.desk_outlined : Icons.meeting_room_outlined,
            size: 48,
            color: indigo,
          ),
        ),
      ),
    );
  }
}

class FactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const FactRow(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: secondaryInk),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class FieldGrid extends StatelessWidget {
  final List<Widget> children;
  const FieldGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth >= 560
          ? (box.maxWidth - 20) / 2
          : box.maxWidth;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class EditorDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final bool saving;
  final String? error;
  final VoidCallback onSave, onCancel;
  const EditorDialog({
    super.key,
    required this.title,
    required this.child,
    required this.saving,
    this.error,
    required this.onSave,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (!saving) onSave();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          if (!saving) onSave();
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!saving) onSave();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!saving) onCancel();
        },
      },
      child: FocusTraversalGroup(
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          title: Text(title),
          content: SizedBox(
            width: 620,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .65,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      ErrorBanner(error!),
                      const SizedBox(height: 20),
                    ],
                    child,
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          actions: [
            OutlinedButton(
              onPressed: saving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          OutlinedButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
