# apps.md - Comprehensive & Final

**Sisu Mate- Offshore-Ready Boating Suite**  
Updated: 30 November 2025

```markdown
# Sisu Mate Suite - All Apps (Home Screen Grid)

The main home screen displays large, colourful, breathing tiles (2×3 or 2×4 grid depending on device size).  
Each tile is an independent “app” within the suite. All apps follow the exact same design language, swipe actions, and Free vs Pro rules.

| #   | App Name                  | Icon (suggested)         | Short Tagline                                  | Free Tier Capabilities                                         | Pro Tier Additional Capabilities                                                            | Navigation Hierarchy (tap → next screen)                                                         |
| --- | ------------------------- | ------------------------ | ---------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1   | **Checklists**            | Clipboard with checkmark | Professional offshore checklists with photos   | View all bundled checklists<br>Read-only items                 | Mark complete, add notes/photos, edit/reorder, create custom checklists, completion history | Home → Checklists → Group List → Checklist → Item List → Item Detail (history, notes, photos)    |
| 2   | **Shopping & Spares**     | Shopping cart            | Onboard provisioning & shopping list manager   | FULL CRUD - add, edit, delete, mark provisioned, categories, photos, prices | Sync across devices & crew, export to PDF/CSV, add from anywhere in app                       | Home → Shopping & Spares → Origin Categories (with budget totals) → Item List → Add/Edit Item     |
| 3   | **Captain’s Log**         | Open book + anchor       | Digital yacht logbook with auto weather & GPS  | View last 7 days only (read-only)                              | Unlimited history, full edit, attach photos, auto weather/position, crew on board           | Home → Captain’s Log → Calendar/Date List → Log Entry Detail                                     |
| 4   | **Maintenance Scheduler** | Wrench + calendar        | Never miss an engine hour or rigging service   | View upcoming tasks (read-only)                                | Add/edit equipment, log service history, set reminders, running-hour counters               | Home → Maintenance → Equipment List → Equipment Detail → Service History + Upcoming              |
| 5   | **Safety Briefings**      | Life ring + megaphone    | One-tap crew & guest safety briefings          | Read all briefing scripts                                      | Read-aloud mode, custom briefings, mark as delivered, history                               | Home → Safety Briefings → Briefing Type → Script (with optional voice playback)                  |
| 6   | **Documents Vault**       | Locked folder            | Store & track boat papers, passports, licences | View documents & expiry dates                                  | Upload/edit, expiry alerts (push), share with crew/authorities                              | Home → Documents Vault → Category → Document List → Document Detail (preview + expiry countdown) |
| 7   | **Weather & Passage**     | Cloud + sun/rain         | (Future Feature) Offline GRIBs, routing notes & port guides     | (Future) View last downloaded weather (if any)                          | (Future) Download new GRIBs, save multiple routes, port guides, wind/wave overlays                   | Home → Weather & Passage → (Coming Soon)                    |
| 8   | **Crew & Contacts**       | Three people silhouette  | Manage crew details, emergency contacts        | View only                                                      | Add/edit crew, medical info, passport copies, emergency checklist                           | Home → Crew & Contacts → Crew List → Crew Member Detail                                          |
| 9   | **Inventory**             | Box stack                | Complete boat inventory (not just spares)      | View only                                                      | Full CRUD inventory, locations (locker labels), low-stock alerts                            | Home → Inventory → Location → Item List → Item Detail                                            |
| 10  | **Fuel & Water Log**      | Fuel pump + water drop   | Track consumption and tank levels              | View last 7 entries                                            | Unlimited logging, graphs, range calculations, refill reminders                             | Home → Fuel & Water → Tank Selection → Log History + Charts                                      |
| 11  | **Menus**                 | Chef hat                 | Onboard meal planning with ingredient tracking | View bundled menus, check ingredient availability             | Create custom recipes, edit ingredients, full recipe management                                | Home → Menus → Recipe Categories → Recipes → Recipe Details + Ingredients                        |
| 12  | **Cocktails**             | Cocktail glass           | Drink recipes with ingredient availability      | View bundled cocktails, check ingredient availability         | Create custom drinks, edit ingredients, full recipe management                                 | Home → Cocktails → Recipe Categories → Recipes → Recipe Details + Ingredients                    |

## Navigation Hierarchy

All apps follow a consistent 4-level navigation structure:

```
App List Screen → Category/List Screen → Item Screen → Item Detail Screen

