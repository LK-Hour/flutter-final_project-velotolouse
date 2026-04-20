# VeloToulouse — Final Flutter Project

This repository contains our **final Flutter Advanced project** for a bike-sharing app experience inspired by VeloToulouse.

The app currently focuses on the **station map flow (User Story 2)**:
- Discover nearby bike stations on a map-style screen
- Switch between renting and return mode
- View station capacity details
- Handle full-station return with reroute suggestion

## Tech Stack

- **Flutter** (Dart SDK `^3.10.8`)
- **State management:** `provider`
- **Architecture:** MVVM + Repository pattern
- **Preview tooling:** `device_preview` (enabled in non-release builds)

## Project Structure

```text
lib/
  data/
    repositories/           # Mock repository implementations
  domain/
    model/                  # Domain entities (e.g., Station)
    repositories/           # Repository contracts
  ui/
    screens/station_map/
      view_model/           # ChangeNotifier view model
      widgets/              # Reusable UI components
  app.dart                  # MaterialApp setup
  main.dart                 # Entry point
  main_dev.dart             # Dev providers wiring
  main_common.dart          # Shared runApp bootstrap
```

## Implemented User Story (Current)

### User Story 2: Smart return station flow

Implemented behaviors include:
- Loading station data via repository abstraction
- Selecting station markers and opening station detail popup
- Switching to return mode after scan-based bike unlock (debug toggle kept for testing)
- Showing dock availability based on active mode
- Returning bike at a selected station with free docks (exits return mode)
- Updating station availability immediately after successful return
- Marking full stations in return search and preventing invalid selection
- Showing a clear "No docks available" hint for disabled return-search stations
- Keeping station search available in return mode once the banner is dismissed
- Using return-mode specific search prompt: "Find a station with free docks..."
- Sorting return search results to show stations with free docks first
- Showing return-mode empty state: "No station with free docks found"
- Marking empty-bike stations in renting search and preventing invalid selection
- Showing a clear "No bikes available" hint for disabled renting-search stations
- Sorting renting search results to show stations with bikes first
- Suggesting nearest bike station when selected renting station has no bikes
- Suggesting alternative stations when selected return station has no free docks
- Showing reroute confirmation feedback after auto-selecting suggested station
- Showing a return-mode bottom status label: "Return in progress"
- Bottom action area with ride/profile + scan button

## Run the Project

```bash
flutter pub get
flutter run
```

## Development Commands

```bash
flutter analyze
flutter test
```

## Device Preview

`device_preview` is integrated and wrapped at app bootstrap:
- Enabled automatically for non-release builds
- Disabled in release builds

This helps test responsive layouts quickly across multiple virtual devices.

## Notes

- Current design assets available in this repo are centered on **User Story 2**.
- Mock station data is currently configured around **Phnom Penh, Cambodia**.
- Work is being delivered incrementally with small, reviewable steps.
