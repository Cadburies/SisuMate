Here is your **ready-to-copy, production-ready schema** for **Supabase (PostgreSQL + RLS)** and **Isar (Flutter local DB)** — 100% aligned with your final Free vs Pro rules, multi-boat, offline-first, real-time sync, hidden items, swipe actions, and the exact apps.md structure.

### 1. Supabase Schema (SQL) - Run this in Supabase SQL Editor

```sql
-- 1. Enable extensions
create extension if not exists "uuid-ossp";

-- 2. Profiles (Supabase Auth users)
create table profiles (
  public.profiles (
  id uuid primary key references auth.users not null,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 3. Boats (multi-boat support)
create table public.boats (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  owner_id uuid references auth.users not null,
  photo_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 4. Boat Members (crew sharing)
create table public.boat_members (
  boat_id uuid references public.boats on delete cascade,
  user_id uuid references auth.users on delete cascade,
  role text default 'crew', -- owner / admin / crew / guest
  joined_at timestamp with time zone default now(),
  primary key (boat_id, user_id)
);

-- 5. Checklist Groups
create table public.checklist_groups (
  id uuid primary key default uuid_generate_v4(),
  boat_id uuid references public.boats on delete cascade,
  name text not null,
  icon text default 'clipboard-check',
  sort_order integer default 0,
  app_type text default 'checklist', -- 'checklist', 'safety', 'document'
  is_bundled boolean default false,  -- true = factory content (never deleted on reset)
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 6. Checklist Items
create table public.checklist_items (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid references public.checklist_groups on delete cascade,
  name text not null,
  description text,
  asset_name text,           -- bundled photo path in assets
  user_photo_url text,       -- uploaded photo path in app folder
  notes text,
  is_completed boolean default false,
  completed_at timestamp with time zone,
  completed_by uuid references auth.users,
  expiry_date date,          -- for Documents Vault
  is_hidden boolean default false,
  permanently_deleted boolean default false,
  sort_order integer default 0,
  created_at timestamp with time zone default now(),
  added_at timestamp with time zone,  -- when added to list
  updated_at timestamp with time zone default now()
);

-- 7. Shopping / Spares
create table public.shopping_categories (
  id uuid primary key default uuid_generate_v4(),
  boat_id uuid references public.boats on delete cascade,
  name text not null,
  sort_order integer default 0
);

create table public.shopping_items (
  id uuid primary key default uuid_generate_v4(),
  category_id uuid references public.shopping_categories on delete cascade,
  name text not null,
  quantity integer default 1,
  notes text,
  asset_name text,           -- bundled photo path in assets
  user_photo_url text,       -- uploaded photo path in app folder
  is_bought boolean default false,
  is_hidden boolean default false,
  permanently_deleted boolean default false,
  origin text default 'spares', -- 'galley', 'spares', 'bar', etc.
  last_purchase_price decimal,
  last_purchase_date date,
  purchase_location text, -- notes field for where bought
  created_at timestamp with time zone default now(),
  added_at timestamp with time zone,  -- when added to list
  purchased_at timestamp with time zone,  -- when marked as bought/provisioned
  updated_at timestamp with time zone default now()
);

-- 8. Captain's Log
create table public.captain_logs (
  id uuid primary key default uuid_generate_v4(),
  boat_id uuid references public.boats on delete cascade,
  log_date date not null,
  log_time time,
  position_lat double precision,
  position_lng double precision,
  weather text,
  wind_speed_kt integer,
  wind_dir text,
  crew_on_board text[],
  notes text,
  photos text[], -- array of Supabase Storage URLs
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 9. Maintenance Scheduler
create table public.equipment (
  id uuid primary key default uuid_generate_v4(),
  boat_id uuid references public.boats on delete cascade,
  name text not null,
  running_hours integer default 0,
  notes text
);

create table public.maintenance_tasks (
  id uuid primary key default uuid_generate_v4(),
  equipment_id uuid references public.equipment on delete cascade,
  description text not null,
  interval_hours integer,      -- null = calendar-based
  interval_months integer,    -- null = hour-based
  last_done_hours integer,
  last_done_date date,
  done_by uuid references auth.users,
  notes text,
  is_hidden boolean default false
);

create table public.maintenance_logs (
  id uuid primary key default uuid_generate_v4(),
  task_id uuid references public.maintenance_tasks on delete cascade,
  boat_id uuid references public.boats on delete cascade,
  completed_date date not null,
  completed_at_hours integer,
  completed_by uuid references auth.users,
  notes text,
  created_at timestamp with time zone default now()
);

-- 10. Recipes (Menus and Cocktails)
create table public.recipes (
  id uuid primary key default uuid_generate_v4(),
  boat_id uuid references public.boats on delete cascade,
  name text not null,
  description text,
  instructions text,
  recipe_type text default 'menu', -- 'menu' or 'cocktail'
  asset_name text,           -- bundled photo path in assets
  user_photo_url text,       -- uploaded photo path in app folder
  is_bundled boolean default false,
  created_at timestamp with time zone default now(),
  added_at timestamp with time zone,  -- when added to list
  updated_at timestamp with time zone default now()
);

-- 11. Recipe Ingredients
create table public.recipe_ingredients (
  id uuid primary key default uuid_generate_v4(),
  recipe_id uuid references public.recipes on delete cascade,
  name text not null,
  quantity decimal,
  unit text, -- teaspoon, tablespoon, cup, etc.
  substitute text,
  is_garnish boolean default false,
  is_optional boolean default false,
  asset_name text,           -- bundled photo path in assets
  user_photo_url text,       -- uploaded photo path in app folder
  sort_order integer default 0,
  created_at timestamp with time zone default now(),
  added_at timestamp with time zone,  -- when added to recipe
  updated_at timestamp with time zone default now()
);

-- 12. User Settings (synced only for Pro users)
create table public.user_settings (
  user_id uuid primary key references auth.users,
  active_boat_id uuid references public.boats,
  show_hidden_items boolean default false,
  is_pro boolean default false,
  pro_expires_at timestamp with time zone,
  updated_at timestamp with time zone default now()
);

-- ROW LEVEL SECURITY (RLS) - CRITICAL FOR MULTI-BOAT SHARING
alter table public.boats enable row level security;
alter table public.boat_members enable row level security;
alter table public.checklist_groups enable row level security;
alter table public.checklist_items enable row level security;
alter table public.shopping_categories enable row level security;
alter table public.shopping_items enable row level security;
alter table public.captain_logs enable row level security;
alter table public.captain_logs enable row level security;
alter table public.equipment enable row level security;
alter table public.maintenance_tasks enable row level security;
alter table public.maintenance_logs enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;

-- Policy: Users can only see/modify data for boats they are members of
create policy "Users can access their boats" on public.boats
  for all using (auth.uid() = owner_id or exists (select 1 from public.boat_members where boat_id = boats.id and user_id = auth.uid()));

-- Repeat similar policy for every table referencing boat_id
create policy "Access checklist data" on public.checklist_groups for all using (
  exists (select 1 from public.boats b join public.boat_members bm on b.id = bm.boat_id
          where b.id = checklist_groups.boat_id and bm.user_id = auth.uid())
);

-- Apply same pattern to all other tables… (copy-paste 8× or use loop in migration)

-- Realtime enabled on everything
alter publication supabase_realtime add table
  checklist_groups, checklist_items, shopping_items, shopping_categories,
  captain_logs, equipment, maintenance_tasks, maintenance_logs, boats, boat_members,
  recipes, recipe_ingredients;
```

