import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/pasted_excerpt_local_check.dart';
import '../components/pasted_excerpt_check_dialog.dart';

/// #222: "is this covered?" — the user pastes the relevant excerpt of their
/// own boat's manual/warranty terms/wiring diagram labels alongside a
/// description of what broke, and the LLM reasons over that pasted text.
/// There is no OCR/text-extraction pipeline for `Document` (#222's scope
/// note), so this never reads a stored file directly. Reached only via the
/// maintenance item's AI menu (#208 separation — never blended into the
/// item's offline Complete/Hide/Delete actions).
///
/// A thin wrapper over [PastedExcerptCheckDialog] (extracted at #227, once
/// #226 made this the second near-identical dialog) — owns only this
/// feature's labels, system prompt, and payload builder call.
class WarrantyCheckDialog extends ConsumerWidget {
  const WarrantyCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PastedExcerptCheckDialog(
      title: 'AI: Warranty check',
      descriptionLabel: 'What broke?',
      descriptionHelper: 'Describe the failure — what happened, when.',
      excerptLabel: 'Manual / warranty excerpt',
      excerptHelper:
          'Paste the relevant clause, manual section, or wiring '
          'diagram labels — not the whole document.',
      disclaimer:
          'This is a reading of the text you pasted, not a '
          'legal or warranty determination — confirm with the '
          'manufacturer/dealer before relying on it.',
      onLocal: (breakage, excerpt) => PastedExcerptLocalCheck.warranty(
        situation: breakage,
        excerpt: excerpt,
      ),
      onAsk: (breakage, excerpt) async {
        final boat = await ref.read(activeBoatProvider.future);
        final payload = LlmPayloadBuilder.warrantyQuery(
          breakageDescription: breakage,
          manualExcerpt: excerpt,
        );
        return LlmClientService().complete(
          boat: boat,
          systemPrompt:
              'You are a boat maintenance assistant. Given a '
              'description of a breakage and a pasted excerpt from the '
              'boat\'s own manual, warranty terms, or wiring diagram labels, '
              'assess whether the breakage looks covered and explain your '
              'reasoning by pointing to what in the excerpt supports it. If '
              'the excerpt doesn\'t say enough to tell, say so plainly. Be '
              'concise.',
          prompt: jsonEncode(payload),
        );
      },
    );
  }
}
