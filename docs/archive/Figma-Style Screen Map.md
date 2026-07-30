# Figma-Style Screen Map - Sisu Mate (v3.0)

Ready to import directly into Figma as frames or to hand to your UI/UX designer  
(Exact naming, hierarchy, and flow as in your final PRD + apps.md)

```
MAIN FLOW - Mobile (iPhone 15 Pro / Pixel 8 size - 393×852 pt)
All screens use the unified TitleTile header with context-aware titles and status information.
All lists use the exact same swipe behaviour (Right = Teal Complete | Left = Dark-grey Hide + action buttons → Red Permanent Delete).
All lists include search filter and sort options (original, name, completed, price).
Menu buttons are integrated into TitleTile for screens with drawers.
```

### 0 Splash & Onboarding (only seen once)

```
0.1 Splash Screen                  → auto → 0.2
0.2 Welcome - Beautiful Leopard 45 photo
0.3 Permission requests (Location, Photos, Notifications)
0.4 Sign-in options (Magic Link / Apple / Google / Skip for now → Free mode)
→ goes to 1. Home
```

### 1 Home - Sisu Mate Suite Grid

```
1. Home (2×6 breathing tiles)

┌─ TitleTile Header ─────────────────────────────────────┐
│  Sisu Mate                                              │
│  Boat Name • Free/Pro • Online/Offline • Username       │
└───────────────────────────────────────────────────────┐
│  Checklists          Shopping & Spares                     │
│  Captain’s Log       Maintenance Scheduler                 │
│  Safety Briefings    Documents Vault                        │
│  Crew & Contacts     Inventory                              │
│  Fuel & Water Log    Menus                                  │
│  Cocktails           Settings                               │
└────────────────────────────────────────────────────────────┘
```

### 2 Hierarchical Navigation Structure

All apps follow a consistent 4-level navigation hierarchy:

```
App List Screen → Category/List Screen → Item Screen → Item Detail Screen

Examples:
• Checklists → Checklist Groups → Checklist Items → Item Details + History
• Shopping → Categories → Shopping Items → Item Details
• Menus → Recipe Categories → Recipes → Recipe Details + Ingredients
• Captain's Log → Date List → Log Entries → Log Details
```

#### 2.1 App List Screen (Home Grid)
- **Purpose**: Select which app to use
- **Features**: Large tiles, consistent across all apps
- **Navigation**: Tap any tile → Category/List Screen

#### 2.2 Category/List Screen
- **Purpose**: Browse categories or lists within an app
- **Features**:
  - Search bar (top)
  - Sort/Filter button (three lines menu in app bar)
  - Add button (Pro only, FAB)
  - Swipe actions on items
- **Navigation**: Tap category/list → Item Screen

#### 2.3 Item Screen
- **Purpose**: View items within a category/list
- **Features**:
  - Search bar (top)
  - Sort/Filter button (three lines menu in app bar)
  - Add button (Pro only, FAB)
  - Swipe actions on items
  - Bulk actions (select multiple, delete, etc.)
- **Navigation**: Tap item → Item Detail Screen

#### 2.4 Item Detail Screen
- **Purpose**: View/edit individual item details
- **Features**:
  - Full item information
  - Edit button (Pro only)
  - History/timeline (Pro only)
  - Photos and notes
  - Completion actions
- **Navigation**: Back to Item Screen

### 3 Checklists Flow (most restricted in Free)

```
3.1 App List → Checklists (from home)
3.2 Checklist Groups Screen (Category/List level)
    • Daily Engine Checks
    • Weekly Checks
    • Monthly
    • Annual Sisu Mate
    • Pre-Passage
    • Watch-Keeping Checks
    • Safety Briefings
    • Documents Checklist
    → Tap group → 3.3

3.3 Checklist Items Screen (Item level)
    Free: checkboxes disabled, no + button, no swipe disabled
    Pro: full swipe, reorder, + button, sort/filter menu
    → Tap item → 3.4

3.4 Item Detail Screen (Detail level)
    • Huge bundled photo (full width)
    • Title + Description
    • Completion timeline (who/when) - embedded HistoryList
    • User photos grid
    • Notes field
    • Mark Complete FAB (green)
    • Back → 3.3
```

### 3 Shopping & Spares Flow (fully works in Free - the “hook”)