Examples:
• Checklists → Checklist Groups → Checklist Items → Item Details + History
• Shopping → Categories → Shopping Items → Item Details
• Menus → Recipe Categories → Recipes → Recipe Details + Ingredients
• Captain's Log → Date List → Log Entries → Log Details
```

### Screen Types

#### App List Screen (Home Grid)
- **Purpose**: Select which app to use
- **Features**: Large tiles, consistent across all apps
- **Navigation**: Tap any tile → Category/List Screen

#### Category/List Screen
- **Purpose**: Browse categories or lists within an app
- **Features**:
  - Search bar (top)
  - Sort/Filter button (three lines menu in app bar)
  - Add button (Pro only, FAB)
  - Swipe actions on items
- **Navigation**: Tap category/list → Item Screen

#### Item Screen
- **Purpose**: View items within a category/list
- **Features**:
  - Search bar (top)
  - Sort/Filter button (three lines menu in app bar)
  - Add button (Pro only, FAB)
  - Swipe actions on items
  - Bulk actions (select multiple, delete, etc.)
- **Navigation**: Tap item → Item Detail Screen

#### Item Detail Screen
- **Purpose**: View/edit individual item details
- **Features**:
  - Full item information
  - Edit button (Pro only)
  - History/timeline (Pro only)
  - Photos and notes
  - Completion actions
- **Navigation**: Back to Item Screen

### Sorting & Filtering (All List Screens)

All list screens (Category/List and Item screens) include:

**App Bar Actions:**
- Three horizontal lines menu button (≡) for sort/filter options

**Sort Options (universal):**
- Name (A-Z / Z-A)
- Date Created (newest/oldest first)
- Date Added (newest/oldest first)
- Completion Status (completed/not completed first)

**Filter Options (app-specific):**
- Checklists: All, Completed, Incomplete, Hidden
- Shopping: All, Bought, Not Bought, By Category
- Recipes: All, Quick, Easy, Vegetarian, By Category
- Captain's Log: All, This Week, This Month, By Date Range

## Detailed Screen Flows & Free/Pro Gates

### 1. Checklists (most restricted in Free)

- Group List → Checklist → Item List
  - Free: can only view
  - Tap any checkbox / edit / + button → Snackbar: “Checklists are read-only in Free → Go Pro to mark complete, add notes or edit”
  - Swipe actions completely disabled in Free
- Item Detail (Pro only)
  - Large bundled photo + user photos
  - Completion timeline (who/when)
  - Notes field
  - “Mark as Complete” floating button

### 2. Shopping & Spares (fully usable in Free - the main hook)

- Top level: Origin categories (Galley, Spares, Bar, etc.) with total budget prices summed from items below
- Items can be added from anywhere in the app via tap/long press/context menu on any item in lists
- When shopping: tick as "Provisioned" → item automatically appears as present in galley/spares/bar inventory
- Price tracking: shows last purchase price, date, and location (notes field)
- Categories pre-seeded and customizable
- Full swipe support even in Free
- Pro adds sync across devices & crew, export to PDF/CSV

### 3-10. All other apps

- Free = read-only or very limited history (7 days)
- Any attempt to add/edit/delete/complete → same upgrade snackbar
- All lists use identical swipe behaviour (see below)

### 11. Menus

- Meal List → Meal Detail
  - Free: view bundled meals, ingredient availability indicators (green=all available, red=missing some)
  - Pro: create custom meals, edit recipes
- Meal Detail (Pro only for editing)
  - Ingredient list with availability colors/marks (green=available, red=missing)
  - Preparation instructions
  - Tap ingredient → Ingredient Detail
- Ingredient Detail (Pro only)
  - Edit photo, name (dropdown from inventory/shopping + add new), quantity + unit (teaspoon, tablespoon, cup, etc.), substitute, garnish checkbox, optional checkbox

### 12. Cocktails

- Drink List → Drink Detail
  - Free: view bundled drinks, ingredient availability indicators
  - Pro: create custom drinks, edit recipes
- Drink Detail (Pro only for editing)
  - Ingredient list with availability colors/marks
  - Mixing instructions
  - Tap ingredient → Ingredient Detail (same as Menus)

## Universal List Item Layout (consistent across all apps)

All list items follow the same 3-line layout (enhanced from previous app for better consistency):

```
┌─────────────────────────────────────────────────────────────┐
│ [Icon/Photo] [Item Name (bold, largest)]                    │
│ [Description/Notes (medium, truncated)]                    │
│ [Creation/Add Date (smallest, bottom right)]               │
└─────────────────────────────────────────────────────────────┘
```

**Photo/Icon Priority:**
1. User-uploaded photo (resized, compressed, stored in app folder)
2. Asset/bundled photo from assets
3. Clickable camera icon for photo upload

**Date Display:**
- Shows creation date for new items
- Shows add date for items added to lists
- Shows completion/purchase date when applicable

**Status-Based Coloring (from previous app, for intuitive UX):**
- Completed/Provisioned: Teal background/text for positive actions
- Incomplete/To Do: Grey for neutral state
- Hidden/Deleted: Dark grey with strikethrough for soft-deleted items
- Not Available (e.g., out of stock): Red background/text for alerts

## Comprehensive History Tracking (Pro Feature)

All item types maintain complete snapshots of their state at different points in time, stored in dedicated history tables without images (text-only records).

### History Snapshot Tables

**ChecklistItemHistory**: Complete snapshots of checklist items
- Stores full item record at creation, completion, notes changes, etc.
- Reference to original item via `itemSupabaseId`
- Timestamp and reason for each snapshot
- Text-only (no image data)

**ShoppingItemHistory**: Complete snapshots of shopping items
- Stores full item record at creation, purchase, price changes, etc.
- Tracks price history, location changes, quantity updates
- Reference to original item via `itemSupabaseId`

### History Display

**Timeline View** (Pro users only):
- List of complete item snapshots (newest first)
- Each entry shows the full item state at that point in time
- Color-coded entries with appropriate icons
- Relative timestamps ("2 hours ago", "3 days ago", etc.)
- Tap to view complete item details from that snapshot

**Snapshot Triggers:**
- **Item Creation**: Automatic snapshot when item is first created
- **Status Changes**: Completion, hiding, purchasing events
- **Field Updates**: Notes, prices, locations, quantities
- **Manual Saves**: When user explicitly saves changes

### Benefits of Snapshot Approach

- **Complete State**: Shows exactly what the item looked like at any point
- **Easy Display**: Full item record can be displayed directly in list
- **Audit Trail**: Perfect for compliance and debugging
- **No Complexity**: Simple to implement and understand
- **Storage Efficient**: Text-only, no duplicate images

## Universal Swipe Behaviour (used in every scrollable list)

| Direction   | Visible item (not hidden)              | Already hidden item (when “Show hidden items” = ON) |
| ----------- | -------------------------------------- | --------------------------------------------------- |
| Swipe Left  | Dark grey “Hide” + action buttons      | Red “Permanently Delete”                            |
| Swipe Right | Teal “Complete” (or “Uncomplete”)      | Undo Hide                                           |

Action buttons on left swipe:
- Add to Shopping List
- Toggle In/Out of Stock

## Item Color Coding (universal across all lists)

| Status              | Text Color     | Background Color | Notes                          |
| ------------------- | -------------- | ---------------- | ------------------------------ |
| Completed           | Pleasant teal  | Darker teal      | Items marked as done           |
| Not completed       | Light grey     | Darker grey      | Default state                  |
| Hidden              | Dark grey      | Darker grey      | Soft deleted, shown when toggled|
| Not available       | Pleasant red   | Darker red       | Ingredients/recipes out of stock|

## Consistent Menu System (End Drawer, from previous app for intuitive UX)

All list screens include an end drawer (accessible via ≡ menu button in app bar) with consistent options:

**Universal Options:**
- **Show Hidden Items**: Toggle to reveal soft-deleted items with strikethrough
- **Reset Database to Factory**: Warning dialog → restores bundled data, keeps Pro status (available in all apps)
- **Upgrade to Pro**: Opens paywall (if not Pro)
- **Sign In/Out**: Shows current user or "Not logged in"
- **About**: Version, links, disclaimer

**App-Specific Filters & Sorts (in drawer):**
- **Filter Options:**
  - Search box: partial match on all text fields (name, description, notes, etc.)
  - Status filters (All, Completed, Incomplete, Hidden)
  - Category filters (where applicable)
- **Sort Options:**
  - Original seed insert order
  - Name (A-Z / Z-A)
  - Completed status (completed first / not completed first)
  - Price (low to high / high to low)
  - Date created/added (newest/oldest first)

Hidden items appear with strikethrough + small trash icon when "Show hidden items" is enabled.



**Additional Features from Previous App Not Yet Integrated:**
- **CheckPageViewer**: Swipeable full-screen viewer for browsing checklist items (like a photo gallery)
- **Full Group CRUD UI**: Dismissible group cards with soft delete/restore, complete editing flow for groups
- **App Bar Subtitles**: Dynamic subtitles showing database type ("Online Database: [username]" or "Local Database: [user], subscription expired")
- **Group Dismissible Actions**: Swipe left-to-right on group cards for soft delete/restore

## Top Status Bar (always visible on every screen)
```

