import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Asks for one line of text. Returns null when cancelled.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
  String hint = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) {
      void submit() {
        final value = controller.text.trim();
        if (value.isNotEmpty) Navigator.of(context).pop(value);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint, counterText: ''),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: submit, child: Text(action)),
        ],
      );
    },
  );
}

/// Asks the person to confirm a destructive step.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: OrdoColors.danger),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
