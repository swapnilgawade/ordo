# Ordo

Ordo is an app for building ranked lists. You don't drag a new item into
place. Ordo asks a few "which do you prefer?" questions and works out where the
item belongs, using binary search. Even a 1,000-item list needs at most 10
questions.

It runs on iOS, Android, web, Windows, macOS and Linux from one Flutter codebase.

## What works today (step 2: core app, offline)

- Create, rename and delete lists
- Add items with a name, a note and a photo
- Rank a new item through comparisons, with **Back**, **Too close** and
  **Undo last answer**
- Stop part-way and the item waits in a "Not ranked yet" tray
- Drag to fine-tune the order, or re-rank an item with questions
- Everything is saved on the device (SQLite) and survives restarts

Sign-in, sync across devices, sharing and export come in step 3.

## How it is built

| Folder | What it holds |
| --- | --- |
| `lib/ranking/` | `InsertionSession` (the binary-search question flow) and `rank_key.dart` (sortable position keys) |
| `lib/data/` | Drift database tables and the `Repository` that screens use |
| `lib/screens/` | Home, list, item editor and compare screens |
| `lib/widgets/` | Shared pieces such as the raised card and item photo |
| `web/` | `sqlite3.wasm` and `drift_worker.js`, which the web build needs for storage |

Each item stores its position as a sortable string key. Moving or inserting an
item changes only that item's key, which keeps sync simple later.

## Running it

Install [Flutter](https://docs.flutter.dev/get-started/install) (stable, 3.50 or
newer), then:

```sh
flutter pub get
dart run build_runner build   # regenerates lib/data/database.g.dart after table changes
flutter run                   # pick a device: Chrome, macOS, an emulator, ...
flutter test
```

To build the website:

```sh
flutter build web --release
```

The web files `sqlite3.wasm` (sqlite3 3.9.2) and `drift_worker.js` (drift 2.35.4)
must match the package versions in `pubspec.lock`. When upgrading drift or
sqlite3, download the matching files from their GitHub releases.
