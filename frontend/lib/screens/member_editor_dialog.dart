// Member editor: validates input and delegates persistence to its parent page.
import 'package:flutter/material.dart';

import '../models/member.dart';
import '../widgets/app_ui.dart';

class MemberEditor extends StatefulWidget {
  final Member? existing;
  final Future<void> Function(Member draft) onSave;
  const MemberEditor({super.key, this.existing, required this.onSave});
  @override
  State<MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<MemberEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, email;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.fullName ?? '');
    email = TextEditingController(text: widget.existing?.email ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  // TRACE: Save -> validate -> parent onSave -> MemberApi.create/update
  // -> MemberController -> MemberService -> MemberRepository.save -> MySQL
  // <- success closes dialog; failure keeps fields and displays the backend message.
  Future<void> submit() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final draft = Member(
        fullName: name.text.trim(),
        email: email.text.trim(),
      );
      await widget.onSave(draft);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = displayError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => EditorDialog(
    title: widget.existing == null ? 'Add member' : 'Edit member',
    saving: saving,
    error: error,
    onSave: submit,
    onCancel: () => Navigator.pop(context, false),
    child: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: name,
            onFieldSubmitted: (_) => submit(),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Member name *',
              hintText: 'e.g. Dana Ali',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Enter the member name.'
                : v.trim().length > 150
                ? 'Use 150 characters or fewer.'
                : null,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: email,
            onFieldSubmitted: (_) => submit(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'e.g. dana@example.com',
            ),
            validator: (v) =>
                v == null ||
                    v.trim().length > 150 ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? 'Enter a valid email address, e.g. dana@example.com.'
                : null,
          ),
        ],
      ),
    ),
  );
}
