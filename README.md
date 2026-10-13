# Sport App

Minimalistische gym-workout-tracker voor iPhone (SwiftUI, iOS 16+).

- `docs/DESIGN.md`: ontwerpdocument, de bron voor uiterlijk en gedrag
- `docs/prototype/`: klikbaar HTML-prototype
- `reference/SportApp_stap1.zip`: eerste versie (alleen de Domain-map en WorkoutStore zijn hergebruikt)
- `SportApp/`: de app (`Domain`, `Data`, `Design`, `App`, `Resources`)
- `SportAppTests/`: unit tests
- `project.yml`: beschrijving van het Xcode-project (XcodeGen)

## Project openen in Xcode

Het Xcode-project (`SportApp.xcodeproj`) wordt door CI gemaakt en na elke merge op `main` in de repository gezet.
Haal `main` binnen (Xcode: Source Control > Pull) en open `SportApp.xcodeproj`.

## CI

Elke push bouwt de app voor de iPhone-simulator, draait de tests en maakt screenshots. De uitkomst staat op de
branch `ci-results` onder `results/<branchnaam>/` (status, samenvatting en screenshots).