```
3.1 Origin Categories (with budget totals)
    • Galley ($245.50)    • Spares ($1,230.75)    • Bar ($89.25)    • ...
    → Tap → 3.2

3.2 Items in Origin Category (full swipe even in Free)
    [Search Box] [Sort: Name ▼]
    Swipe Right → Teal “Provisioned” (or “Unprovisioned”)
    Swipe Left  → Dark-grey “Hide” + [Add to Shopping] [In/Out Stock] → Red “Delete forever”
    + FAB → 3.3 Add/Edit Item (with price tracking)
```

### 4 Captain’s Log Flow

```
4.1 Calendar or Month/Week/List view
    Free: only last 7 days visible
    Pro: full scrollable history
    → Tap date → 4.2

4.2 Log Entry Detail
    Free: read-only
 Pro: edit text, add photos, auto GPS/weather
```

### 5 Maintenance Scheduler Flow

```
5.1 Equipment List (Engine STB, Engine Port, Generator, Watermaker…)
    → Tap → 5.2

5.2 Equipment Detail
    • Current running hours
    • Upcoming services list
    • + Log service button (Pro only)
```

### 6 Safety Briefings Flow

```
6.1 Briefing Types
    • Day Guests
    • New Crew
    • Passage Briefing
    • Abandon Ship
    → Tap → 6.2 Script (scrollable with large text + read-aloud button Pro)
```

### 7 Documents Vault Flow

```
7.1 Categories (Passports, Boat Papers, Insurance, Qualifications)
    → Tap → 7.2 Document Grid (with expiry countdown badges)
```

### 8 Settings Screen (identical everywhere)

```
┌─ TitleTile Header ─────────────────────────────────────┐
│  Settings                                              │
│  Boat Name • Free/Pro • Online/Offline • Username      │
└───────────────────────────────────────────────────────┘

Active Boat                Boat ▼          (Free = greyed if >1)
Show hidden items          Toggle OFF
Reset to factory checklists → Warning dialog
Upgrade to Sisu Mate Pro → RevenueCat paywall
Sign in with email         hello@sisu.com    Sign out
About                      v2.4.1 • Privacy • Disclaimer
```

### Upgrade Paywall Modal (shown on any restricted action in Free)

```
┌────────────────────────────────────────────────────────────┐
│                   Unlock Sisu Mate Pro                   │
│  • Mark items complete & add notes                         │
│  • Unlimited history & photos                              │
│  • Real-time crew sync                                     │
│  • Multiple boats                                          │
│  • No ads                                                  │
│                                                            │
│  $6.99 / month      $59.99 / year (2 months free)          │
│                     [Start Free Trial]                     │
│                     [Restore Purchase]                     │
└────────────────────────────────────────────────────────────┘
```

### Colour System (exact hex for Figma)

```
Primary / Pro + Online      #2e8b57 (sea green)
Pro + Offline               #f39c12 (amber)
Free + Online               #3498db (blue)
Free + Offline              #7f8c8d (grey)
Complete / Bought           #27ae60 (emerald)
Hide                        #34495e (dark grey)
Permanent Delete            #c0392b (red)
Background                  #f8fafc
Card                        #ffffff
Text Primary                #1a2a44

Item Status Colors:
Completed                   #40e0d0 (turquoise) on #006666 (dark teal)
Not Completed               #d3d3d3 (light grey) on #696969 (dark grey)
Hidden                      #a9a9a9 (dark grey) on #696969 (dark grey)
Not Available               #ff6b6b (coral red) on #cc0000 (dark red)
```

### Figma File Structure (copy-paste this into Figma “Pages” or “Files”)

```
Sisu Mate 3.0
 ├─ 0 Onboarding
 ├─ 1 Home Grid
 ├─ 2 Checklists
 ├─ 3 Shopping & Spares
 ├─ 4 Captain’s Log
 ├─ 5 Maintenance Scheduler
 ├─ 6 Safety Briefings
 ├─ 7 Documents Vault
 ├─ 8 Settings
 ├─ Components
 │   ├─ TitleTile Header (context-aware)
 │   ├─ Common Drawer Sections
 │   │   ├─ AccountSection
 │   │   ├─ DataManagementSection
 │   │   ├─ ProUpgradeSection
 │   │   └─ AboutSection
 │   ├─ App Tile
 │   ├─ List Item (normal / completed / hidden)
 │   ├─ Swipe Actions
 │   ├─ Paywall Modal
 │   └─ Buttons & Snackbar
 └─ Styleguide (colours, typography, shadows)
```
