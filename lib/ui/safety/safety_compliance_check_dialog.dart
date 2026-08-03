import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../components/pasted_excerpt_check_dialog.dart';

/// #226: same document-grounded-reasoning shape as #222's
/// [WarrantyCheckDialog] — the user pastes an excerpt from a flare/life-raft/
/// EPIRB/fire-extinguisher service manual or certification card alongside
/// the item's current state (last service date, visible condition, expiry
/// markings), and the LLM assesses whether it looks still compliant/in-date.
/// Conservatively scoped to pasted text only — no OCR/photo reading of an
/// actual certification tag. Reached only via the safety item's AI badge
/// (#208 separation — never blended into the tile's offline Complete/Hide
/// actions).
///
/// A thin wrapper over [PastedExcerptCheckDialog] (extracted at #227) — owns
/// only this feature's labels, system prompt, and payload builder call.
class SafetyComplianceCheckDialog extends ConsumerWidget {
  const SafetyComplianceCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PastedExcerptCheckDialog(
      title: 'AI: Compliance check',
      descriptionLabel: 'Item & current state',
      descriptionHelper: 'What is it, last service date, visible '
          'condition, expiry markings.',
      excerptLabel: 'Manual / certification excerpt',
      excerptHelper: 'Paste the relevant service interval or certification '
          'section — not the whole document.',
      disclaimer: 'This is an AI reading of the text you pasted, not a '
          'certified inspection — confirm with a certified '
          'inspector/service agent before relying on it.',
      onAsk: (item, excerpt) async {
        final boat = await ref.read(activeBoatProvider.future);
        final payload = LlmPayloadBuilder.safetyComplianceQuery(
          itemDescription: item,
          excerptText: excerpt,
        );
        return LlmClientService().complete(
          boat: boat,
          systemPrompt: 'You are a boat safety-equipment assistant. Given a '
              'description of a safety item\'s current state (last service '
              'date, visible condition, expiry markings) and a pasted '
              'excerpt from its service manual or certification card, '
              'assess whether it looks still compliant/in-date and explain '
              'your reasoning by pointing to what in the excerpt supports '
              'it. If the excerpt doesn\'t say enough to tell, say so '
              'plainly. Be concise.',
          prompt: jsonEncode(payload),
        );
      },
    );
  }
}