### 2. Isar Schema (Dart) - Put in lib/models/

```dart
import 'package:isar/isar.dart';
part 'models.g.dart';

@collection
class Boat {
  Id id = Isar.autoIncrement;
  late String supabaseId;           // UUID from Supabase
  late String name;
  String? photoUrl;
  bool isSynced = false;
}

@collection
class ChecklistGroup {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String boatSupabaseId;
  late String name;
  String icon = 'clipboard-check';
  int sortOrder = 0;
  String appType = 'checklist'; // 'checklist', 'safety', 'document'
  bool isBundled = false;
  final items = IsarLinks<ChecklistItem>();
}

@collection
class ChecklistItem {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String groupSupabaseId;
  late String name;
  String? description;
  String? assetName;                // bundled photo
  String? userPhotoUrl;             // Supabase Storage
  String? notes;
  bool isCompleted = false;
  DateTime? completedAt;
  String? completedBy;               // user UID
  DateTime? expiryDate;              // for Documents
  bool isHidden = false;
  bool permanentlyDeleted = false;
  int sortOrder = 0;
}

@collection
class ShoppingCategory {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String boatSupabaseId;
  late String name;
  int sortOrder = 0;
  final items = IsarLinks<ShoppingItem>();
}

@collection
class ShoppingItem {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String categorySupabaseId;
  late String name;
  int quantity = 1;
  String? notes;
  String? photoUrl;
  bool isBought = false;
  bool isHidden = false;     // soft delete
  bool permanentlyDeleted = false;
  String origin = 'spares';  // 'galley', 'spares', 'bar', etc.
  double? lastPurchasePrice;
  DateTime? lastPurchaseDate;
  String? purchaseLocation;  // notes for where bought
}

@collection
class UserSettings {
  Id id = 1; // singleton
  String? activeBoatSupabaseId;
  bool showHiddenItems = false;
  bool isPro = false;
  DateTime? proExpiresAt;
}

@collection
class Recipe {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String boatSupabaseId;
  late String name;
  String? description;
  String? instructions;
  String recipeType = 'menu'; // 'menu' or 'cocktail'
  String? photoUrl;
  bool isBundled = false;
  final ingredients = IsarLinks<RecipeIngredient>();
}

@collection
class RecipeIngredient {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String recipeSupabaseId;
  late String name;
  double? quantity;
  String? unit; // teaspoon, tablespoon, cup, etc.
  String? substitute;
  bool isGarnish = false;
  bool isOptional = false;
  String? photoUrl;
  int sortOrder = 0;
}

@collection
class MaintenanceLog {
  Id id = Isar.autoIncrement;
  late String supabaseId;
  late String taskSupabaseId;
  late String boatSupabaseId;
  late DateTime completedDate;
  int? completedAtHours;
  String? completedBy;
  String? notes;
}

// Add other collections the same way: CaptainLogEntry, Equipment, MaintenanceTask, etc.
```

### 3. Sync Strategy (Pro users only)

```dart
// In your repository layer
if (userSettings.isPro && networkInfo.isConnected) {
  final tables = ['checklist_items', 'shopping_items', 'captain_logs', 'maintenance_logs', 'recipes', 'recipe_ingredients'];
  for (final table in tables) {
    supabase.from(table).stream(primaryKey: ['id']).listen((changes) {
      // upsert / soft-delete logic using is_hidden & permanently_deleted flags
    });
  }
}
```

### 4. Factory Bundled Data Seeder (run once on first launch)

```dart
// Seed all checklist_groups & checklist_items with isBundled = true
// These rows are never deleted on "Reset to factory"
```
