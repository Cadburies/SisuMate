import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/di.dart';
import '../models/models.dart';

/// Shopping/provision list sharing via the device's own mail app
/// (`mailto:` scheme — no in-app SMTP, nothing to configure).
class EmailService {
  static const _maxRecent = 5;

  /// Prompts for a recipient (pre-filled with the most recent, plus
  /// tappable chips for the rest), then launches the mail app.
  static Future<void> composeAndSend(
    BuildContext context,
    WidgetRef ref, {
    required String subject,
    required String body,
  }) async {
    final settings = await ref.read(userSettingsProvider.future);
    if (!context.mounted) return;
    final recentEmails = settings?.recentEmails ?? [];

    final recipient = await showDialog<String>(
      context: context,
      builder: (_) => _RecipientDialog(recentEmails: recentEmails),
    );
    if (recipient == null || recipient.isEmpty) return;

    final replyTo = settings?.replyToEmail;
    final fromName = settings?.fromName;
    final finalBody =
        fromName != null && fromName.trim().isNotEmpty ? '$body\n\n— $fromName' : body;

    // Uri(queryParameters:) form-encodes spaces as "+", which RFC 6068
    // mailto consumers (e.g. Gmail) show literally instead of decoding —
    // percent-encode each value by hand so spaces render correctly.
    final params = {
      'subject': subject,
      'body': finalBody,
      if (replyTo != null && replyTo.trim().isNotEmpty) 'reply-to': replyTo,
    };
    final query =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final uri = Uri.parse('mailto:$recipient?$query');

    final launched = await launchUrl(uri);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No email app available')));
      return;
    }

    await _recordRecentEmail(ref, settings, recipient);
  }

  static Future<void> _recordRecentEmail(
      WidgetRef ref, UserSettings? settings, String email) async {
    final updated = settings ?? UserSettings();
    final list = [...updated.recentEmails]..remove(email);
    list.insert(0, email);
    updated.recentEmails = list.take(_maxRecent).toList();
    await ref.read(userSettingsRepositoryProvider).updateSettings(updated);
    ref.invalidate(userSettingsProvider);
  }
}

class _RecipientDialog extends StatefulWidget {
  final List<String> recentEmails;
  const _RecipientDialog({required this.recentEmails});

  @override
  State<_RecipientDialog> createState() => _RecipientDialogState();
}

class _RecipientDialogState extends State<_RecipientDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.recentEmails.isNotEmpty ? widget.recentEmails.first : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send to'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.recentEmails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.recentEmails
                  .map((e) => ActionChip(
                        label: Text(e, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _controller.text = e),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
