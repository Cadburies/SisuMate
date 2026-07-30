/// Curated marine engine/boat-system makes for Community Marketplace search
/// (S5). A controlled vocabulary rather than free text, so browsing by
/// engine is an exact match instead of a string-contains guess. Stored in
/// `CommunityTemplate.subcategory` (and Supabase `community_templates.subcategory`),
/// which already existed end-to-end before S5 — this is the first thing that
/// actually populates it from the UI.
abstract final class BoatEngineTaxonomy {
  static const makes = <String>[
    'Yanmar',
    'Volvo Penta',
    'Perkins',
    'Beta Marine',
    'Universal',
    'Westerbeke',
    'Nanni',
    'Vetus',
    'Yamaha',
    'Mercury',
    'Honda',
    'Other',
  ];
}
