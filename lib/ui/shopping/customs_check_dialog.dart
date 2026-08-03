import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../components/pasted_excerpt_check_dialog.dart';

/// #228: same document-grounded-reasoning shape as #222/#226/#227 — before
/// crossing a border, the user pastes an excerpt of that country's
/// customs/import-restriction rules alongside the item(s) they're carrying
/// (spirits quantity, meat/dairy/produce, firearms-adjacent gear, plant
/// material), and the LLM assesses whether it looks restricted and what
/// the excerpt says. Reasons only over pasted text the user themselves
/// supplied — not a live-search feature (that shape belongs to #224).
/// Reached only via a shopping/provisioning item's AI badge (#208
/// separation — never blended into the item's swipe-revealed
/// Complete/Hide/Email actions).
///
/// A thin wrapper over [PastedExcerptCheckDialog] (shared base widget
/// extracted at #227) — owns only this feature's labels, system prompt,
/// and payload builder call.
class CustomsCheckDialog extends ConsumerWidget {
  const CustomsCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PastedExcerptCheckDialog(
      title: 'AI: Customs check',
      descriptionLabel: 'Item(s) you\'re carrying',
      descriptionHelper: 'Describe what and how much — e.g. spirits '
          'quantity, meat/dairy/produce, plant material, firearms-adjacent '
          'gear.',
      excerptLabel: 'Customs / import rules excerpt',
      excerptHelper: 'Paste the relevant section from the destination '
          'country\'s customs site or cruising guide — not the whole page.',
      disclaimer: 'This is an AI reading of the text you pasted, not an '
          'official customs determination — confirm with the destination '
          'country\'s customs/border authority before relying on it.',
      onAsk: (item, excerpt) async {
        final boat = await ref.read(activeBoatProvider.future);
        final payload = LlmPayloadBuilder.customsQuery(
          itemDescription: item,
          rulesExcerpt: excerpt,
        );
        return LlmClientService().complete(
          boat: boat,
          systemPrompt: 'You are a boat provisioning/customs assistant. '
              'Given a description of item(s) being carried across a '
              'border and a pasted excerpt from that country\'s customs or '
              'import-restriction rules, assess whether the item(s) look '
              'restricted and explain your reasoning by pointing to what '
              'in the excerpt supports it. If the excerpt doesn\'t say '
              'enough to tell, say so plainly. Be concise.',
          prompt: jsonEncode(payload),
        );
      },
    );
  }
}
