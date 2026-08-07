import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
import '../../services/provision_calculator.dart';
import '../../services/email_service.dart';
import '../../providers/pantry_ingredient_provider.dart';
import 'meal_planner_screen.dart' show formatShortDate;

class ProvisionPlannerScreen extends ConsumerStatefulWidget {
  final MealPlan plan;
  const ProvisionPlannerScreen({super.key, required this.plan});

  @override
  ConsumerState<ProvisionPlannerScreen> createState() =>
      _ProvisionPlannerScreenState();
}

class _ProvisionPlannerScreenState
    extends ConsumerState<ProvisionPlannerScreen> {
  late Future<Map<String, List<RecipeIngredient>>> _ingredientsByRecipe;

  @override
  void initState() {
    super.initState();
    _ingredientsByRecipe = _loadIngredients();
  }

  Future<Map<String, List<RecipeIngredient>>> _loadIngredients() async {
    final repo = ref.read(recipeRepositoryProvider);
    final ids = widget.plan.slots
        .map((s) => s.recipeSupabaseId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final result = <String, List<RecipeIngredient>>{};
    for (final id in ids) {
      result[id] = await repo.getIngredientsOnce(id);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(pantryIngredientsProvider);
    final profilesAsync = ref.watch(guestProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            tooltip: 'Add pack shortfall to shopping',
            onPressed: () => _addPackGapsToShopping(context),
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: 'Email provision list',
            onPressed: () => _emailList(context),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<RecipeIngredient>>>(
        future: _ingredientsByRecipe,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return pantryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (pantry) {
              return profilesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (profiles) => _buildContent(
                    context, snapshot.data!, pantry, profiles),
              );
            },
          );
        },
      ),
    );
  }

  ProvisionResult _compute(
    Map<String, List<RecipeIngredient>> ingredientsByRecipe,
    List<PantryIngredient> pantry,
    List<GuestProfile> profiles,
  ) {
    return ProvisionCalculator.compute(
      plan: widget.plan,
      ingredientsByRecipe: ingredientsByRecipe,
      pantry: pantry,
      profiles: profiles,
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, List<RecipeIngredient>> ingredientsByRecipe,
    List<PantryIngredient> pantry,
    List<GuestProfile> profiles,
  ) {
    final plan = widget.plan;
    final result = _compute(ingredientsByRecipe, pantry, profiles);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
        Text('${plan.guestCount} guests',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 16),
        if (result.allergenWarnings.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.warning_amber,
                      size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 6),
                  Text('Allergen warnings',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                ...result.allergenWarnings.map((w) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(w,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (result.portionedItems.isNotEmpty) ...[
          Text('Freezer / butcher packs',
              style: Theme.of(context).textTheme.titleSmall),
          Text(
            'One bag per meal — bag contents are already guest-scaled.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 6),
          ...result.portionedItems.map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.set_meal_outlined,
                    color: SisuColors.completedBackground),
                title: Text(r.freezerPackPlan),
                subtitle: Text(r.formatted),
              )),
          const SizedBox(height: 16),
        ],
        Text('Consolidated Provisions',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        if (result.consolidatedItems.isEmpty)
          Text('No recipes assigned yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline))
        else
          ...result.consolidatedItems.map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_basket_outlined,
                    color: SisuColors.incompleteBackground),
                title: Text(r.formatted),
              )),
        // #310 — pack-aware shortfall for shopping.
        ..._shopGapSection(context, result, pantry),
      ],
    );
  }

  List<Widget> _shopGapSection(
    BuildContext context,
    ProvisionResult result,
    List<PantryIngredient> pantry,
  ) {
    final packs = ProvisionCalculator.shoppingPackGaps(
      provision: result,
      pantry: pantry,
    );
    if (packs.isEmpty) {
      return [
        const SizedBox(height: 16),
        Text('Shopping shortfall',
            style: Theme.of(context).textTheme.titleSmall),
        Text('Nothing to buy — pantry covers the plan (or plan is empty).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline)),
      ];
    }
    return [
      const SizedBox(height: 16),
      Text('Shopping shortfall (packs)',
          style: Theme.of(context).textTheme.titleSmall),
      Text(
        'Buy counts use package size from the catalog (e.g. 500 g bag), '
        'not raw recipe grams.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline),
      ),
      const SizedBox(height: 6),
      ...packs.map((line) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_grocery_store_outlined),
            title: Text(line.formatted),
            subtitle: line.note != null ? Text(line.note!) : null,
            trailing: line.lineEstimate != null
                ? Text('\$${line.lineEstimate!.toStringAsFixed(2)}')
                : null,
          )),
    ];
  }

  Future<void> _addPackGapsToShopping(BuildContext context) async {
    final ingredientsByRecipe = await _ingredientsByRecipe;
    final pantry = ref.read(pantryIngredientsProvider).asData?.value ?? [];
    final profiles = ref.read(guestProfilesProvider).asData?.value ?? [];
    final result = _compute(ingredientsByRecipe, pantry, profiles);
    final packs = ProvisionCalculator.shoppingPackGaps(
      provision: result,
      pantry: pantry,
    );
    if (packs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pack shortfall to add')),
        );
      }
      return;
    }
    final repo = ref.read(shoppingRepositoryProvider);
    var added = 0;
    for (final line in packs) {
      final ok = await repo.ensureInShopping(
        name: line.name,
        origin: 'pantry',
        quantity: line.packages,
        unit: line.unitLabel,
      );
      if (ok) added++;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added == 0
            ? 'All shortfall lines already on the shopping list'
            : 'Added $added pack line${added == 1 ? '' : 's'} to shopping'),
      ));
    }
  }

  Future<String> _buildProvisionText() async {
    final ingredientsByRecipe = await _ingredientsByRecipe;
    final pantry = ref.read(pantryIngredientsProvider).asData?.value ?? [];
    final profiles = ref.read(guestProfilesProvider).asData?.value ?? [];
    final plan = widget.plan;
    final result = _compute(ingredientsByRecipe, pantry, profiles);

    final buffer = StringBuffer()
      ..writeln(plan.name)
      ..writeln('${plan.guestCount} guests')
      ..writeln();
    if (result.portionedItems.isNotEmpty) {
      buffer.writeln('Freezer / butcher packs:');
      for (final r in result.portionedItems) {
        buffer.writeln('- ${r.freezerPackPlan}');
      }
      buffer.writeln();
    }
    buffer.writeln('Consolidated Provisions:');
    for (final r in result.consolidatedItems) {
      buffer.writeln('- ${r.formatted}');
    }
    final packs = ProvisionCalculator.shoppingPackGaps(
      provision: result,
      pantry: pantry,
    );
    if (packs.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Shopping shortfall (packs):');
      for (final line in packs) {
        buffer.writeln('- ${line.formatted}');
      }
    }
    return buffer.toString();
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = await _buildProvisionText();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Provision list copied')));
    }
  }

  Future<void> _emailList(BuildContext context) async {
    final text = await _buildProvisionText();
    if (!context.mounted) return;
    final settings = await ref.read(userSettingsProvider.future);
    if (!context.mounted) return;
    final plan = widget.plan;
    final boatName = settings?.boatName ?? plan.name;

    await EmailService.composeAndSend(
      context,
      ref,
      subject:
          'Provisions for $boatName for ${plan.guestCount} guests — week of ${formatShortDate(plan.startDate)}',
      body: text,
    );
  }
}
