import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
import '../../services/recipe_allergen_service.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/pantry_ingredient_provider.dart';
import '../../services/provision_calculator.dart' show isoWeekdayNames;
import '../../services/trip_schedule.dart';

const _monthNames = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatShortDate(DateTime d) => '${_monthNames[d.month]} ${d.day}';

class MealPlannerScreen extends ConsumerWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(mealPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Planner')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No meal plans yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Tap + to plan meals for a trip.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final endDate =
                  plan.startDate.add(Duration(days: plan.numberOfDays - 1));
              final filledSlots = plan.slots
                  .where((s) => s.recipeSupabaseId.isNotEmpty)
                  .length;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SisuColors.incompleteBackground,
                    child: const Icon(Icons.restaurant_menu, color: Colors.white),
                  ),
                  title: Text(plan.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${formatShortDate(plan.startDate)} – ${formatShortDate(endDate)} · '
                    '${plan.guestCount} guest${plan.guestCount == 1 ? '' : 's'} · '
                    '$filledSlots/${totalSlotsForTrip(plan.numberOfDays)} slots planned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => _confirmDelete(context, ref, plan),
                  ),
                  onTap: () => context.push(AppRoutes.mealPlanDetail, extra: plan),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, MealPlan? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _PlanEditDialog(
        existing: existing,
        onSave: (plan) async {
          final repo = ref.read(mealPlanRepositoryProvider);
          if (existing == null) {
            await repo.addPlan(plan);
          } else {
            await repo.updatePlan(plan);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, MealPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('Remove "${plan.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(mealPlanRepositoryProvider).deletePlan(plan);
    }
  }
}

class _PlanEditDialog extends StatefulWidget {
  final MealPlan? existing;
  final Future<void> Function(MealPlan) onSave;
  const _PlanEditDialog({required this.existing, required this.onSave});

  @override
  State<_PlanEditDialog> createState() => _PlanEditDialogState();
}

class _PlanEditDialogState extends State<_PlanEditDialog> {
  late final TextEditingController _nameCtrl;
  late DateTime _startDate;
  late int _numberOfDays;
  late int _guestCount;
  late Set<int> _selectedProfileIds;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _startDate = e?.startDate ?? DateTime(now.year, now.month, now.day);
    _numberOfDays = e?.numberOfDays ?? 7;
    _nameCtrl = TextEditingController(text: e?.name ?? _defaultName());
    _guestCount = e?.guestCount ?? 4;
    _selectedProfileIds = Set.from(e?.guestProfileIds ?? []);
  }

  String _defaultName() => _numberOfDays == 7
      ? 'Week of ${formatShortDate(_startDate)}'
      : '$_numberOfDays-Day Trip — ${formatShortDate(_startDate)}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final profilePicker = _buildProfilePicker(context);
    return AlertDialog(
      title: Text(isEdit ? 'Edit Meal Plan' : 'New Meal Plan'),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Plan name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: const Text('Start date'),
              subtitle: Text(formatShortDate(_startDate)),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Trip length (days):'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _numberOfDays > 1
                      ? () => setState(() => _numberOfDays--)
                      : null,
                ),
                Text('$_numberOfDays',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _numberOfDays < 30
                      ? () => setState(() => _numberOfDays++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Guests:'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _guestCount > 1
                      ? () => setState(() => _guestCount--)
                      : null,
                ),
                Text('$_guestCount',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _guestCount < 20
                      ? () => setState(() => _guestCount++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Guest profiles (for allergen warnings):',
                style: Theme.of(context).textTheme.labelLarge),
            profilePicker,
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _nameCtrl.text.trim().isEmpty
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final plan = widget.existing ?? MealPlan();
                  plan
                    ..name = _nameCtrl.text.trim()
                    ..startDate = _startDate
                    ..numberOfDays = _numberOfDays
                    ..guestCount = _guestCount
                    ..guestProfileIds = _selectedProfileIds.toList()
                    // Drop slots for days a shortened trip no longer has.
                    ..slots = plan.slots
                        .where((s) => s.dayOffset < _numberOfDays)
                        .toList();
                  await widget.onSave(plan);
                  if (mounted) navigator.pop();
                },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  // Small helper to build the guest-profile checklist reactively without
  // making the whole dialog a ConsumerStatefulWidget just for one list.
  Widget _buildProfilePicker(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final profilesAsync = ref.watch(guestProfilesProvider);
        return profilesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (profiles) {
            if (profiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No guest profiles yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
              );
            }
            return Wrap(
              spacing: 6,
              runSpacing: 4,
              children: profiles
                  .map((p) => FilterChip(
                        label: Text(p.name, style: const TextStyle(fontSize: 12)),
                        selected: _selectedProfileIds.contains(p.id),
                        selectedColor:
                            SisuColors.completedBackground.withValues(alpha: 0.2),
                        checkmarkColor: SisuColors.completedBackground,
                        onSelected: (sel) => setState(() => sel
                            ? _selectedProfileIds.add(p.id)
                            : _selectedProfileIds.remove(p.id)),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class MealPlanDetailScreen extends ConsumerWidget {
  final MealPlan plan;
  const MealPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(mealPlansProvider);
    final currentPlan = plansAsync.asData?.value
            .where((p) => p.id == plan.id)
            .firstOrNull ??
        plan;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Provision list',
            onPressed: () =>
                context.push(AppRoutes.provisionPlanner, extra: currentPlan),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: currentPlan.numberOfDays,
        itemBuilder: (context, dayOffset) {
          final date = currentPlan.startDate.add(Duration(days: dayOffset));
          final dayMealTypes =
              mealTypesForDay(dayOffset, currentPlan.numberOfDays);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isoWeekdayNames[date.weekday]} · ${formatShortDate(date)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Divider(),
                  ...dayMealTypes.map((mealType) => _MealSlotRow(
                        plan: currentPlan,
                        dayOffset: dayOffset,
                        mealType: mealType,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MealSlotRow extends ConsumerWidget {
  final MealPlan plan;
  final int dayOffset;
  final String mealType;
  const _MealSlotRow({
    required this.plan,
    required this.dayOffset,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = plan.slots
        .where((s) => s.dayOffset == dayOffset && s.mealType == mealType)
        .firstOrNull;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 76,
        child: Text(
          mealType[0].toUpperCase() + mealType.substring(1),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline),
        ),
      ),
      title: slot == null
          ? Text('— none —',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic))
          : Text(slot.recipeName,
              style: Theme.of(context).textTheme.bodyMedium),
      trailing: slot == null
          ? IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: SisuColors.completedBackground,
              onPressed: () => _pickRecipe(context, ref),
            )
          : IconButton(
              icon: const Icon(Icons.close),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _clearSlot(ref),
            ),
    );
  }

  Future<void> _clearSlot(WidgetRef ref) async {
    final updated = plan.slots
        .where((s) => !(s.dayOffset == dayOffset && s.mealType == mealType))
        .toList();
    plan.slots = updated;
    await ref.read(mealPlanRepositoryProvider).updatePlan(plan);
  }

  void _pickRecipe(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, _) {
            final recipesAsync = ref.watch(recipesProvider('menu'));
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text('Choose a recipe',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: recipesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (recipes) => ListView.builder(
                        controller: scrollController,
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return _RecipePickerTile(
                            recipe: recipe,
                            guestProfileIds: plan.guestProfileIds,
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              final updated = [
                                ...plan.slots.where((s) => !(s.dayOffset ==
                                        dayOffset &&
                                    s.mealType == mealType)),
                                MealPlanSlot()
                                  ..dayOffset = dayOffset
                                  ..mealType = mealType
                                  ..recipeSupabaseId = recipe.supabaseId
                                  ..recipeName = recipe.name,
                              ];
                              plan.slots = updated;
                              await ref
                                  .read(mealPlanRepositoryProvider)
                                  .updatePlan(plan);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecipePickerTile extends ConsumerWidget {
  final Recipe recipe;
  final List<int> guestProfileIds;
  final VoidCallback onTap;
  const _RecipePickerTile({
    required this.recipe,
    required this.guestProfileIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync =
        ref.watch(recipeIngredientsProvider(recipe.supabaseId));
    final pantryAsync = ref.watch(pantryIngredientsProvider);
    final profilesAsync = ref.watch(guestProfilesProvider);

    final conflicts = <String>{};
    ingredientsAsync.whenData((ingredients) {
      pantryAsync.whenData((pantry) {
        profilesAsync.whenData((profiles) {
          final assessment = RecipeAllergenService.assess(ingredients, pantry);
          final restrictedAllergens = profiles
              .where((p) => guestProfileIds.contains(p.id))
              .expand((p) => p.allergenRestrictions)
              .toSet();
          conflicts.addAll(assessment.allergens.intersection(restrictedAllergens));
        });
      });
    });

    return ListTile(
      title: Text(recipe.name),
      subtitle: conflicts.isEmpty
          ? null
          : Text('Contains: ${conflicts.join(', ')}',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
      trailing: conflicts.isEmpty
          ? null
          : Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
      onTap: onTap,
    );
  }
}
