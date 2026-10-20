# Sport App

Minimalistische gym-workout-tracker voor iPhone (SwiftUI, iOS 26+). App-naam: Set.

- `docs/DESIGN.md`: ontwerpdocument, de bron voor uiterlijk en gedrag
- `docs/prototype/`: klikbaar HTML-prototype
- `reference/SportApp_stap1.zip`: eerste versie (alleen de Domain-map en WorkoutStore zijn hergebruikt)
- `SportApp/`: de app (`Domain`, `Data`, `Design`, `App`, `Resources`)
- `SportAppTests/`: unit tests
- `project.yml`: beschrijving van het Xcode-project (XcodeGen)

## Bouwen en testen op je iPhone

De app vraagt iOS 26 en wordt daarom op GitHub gebouwd (macOS 26 met Xcode 26), niet op de iMac met Xcode 14.2.

1. Ga naar **Actions › IPA › Run workflow**, kies de branch en start.
2. Als de run klaar is (groen), download onderaan de run het artifact **Set-ipa** en pak de zip uit: daarin zit `Set.ipa`.
3. Zet `Set.ipa` met Sideloadly op je iPhone (gratis Apple ID; na 7 dagen opnieuw ondertekenen).

Blijft een run lang in de wachtrij staan en stopt hij met "not acquired by Runner", dan had GitHub even geen Mac vrij. Start hem dan later opnieuw.

## CI

Elke push bouwt de app voor de iPhone-simulator, draait de tests en maakt screenshots. De uitkomst staat op de
branch `ci-results` onder `results/<branchnaam>/` (status, samenvatting en screenshots).
