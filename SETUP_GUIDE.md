# 🌳 FamilyTree Flutter App — Setup Guide
### Email Auth + Local Storage + Horizontal Tree

---

## What's Inside

### Authentication (3 screens)
| Screen | Features |
|--------|---------|
| **Login** | Email + password, show/hide password, Remember Me toggle, Forgot Password link, register link, loading state |
| **Register** | Full name, email, password with **strength indicator** (Weak/Fair/Good/Strong), confirm password, terms checkbox |
| **Forgot Password** | Email form → animated success state ("check your inbox") |
| **Settings** | Change password with current password verification, account info display |

Passwords are **SHA-256 hashed** with a salt — never stored in plain text. Each user has isolated family tree data.

---

### Family Tree Features — All Buttons Working

| Button | Function |
|--------|---------|
| ✏️ **Edit** | 3-tab form (Basic Info, Details, Contact) |
| 🔗 **Add Parent** | Pick from member list → bidirectional link |
| 👶 **Add Child** | Pick from member list → bidirectional link |
| 💍 **Add Spouse** | Pick from member list → dashed heart line |
| 👥 **Add Sibling** | Pick from member list → bidirectional link |
| 🔗 **Link** | Add new person then pick their role |
| ⛓ **Unlink** | Shows existing connections → remove any |
| 🔄 **Update** | Same as Edit (opens form pre-filled) |
| 🗑 **Delete** | Removes person + auto-cleans all links |

### Tree Canvas (Horizontal Left→Right)
- **Roots on left**, children expand to the right
- **Curved bezier lines** for parent→child (blue)
- **Dashed heart lines** for spouses (rose)
- **Dashed teal lines** for siblings
- **Arrow heads** on parent→child lines
- **Pan + pinch-zoom** (mouse scroll + touch)
- **Click a node** = open detail panel
- **Hover glow** + scale animation on nodes

---

## File Structure

```
lib/
├── main.dart                         ← Entry point, auth router, splash
├── utils/
│   └── theme.dart                    ← All colors, theme, shared decoration
├── models/
│   ├── person.dart                   ← Person model + relationships
│   └── app_user.dart                 ← Auth user model
├── providers/
│   ├── auth_provider.dart            ← Login, register, logout, password
│   └── family_provider.dart         ← Full CRUD + all relationship ops
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         ← Login UI
│   │   ├── register_screen.dart      ← Register UI + pw strength bar
│   │   └── forgot_screen.dart        ← Forgot pw + animated sent state
│   ├── home_screen.dart              ← Shell: sidebar, tabs, search, FAB
│   └── settings_screen.dart          ← Change pw, stats, danger zone
└── widgets/
    ├── person_node.dart              ← PersonAvatar + PersonNode card
    ├── tree_canvas.dart              ← Horizontal tree + connection painter
    ├── person_form_dialog.dart       ← Add/edit dialog (3 tabs)
    ├── link_dialog.dart              ← Link/unlink member picker
    └── detail_panel.dart             ← Right panel: profile, actions, relations
```

---

## Quick Start (4 commands)

```bash
# 1. Enable Flutter web (one time only)
flutter config --enable-web

# 2. Enter project folder
cd family_tree

# 3. Install packages
flutter pub get

# 4. Run
flutter run -d chrome
```

---

## Step-by-Step Setup

### Step 1 — Install Flutter
- Windows: https://docs.flutter.dev/get-started/install/windows
- macOS: `brew install --cask flutter`  
- Linux: https://docs.flutter.dev/get-started/install/linux

After installing:
```bash
flutter doctor        # check setup
flutter --version     # needs 3.0+
```

### Step 2 — Project Folder Structure
Create this layout and copy all provided files into it:

```
family_tree/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── utils/theme.dart
    ├── models/person.dart
    ├── models/app_user.dart
    ├── providers/auth_provider.dart
    ├── providers/family_provider.dart
    ├── screens/auth/login_screen.dart
    ├── screens/auth/register_screen.dart
    ├── screens/auth/forgot_screen.dart
    ├── screens/home_screen.dart
    ├── screens/settings_screen.dart
    ├── widgets/person_node.dart
    ├── widgets/tree_canvas.dart
    ├── widgets/person_form_dialog.dart
    ├── widgets/link_dialog.dart
    └── widgets/detail_panel.dart
```

### Step 3 — Install dependencies
```bash
flutter pub get
```

**Packages installed:**
| Package | Purpose |
|---------|---------|
| `provider ^6.1.1` | State management |
| `shared_preferences ^2.2.2` | Local storage (users + tree data) |
| `uuid ^4.3.3` | Unique IDs |
| `google_fonts ^6.2.1` | Inter font |
| `crypto ^3.0.3` | SHA-256 password hashing |
| `flutter_animate ^4.5.0` | Animations (fade, slide, scale) |
| `intl ^0.19.0` | Date formatting |

### Step 4 — Run
```bash
# Chrome (web)
flutter run -d chrome

# Android
flutter run -d android

# iOS (Mac only)
flutter run -d ios

# With a specific port
flutter run -d chrome --web-port=3000
```

---

## How to Use the App

### First time
1. Open → **Login screen** appears
2. Tap **"Create one"** → Register screen
3. Fill name, email, password → **"Create Account"**
4. You're in! Empty tree greets you

### Adding members
1. Click **"Add Person"** button (top bar on desktop / FAB on mobile)
2. Fill the 3-tab form:
   - **Basic Info**: gender, name, birth/death date, alive toggle
   - **Details**: birthplace, nationality, occupation, religion, education, bio
   - **Contact**: phone, email
3. Click **"Add Person"** → appears as a node in the tree

### Connecting people
1. **Click a node** in the tree (or a row in Members list)
2. Detail panel opens on the right (desktop) or bottom sheet (mobile)
3. Use the **9 action buttons**:
   - Add Parent / Child / Spouse / Sibling → opens member picker
   - Link → create new person, then pick role
   - Unlink → pick which connection to remove
   - Edit / Update → re-opens the form pre-filled
   - Delete → removes with confirmation

### Tree navigation
- **Scroll wheel** = zoom in/out
- **Click + drag** = pan around the canvas
- **Click any node** = select and show detail panel
- **Click again** = deselect

---

## Build for Production

```bash
# Web (deploy to Netlify, Vercel, Firebase, etc.)
flutter build web --release
# → files in build/web/

# Android APK
flutter build apk --release

# iOS (Mac only)
flutter build ios --release
```

---

## Extending the App

### Add more fields to Person
In `lib/models/person.dart` add your field, then update `toJson()`, `fromJson()`, and `copyWith()`. Add the input to the form in `person_form_dialog.dart`.

### Switch to Firebase backend
1. Add `firebase_core`, `firebase_auth`, `cloud_firestore` to pubspec
2. Replace `shared_preferences` in `auth_provider.dart` with Firebase Auth
3. Replace `shared_preferences` in `family_provider.dart` with Firestore

### Add profile photos
The `image_picker` package can be added to pubspec. In `PersonAvatar`, replace initials with a `NetworkImage` or `FileImage`.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter: command not found` | Add Flutter's `bin/` to your PATH |
| `No connected devices` | Run `flutter config --enable-web`, then `flutter devices` |
| Packages not found | Run `flutter pub get` inside the project folder |
| Tree nodes overlap | BFS layout is simple — complex trees may need manual spacing adjustment |
| Session not restoring | Check that "Remember Me" was checked at login |
| Can't log in after registering | Data is stored per browser — use the same browser |
