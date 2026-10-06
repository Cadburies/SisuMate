import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/pasted_excerpt_local_check.dart';
import '../components/pasted_excerpt_check_dialog.dart';

/// #227: same document-grounded-reasoning shape as #222's
/// `WarrantyCheckDialog`, against an insurance policy instead of
/// manufacturer warranty terms — the user pastes the relevant policy
/// excerpt (coverage clause, exclusions, deductible terms) alongside a
/// description of an incident (storm damage, grounding, theft, gear loss),
/// and the LLM reasons over that pasted text to assess likely coverage.
/// Reached only via an Insurance-category document's AI entry point (#208
/// separation — never blended into the document's view/delete actions).
///
/// A thin wrapper over [PastedExcerptCheckDialog] (extracted at #227 from
/// #222/#226's near-identical dialogs) — owns only this feature's labels,
/// system prompt, and payload builder call.
class InsuranceClaimCheckDialog extends ConsumerWidget {
  const InsuranceClaimCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PastedExcerptCheckDialog(
      title: 'AI: Insurance claim check',
      descriptionLabel: 'What happened?',
      descriptionHelper:
          'Describe the incident — storm damage, grounding, '
          'theft, gear loss.',
      excerptLabel: 'Policy excerpt',
      excerptHelper:
          'Paste the relevant coverage clause, exclusions '
          'section, or deductible terms — not the whole policy.',
      disclaimer:
          'This is a reading of the text you pasted, not a '
          'claims or legal determination — confirm with your '
          'insurer/broker before relying on it.',
      onLocal: (incident, excerpt) => PastedExcerptLocalCheck.insurance(
        situation: incident,
        excerpt: excerpt,
      ),
      onAsk: (incident, excerpt) async {
        final boat = await ref.read(activeBoatProvider.future);
        final payload = LlmPayloadBuilder.insuranceClaimQuery(
          incidentDescription: incident,
          policyExcerpt: excerpt,
        );
        return LlmClientService().complete(
          boat: boat,
          systemPrompt:
              'You are a boat insurance assistant. Given a '
              'description of an incident and a pasted excerpt from the '
              'boat owner\'s own insurance policy (coverage clause, '
              'exclusions, deductible terms), assess whether the incident '
              'looks likely covered and explain your reasoning by pointing '
              'to what in the excerpt supports it. If the excerpt doesn\'t '
              'say enough to tell, say so plainly. Be concise.',
          prompt: jsonEncode(payload),
        );
      },
    );
  }
}