┌────────────────────────────────────────────────────────────────┐
│ Sisu Mate Pro • Online 14:32 89% │
└────────────────────────────────────────────────────────────────┘

```

Colour rules (entire accent colour of the app changes):
- Pro + Online   → Green (#2e8b57)
- Pro + Offline  → Amber (#f39c12)
- Free + Online  → Blue (#3498db)
- Free + Offline → Grey (#7f8c8d)

If multiple boats → boat name shown on left side.

## Settings Screen (identical across all apps)

All settings stored in Isar + synced (Pro only):

| Option                     | Behaviour                                                                                   |
|----------------------------|---------------------------------------------------------------------------------------------|
| Active Boat                | Dropdown (Pro = unlimited, Free = only 1)                                                   |
| Show hidden items          | Toggle (applies globally to all lists)                                                      |
| Reset to factory checklists| Warning dialog → wipes all custom data, restores original bundled checklists (keeps Pro status) |
| Upgrade to Sisu Mate Pro| Opens RevenueCat paywall with beautiful feature comparison                                  |
| Sign in / Sign out         | Shows current email or “Not signed in”                                                      |
| About                      | App version, SailingSisu YouTube link, privacy policy, legal disclaimer                     |

## Future App Ideas (already reserved icons & colour slots)

13. Expenses & Budget
14. Watch Schedule
15. Radio Log
16. Medical Kit Inventory
17. Starlink & Comms Log
18. Dive Gear Manager

```
