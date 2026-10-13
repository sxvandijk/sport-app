# Sport App: ontwerpdocument

Versie 1 · 13 oktober 2026 · voor SwiftUI, minimaal iOS 16 (Xcode 14.2)

Dit document beschrijft hoe de app eruitziet en zich gedraagt. Het klikbare prototype (canvas "Sport App – ontwerp") laat dit zien. Bij twijfel geldt dit document.

---

## 1. Uitgangspunten

- De app draait alleen om trainen: snel een training starten, snel sets invullen, geen sociale feed.
- Rustig en donker-eerst, met één accentkleur. De lichte modus heeft dezelfde opbouw.
- Zo min mogelijk tikken. Alles wat je tijdens een set nodig hebt zit onderin, binnen duimbereik.
- Grote cijfers met vaste cijferbreedte (`.monospacedDigit()`) voor gewicht, reps en timers.
- Weinig lijnen, geen schaduwen, geen kaarten in kaarten. Vlakken onderscheiden zich alleen door kleur.
- Aanraakvlakken zijn minimaal 44 × 44 pt, ook als het zichtbare element kleiner is.
- **Niet gebruiken:** Liquid Glass, `.glassEffect`, `.sensoryFeedback`, `@Observable`, `ContentUnavailableView`, en verder alles wat iOS 17 of hoger nodig heeft. Haptiek gaat via `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`.
- **Taal:** knoppen, uitleg en spiergroepen zijn in het Nederlands. Namen van oefeningen en machines zijn in het Engels.

---

## 2. Kleuren

Maak elke kleur in de Asset Catalog als *Color Set* met een donkere en een lichte variant (Appearance: Any/Dark). Gebruik in code alleen de tokennamen, nooit losse hexwaarden.

| Token | Donker | Licht | Gebruik |
|---|---|---|---|
| `bg` | `#0D0E10` | `#F4F4F1` | Achtergrond van elk scherm, tabbalk |
| `surface` | `#17191C` | `#FFFFFF` | Open oefening, invoerdock, sheets, blokken op startscherm |
| `raised` | `#22252A` | `#EBEBE6` | Knoppen in een vlak, +/−, chips, minibalk, huidige setrij |
| `line` | `#33373D` | `#D9D9D3` | Schakelaar uit, lege ring, grijper van een sheet |
| `track` | `#2A2E33` | `#E1E1DC` | Achtergrond van voortgangslijn en balken |
| `text` | `#F3F4F6` | `#121316` | Hoofdtekst en cijfers |
| `text2` | `#A9AEB6` | `#50545B` | Labels, samenvattingen, ondertitels |
| `text3` | `#858B94` | `#6A6F77` | Geplande (nog niet gedane) waarden, hints |
| `warm` | `#F5B54A` | `#9A5B00` | Warming-up (label **W**) |
| `drop` | `#B9A6FF` | `#6A4FD0` | Dropset (label **D**) |
| `danger` | `#FF6B5E` | `#C9362B` | Verwijderen, stoppen, tot falen (label **F**) |
| `onDanger` | `#0D0E10` | `#FFFFFF` | Tekst op `danger` |
| `inverse` / `onInverse` | `#F3F4F6` / `#0D0E10` | `#121316` / `#F4F4F1` | Melding "Set verwijderd" |
| `scrim` | zwart 60 % | `#121316` 32 % | Achter een sheet |

### 2.1 Accentkleur (zelf te kiezen)

De gebruiker kiest de accentkleur bij **Profiel › Weergave**. Standaard is dat Olijf.

| Naam | Hex | Soort |
|---|---|---|
| Olijf (standaard) | `#556B2F` | donker |
| Viola | `#5A2D82` (benadering van Lamborghini Viola Pasifae) | donker |
| Limoen | `#C6F25A` | licht |
| Mint | `#5EE6B0` | licht |
| IJsblauw | `#7CC4FF` | licht |
| Roze | `#FF9AC8` | licht |

Uit de gekozen accentkleur `A` maak je vier afgeleide tokens. Een kleur telt als **donker** als de relatieve luminantie (WCAG) onder 0,3 ligt.

| Token | Lichte accent, donkere modus | Lichte accent, lichte modus | Donkere accent, donkere modus | Donkere accent, lichte modus |
|---|---|---|---|---|
| `accent` (vlakken) | A | A | A | A |
| `onAccent` (tekst op accent) | `#0D0E10` | `#121316` | `#FFFFFF` | `#FFFFFF` |
| `accentText` (tekst en iconen) | A | A, 55 % naar zwart | A, 55 % naar wit | A |
| `accentLine` (voortgang, schakelaar aan) | A | A, 30 % naar zwart | A, 35 % naar wit | A |
| `accentSoft` (zachte vulling) | A op 18 % | A op 45 % | A op 40 % | A op 22 % |

Waarom: tekst moet altijd een contrast van minstens 4,5 : 1 halen. Daarom staat er witte tekst op olijf en paars. In de donkere modus is de tekst- en lijnkleur iets lichter, anders verdwijnt die tegen de achtergrond. Amber, koraal en paars zijn bewust geen accent, omdat die al betekenis hebben (warming-up, verwijderen, dropset).

### 2.2 Weergave

**Profiel › Weergave › Modus**: *Systeem* (standaard), *Donker* of *Licht*. Gebruik `.preferredColorScheme(nil / .dark / .light)` op het hoogste niveau.

---

## 3. Typografie

De letter is de systeemletter SF Pro. Gebruik `Font.system(size:weight:)` met `relativeTo:` zodat Dynamic Type blijft werken. Getallen krijgen altijd `.monospacedDigit()`.

| Stijl | Grootte / gewicht | Letterafstand | Voorbeeld |
|---|---|---|---|
| Grote titel | 34 / bold | −0,6 | "Training", "Progressie" |
| Schermtitel | 28–30 / bold | −0,4 | "Push A" in het werkscherm |
| Schematitel | 22 / bold | −0,3 | "Push Pull Legs" |
| Oefening open | 22 / semibold | −0,3 | "Chest press machine" |
| Timer bovenbalk | 22 / semibold, monospacedDigit | −0,3 | 23:14 · ~24 · 10 |
| Waarde in dock | 26 / semibold, monospacedDigit | −0,5 | 55 kg · 10 reps |
| Rusttimer | 22 / semibold, monospacedDigit | 0 | 1:24 |
| Hoofdknop | 17–18 / bold | 0 | "Set klaar" |
| Body | 17 / medium | 0 | Namen in lijsten |
| Subtekst | 13 / regular | 0 | "3 × 55 kg · 10, 9, 9 reps" |
| Sectielabel | 12 / semibold, HOOFDLETTERS | +0,06 em | "MIJN SCHEMA" |
| Tablabel | 11 / semibold | 0 | "Training" |

Decimalen schrijf je met een komma (7,5 kg) en duizendtallen met een punt (48.230 kg). Gebruik een `NumberFormatter` met locale `nl_NL`.

---

## 4. Hoeken, afstanden en maten

**Hoeken** (altijd `RoundedRectangle(cornerRadius:style: .continuous)`):

| Waarde | Waar |
|---|---|
| 8 | Badge (A1, W) |
| 12 | Setrij, invoerveld, stepper in de schema-editor |
| 14 | +/−-balk in de dock, rij in een sheet |
| 16 | Hoofdknop, schemablok, rij met een training |
| 20 | Open oefening, kalenderblok, minibalk |
| 24 | Bovenkant van de dock en van een sheet |
| pil | Chips (Uitleg, Bezet, Superset), Hervat, Wissel |

**Afstanden** (raster van 4 pt): 4 · 8 · 12 · 16 · 20 · 24 · 32.
- Zijmarge van een scherm: 20.
- Binnenmarge van een blok: 16.
- Ruimte tussen secties: 24.
- Tussen rijen in een lijst: 8.

**Vaste maten:**

| Element | Maat |
|---|---|
| Hoofdknop (Set klaar, Start training) | hoogte 52–56 |
| +/−-balk in de dock | hoogte 52, knoppen 48 breed |
| Setrij | hoogte 48 |
| Chip | hoogte 44 |
| Schakelaar | 51 × 31 (iOS-standaard), raakvlak 44 hoog |
| Tabbalk | 50 + onderste veilige zone |
| Minibalk | hoogte 68 |
| Voortgangslijn | 3 hoog |

Er staan nergens schaduwen of lijnen tussen rijen. Rust en afstand doen het werk.

---

## 5. Navigatie

```
TabView (4 tabs)
├─ Training   (startscherm)
├─ Progressie
├─ Gym
└─ Profiel

Los van de tabs (fullScreenCover of NavigationStack-push):
├─ Training-overzicht   (vanaf een training in het schema)
├─ Schema-editor        (nieuwe training / training aanpassen)
├─ Werkscherm           (fullScreenCover, zonder tabbalk)
└─ Afgerond             (na Workout afronden)
```

- Tabicoon en -label van de actieve tab hebben de kleur `accentText`, de andere tabs `text3`.
- Loopt er een training, dan staat de **minibalk** boven de tabbalk, op elke tab.
- iOS 16 heeft `NavigationStack`, dus die mag je gebruiken. `NavigationSplitView` is niet nodig.

---

## 6. Schermen en toestanden

### 6.1 Startscherm (tab Training)

Van boven naar beneden:

1. **Kopregel:** de datum ("dinsdag 13 oktober"), met rechts de gymknop (pin-icoon, gymnaam en een pijltje omlaag). Die opent de sheet *Kies je gym*.
2. **Titel** "Training".
3. **Kalenderblok** (`surface`, hoek 20):
   - Bovenaan een knop over de hele breedte: "Laatst getraind" + "vr 9 okt · 4 dagen geleden", rechts het aantal keer deze week ("2×") en een pijltje.
   - **Ingeklapt (standaard):** alleen deze week, maandag tot en met zondag.
   - **Uitgeklapt:** de afgelopen vijf weken. Het pijltje draait 180°.
   - Dagcellen zijn 32 pt rond met een raakvlak van 42–44:
     - getraind: `accent` met `onAccent`, vet;
     - vandaag: ring van 2 pt in `accentLine`;
     - vandaag en er loopt een training: `accentSoft`;
     - toekomst: `text3`;
     - andere dagen: `text2`.
   - Tik op een dag: onder de week verschijnt "vr 9 okt · Push A · 54 min", "rustdag" of "Vandaag · Push A loopt nog".
4. **Mijn schema:**
   - Een sectielabel, en daaronder een knop met de schemanaam (22 bold) en "3 trainingen · volgende: Pull A", met rechts de chip "Wissel ▾". Die opent de sheet *Kies je schema*.
   - Daaronder een rij per training (`surface`, hoek 16):
     - links: naam, het aantal oefeningen, sets en geschatte minuten, en de spiergroepen;
     - de volgende training in de rotatie krijgt de pil **Volgende** (`accentSoft` met `accentText`);
     - tik op de rij → *Training-overzicht*;
     - rechts een knop **•••** (48 pt) → de sheet *Opties voor deze training*.
   - Daaronder de tekstknop "+ Training toevoegen aan schema" → de schema-editor (nieuw).
   - Lege toestand: "Dit schema heeft nog geen trainingen."
5. **Vrije training:** een rij met een plus-icoon, "Vrije training" en de subtekst "Kies je oefeningen tijdens het trainen".
6. **Minibalk** (alleen als er een training loopt): een stip in `accentLine`, de naam, de verstreken tijd met de huidige oefening, en de pilknop **Hervat**. Tik op de balk of op Hervat → het werkscherm.

**Volgende in de rotatie:** neem de laatst gedane training die in het huidige schema staat. De volgende in de lijst krijgt het label "Volgende"; na de laatste begin je weer bij de eerste. Is er nog niets gedaan, dan is de eerste training de volgende.

**Starten terwijl er al een training loopt:** dan verschijnt de sheet "Er loopt al een workout", met de knoppen **Hervat Push A** (accent) en **Stop Push A en start …** (`danger`-tekst).

### 6.2 Training-overzicht

- **Bovenbalk:** links "‹ Push Pull Legs" (terug), rechts **•••**.
- Daaronder:
  - de naam (30 bold), het aantal oefeningen, sets en minuten, en de spiergroepen;
  - een regel "Vorige keer vr 9 okt · 54 min", of "Nog niet eerder gedaan".
- **Oefeningen:** per rij een badge (blokvolgnummer 1, 2, 3, of A1/A2 bij een superset), de naam, en "W + 3 × 10 · 55 kg · Borst". Boven een superset staat het label "SUPERSET" met een link-icoon.
- **Vast onderin:** de knop **Start training** (accent, hoogte 56).

### 6.3 Opties voor een training (sheet via •••)

- Training aanpassen → de schema-editor.
- Dupliceren → "Push A (2)", die direct onder het origineel in het schema komt.
- Verwijderen uit schema (`danger`). De training zelf blijft bewaard; ze staat alleen niet meer in dit schema.

### 6.4 Schema-editor (training maken of aanpassen)

- **Bovenbalk:** links Annuleer, in het midden "Nieuwe training" of "Training aanpassen", rechts **Bewaar** (`accentText`, vet). Zolang de naam leeg is, is Bewaar gedimd (40 %).
- **Naamveld:** groot (hoogte 56, tekst 22), met de placeholder "Bijv. Push B".
- **Kopregel Oefeningen:** rechts staat "5 · 15 sets · ~36 min".
- **Per oefening** een blok met:
  - een badge bij een superset, de naam, en spiergroep · gewicht;
  - de knoppen ↑ (verplaats omhoog) en prullenbak;
  - twee steppers naast elkaar: sets (1–10) en reps;
  - een schakelaar **Warming-upset** (aan = kleur `warm`).
- **Tussen twee oefeningen** staat een pil **Koppel als superset**. Gekoppeld wordt die "Superset" in `accentSoft` met `accentText`. Gekoppelde oefeningen krijgen de badges A1, A2, …
- **Onderin:**
  - **+ Oefening toevoegen** → de zoeksheet;
  - de hint "Koppel twee oefeningen met de knop ertussen om er een superset van te maken";
  - bij een bestaande training: **Training verwijderen** (`danger`).
- **Bewaren:**
  - een nieuwe training komt in het huidige schema;
  - hernoemen past ook de naam aan in elk schema waarin de training staat;
  - daarna ga je terug naar waar je vandaan kwam (het overzicht of het startscherm).

### 6.5 Werkscherm

```
┌──────────────────────────────────┐
│ ⌄   23:14    ~24      10    •••  │  bovenbalk
│   verstreken  min rest. sets te gaan
│ ━━━━━━━━━━━━──────────────────── │  voortgangslijn (3 pt)
│ Push A                           │
│ Gestart om 12:41 · Mijn gym · 5  │
│ ✓ Incline dumbbell press         │  afgerond, ingeklapt
│ SUPERSET · 2 OEFENINGEN          │
│ ┌ A1 Chest press machine ──────┐ │  open (alleen de huidige)
│ │ [Uitleg] [Bezet] [Superset]  │ │
│ │ SET  KG   REPS               │ │
│ │ W    35   12        ✓        │ │
│ │ 1    55   10        ✓        │ │
│ │ 2    55   10       NU        │ │
│ │ 3    55   9                  │ │
│ │ [+ Set] [+ Warming-up]       │ │
│ └──────────────────────────────┘ │
│ (A2) Cable lateral raise  1 van 3│  ingeklapt
│ ○ Dumbbell shoulder press        │  komend, ingeklapt
├──────────────────────────────────┤
│ ⏱ Rust 1:24   −15  +15  Sla over │  rustbalk (alleen tijdens rust)
├──────────────────────────────────┤
│ Chest press machine   Set 2 van 3│  dock
│ Vorige keer 55 kg × 9            │
│ [ − 55 kg + ] [ − 10 reps + ]    │
│ [        ✓ Set klaar          ]  │
└──────────────────────────────────┘
```

**Bovenbalk:**
- Links ⌄: terug naar het startscherm (de training blijft lopen).
- In het midden drie getallen:
  - **verstreken** tijd;
  - **min resterend**, als ~N;
  - **sets te gaan** (alleen werksets; warming-upsets tellen niet mee).
- Rechts •••: het workoutmenu.
- **Voortgangslijn** = gedane werksets / alle werksets.

**Geschatte resterende tijd** = open werksets × 2,25 min + open warming-upsets × 1 min, afgerond, minimaal 1. Later kan dit uit je eigen gemiddelden komen (`DurationEstimator`).

**Lijst:**
- Alleen de **huidige** oefening staat open.
- **Afgeronde oefeningen**: een ingeklapte regel met een vinkje in `accentSoft` en de samenvatting "3 × 26 kg · 8, 8, 7 reps".
- **Komende oefeningen**: een ingeklapte regel met een lege ring, of een badge A2, en "3 sets · 20 kg × 10".
- **Half gedane oefeningen**: "1 van 3 gedaan · 7,5 kg × 12".
- Tik op een ingeklapte oefening: die gaat open en wordt de huidige (dit heet de *focus*).
- Een vervangen oefening krijgt de toevoeging "· vervangt Chest press machine".

**Open oefening (`surface`, hoek 20):**
- Bovenaan de badge, de naam (22) en spiergroep · materiaal.
- **Chips:** Uitleg, Bezet, Superset.
- **Setrijen:**
  - Kolommen: Set, kg en Reps.
  - Status rechts: een vinkje (gedaan) of "NU" (huidige).
  - Het setlabel is een knop: W (`warm`), D (`drop`), F (`danger`) of het volgnummer. Tik erop → de sheet *Soort set*.
  - De huidige rij heeft achtergrond `raised` en een label in `accentText`.
  - Geplande waarden staan in `text3`, gedane waarden in `text`.
- **Twee knoppen:** **+ Set** (`accentText`) en **+ Warming-up** (`warm`).
- **Hint:** "Tik op het setnummer voor het type · veeg naar links om te verwijderen".

**Invoerdock (`surface`, bovenhoeken 24):**
- Regel 1: oefeningnaam (15 semibold) met rechts het label:
  - "Set 2 van 3";
  - "Warming-up" (`warm`);
  - "Dropset" (`drop`);
  - "Tot falen · 2 van 3" (`danger`).
- Regel 2: "Vorige keer 55 kg × 9", of "Nog geen vorige keer".
- **Twee balken naast elkaar** (`raised`, hoogte 52): `[−] 55 kg [+]` en `[−] 10 reps [+]`.
  - Gewicht springt naar het vorige of volgende gewicht dat dit apparaat in jouw gym heeft (`WeightScale`).
  - Reps gaan per 1, minimaal 1.
- **Set klaar** (accent, hoogte 52): zet de set op gedaan, met een lichte tik (`UIImpactFeedbackGenerator(.medium)`).
- Totale hoogte van de dock: ongeveer 200 pt plus de onderste veilige zone.

**Rustbalk:** staat direct boven de dock (`raised`, hoek 16, hoogte 56).
- Een vulling in `accentSoft` loopt van rechts naar links leeg.
- Links het timer-icoon, "Rust" en de resterende tijd (22, monospacedDigit).
- Knoppen: **−15**, **+15** en **Sla over**.
- Aan het eind: `UINotificationFeedbackGenerator(.success)`, en een lokale melding als de app op de achtergrond staat.

**Melding na verwijderen:** boven de rustbalk of de dock (`inverse`, hoek 16), met "Set verwijderd" en de knop **Ongedaan maken**. Verdwijnt na 5 seconden.

**Alle sets gedaan:** de dock maakt plaats voor "Alle sets gedaan. Sterk werk." en de knop **Workout afronden**. Die knop verschijnt **pas** als de allerlaatste set klaar is.

**Lege training:** "Nog geen oefeningen" met de knop **Oefening toevoegen**. Er is geen dock.

### 6.6 Sheets in het werkscherm

Een sheet heeft `.presentationDetents([.medium, .large])`, de achtergrond `surface`, bovenhoeken 24, een grijper en rechtsboven een sluitknop ✕ (44 pt). Op de achtergrond ligt een `scrim`.

| Sheet | Inhoud |
|---|---|
| **Workoutmenu** (•••) | Oefening toevoegen · Instelling *Warming-up in superset* (schakelaar met uitleg) · **Workout stoppen** (`danger`) |
| **Workout stoppen?** | "Er staan nog N sets open. Je gedane sets worden bewaard." · **Stoppen en opslaan** (`danger`-vlak) · Workout verwijderen (`danger`-tekst) · Verder trainen |
| **Uitleg** | **Zoek op YouTube** (opent `youtube.com/results?search_query=<naam>+form`) · **Open mijn video** (alleen als er een eigen link is; accentvlak) · invoerveld *Eigen link* + Bewaar · Link verwijderen. Een link zonder `https://` krijgt die er automatisch voor. De link hoort bij de oefening en geldt ook voor volgende trainingen. |
| **Machine bezet** | *Suggestie van de app* (zelfde spiergroep, liefst ander materiaal, alleen wat jouw gym heeft) · *Mijn voorkeur* (★, of de uitleg dat je er nog geen hebt) · *Zelf kiezen* (zoekveld + lijst, zelfde spiergroep bovenaan) · schakelaar **Bewaar mijn keuze als voorkeur**. Gedane sets blijven bij de oude oefening; open sets gaan naar de nieuwe, met het standaardgewicht van het nieuwe apparaat. |
| **Superset** | *Loskoppelen uit superset* (`danger`, alleen als de oefening al in een superset zit) · *Uit dit schema*: oefeningen afvinken (meerdere tegelijk) · *Nieuwe oefening zoeken*: zoeken en toevoegen · knop **Koppelen (n)**, gedimd tot je minstens één oefening kiest. Werkt ook met drie of meer oefeningen. |
| **Oefening toevoegen** | Zoekveld (zoekt op naam en spiergroep) + lijst, maximaal 8 resultaten. Tik → onderaan de training, met 3 sets van 10 reps op het standaardgewicht. |
| **Soort set** | W Warming-up ("Telt niet mee voor je sets en volume") · 1 Werkset · D Dropset ("Direct na de vorige set, lichter, zonder rust") · F Tot falen · **Set verwijderen** (`danger`) |

### 6.7 Afgerond

- Een accentcirkel met een vinkje en "Push A afgerond".
- De notitie: "Goed gedaan. Alles is opgeslagen." Na eerder stoppen: "Eerder gestopt. Je gedane sets zijn opgeslagen."
- Drie getallen: **duur**, **sets** (alleen werksets) en **kg volume** (gewicht × reps van de gedane werksets).
- Per oefening een samenvattingsregel.
- De knop **Klaar** → het startscherm. In de kalender is vandaag dan gevuld.

### 6.8 Progressie

- De ondertitel "Laatste 4 weken" en de titel "Progressie".
- Drie getallen: trainingen, kg volume en nieuwe PR's.
- **Volume per week:** een staafdiagram met 8 weken. De huidige week is `accentLine`, eerdere weken `accentSoft`. Labels W35…W42, met eronder "Deze week tot nu toe 6.240 kg".
- **Sets per spiergroep (deze week):** een horizontale balk per spiergroep (`track` met een vulling in `accentLine`), met het getal rechts.
- **Persoonlijke records:** naam, "26 kg × 8 · geschat 1RM 33 kg" (Epley) en de datum.
- Gebruik Swift Charts **niet**: het werkt op iOS 16, maar gewone `Rectangle`s zijn hier eenvoudiger en passen beter bij de stijl.

### 6.9 Gym

- De titel "Gym" en een blok met de huidige gym, "10 van 12 apparaten" en **Wissel**.
- **Apparaten in deze gym:** per apparaat de naam, de gewichtsstappen (bijv. "25–85 kg · stappen van 10 kg") en een schakelaar. Een apparaat dat uit staat toont "Niet in deze gym", in `text2`.
- **+ Apparaat toevoegen**, en de hint dat scannen met de camera later komt.
- **Sheet *Kies je gym*:** de lijst met gyms en een vinkje bij de huidige, plus **+ Nieuwe gym**. De gekozen gym bepaalt de suggesties bij Machine bezet en de stappen van +/−.

### 6.10 Profiel

- Een kop met een accentcirkel met de initiaal, de naam en "48 trainingen · sinds juli 2026".
- **Weergave:** accentkleur (zes ronde stalen van 34 pt in een raakvlak van 48; de gekozen kleur krijgt een ring van 2 pt in `text`) en een segmentknop Modus (Systeem / Donker / Licht).
- **Training:**
  - standaard rusttijd (stepper per 15 s, van 0:30 tot 5:00, standaard 1:30);
  - schakelaar *Warming-up in superset*.
- **Herinneringen:** Creatine (schakelaar, "Elke dag om 09:00").
- Later: kg/lb, gegevens exporteren en een back-up.

---

## 7. Regels voor het gedrag

### 7.1 Volgorde van sets (de wachtrij)

Een training bestaat uit **blokken**. Een blok is één oefening, of een superset van twee of meer opeenvolgende oefeningen met hetzelfde `groupID`.

- **Losse oefening:** de sets in volgorde (eerst warming-up, dan werksets).
- **Superset:** je wisselt per ronde: A1-set1, A2-set1, A1-set2, A2-set2, …
- **Instelling *Warming-up in superset*** (standaard aan): de warming-upsets van een oefening en haar eerste werkset vormen samen ronde 0. Je doet dus A1-W, A1-1, A2-1, A1-2, A2-2, … Staat de instelling uit, dan is elke warming-upset een eigen ronde: A1-W, A2-1, A1-1, …
- **Na Set klaar** wordt de volgende open set in de wachtrij de huidige. Zo gaat een superset altijd door naar de volgende oefening, ook als je eerst een oefening had aangetikt.
- Heb je een ingeklapte oefening aangetikt (focus), dan is de eerste open set van die oefening de huidige.

### 7.2 Rusttimer

- Start na **Set klaar** als de volgende set in een **andere ronde of een ander blok** valt.
- **Geen rust** binnen een superset-ronde, of als de volgende set een **dropset** van dezelfde oefening is.
- **Duur:** 45 s na een warming-upset, anders de standaard rusttijd uit Profiel.
- Tik je tijdens de rust op Set klaar, dan stopt de rust en geldt de normale regel.

### 7.3 Soorten sets

| Soort | Label | Kleur | Telt mee bij "sets te gaan" en volume |
|---|---|---|---|
| Warming-up | W | `warm` | nee |
| Werkset | 1, 2, 3 … | `text2` / `accentText` als huidige | ja |
| Dropset | D | `drop` | ja |
| Tot falen | F | `danger` | ja |

- Warming-upsets staan altijd vooraan. Verander je het type, dan wordt de lijst opnieuw gesorteerd (eerst W, daarna de rest in de oude volgorde).
- **+ Warming-up** voegt een set toe na de laatste warming-upset: ongeveer 50 % van het gewicht van de eerste werkset, afgerond naar beneden op een geldige stap, 12 reps.
- **+ Set** kopieert gewicht en reps van de laatste set.

### 7.4 Verwijderen en ongedaan maken

- Veeg een setrij naar links. Onder de rij verschijnt rood met "Verwijder". Voorbij 90 pt wordt de set verwijderd; loslaten eerder veert terug.
- Het kan ook via de sheet *Soort set* › Set verwijderen (bereikbaar met VoiceOver).
- Na het verwijderen verschijnt 5 seconden lang een melding met **Ongedaan maken**; die zet de set terug op dezelfde plek.
- Gebruik in een `List` `.swipeActions(edge: .trailing, allowsFullSwipe: true)` (dat werkt op iOS 15 en hoger). Staat de lijst niet in een `List`, gebruik dan een `DragGesture`.

### 7.5 Afronden en stoppen

- **Workout afronden** is alleen zichtbaar als er geen open sets meer zijn.
- **Eerder stoppen** kan alleen via ••• › Workout stoppen, met bevestiging.
- *Workout verwijderen* gooit alles weg en gaat terug naar het startscherm.

### 7.6 Autosave

Na elke wijziging slaat `WorkoutStore` de training op, zoals nu al gebeurt. Een lopende training overleeft het sluiten van de app; de minibalk verschijnt dan weer.

---

## 8. Toegankelijkheid

- Elke knop met alleen een icoon heeft een `accessibilityLabel` ("Minder gewicht", "Opties voor Push A", "Naar startscherm").
- Schakelaars zijn echte `Toggle`s. De gekozen kleur en modus geef je door met `.accessibilityAddTraits(.isSelected)`.
- Kleur is nooit de enige drager van betekenis: settypes hebben ook een letter (W/D/F) en gedaan heeft ook een vinkje.
- Tekstcontrast is minstens 4,5 : 1 en grote cijfers minstens 3 : 1 (zie de accentregels in 2.1).
- Ondersteun Dynamic Type tot ten minste *Extra Extra Large*. Lukt het niet om de dock-cijfers in één regel te houden, verklein dan de eenheid ("kg") in plaats van het getal.

---

## 9. Namen en data

- **Oefeningen en apparaten:** Engels, in sentence case: *Chest press machine*, *Lat pulldown*, *Cable lateral raise*, *Barbell bench press*.
- **Spiergroepen:** Nederlands: Borst, Bovenrug, Lats, Schouders, Biceps, Triceps, Onderarmen, Quadriceps, Hamstrings, Billen, Kuiten, Core.
- **Materiaal:** Nederlands, als meta-tekst: Machine, Dumbbells, Kabel, Stang.

### 9.1 Aanpassen in `MockData.swift`

| Nu | Wordt |
|---|---|
| Bankdrukken (stang) | Barbell bench press |
| Dumbbell bankdrukken | Dumbbell bench press |
| Chest press (machine) | Chest press machine |
| Shoulder press (machine) | Shoulder press machine |
| Chest-supported row (machine) | Chest-supported row machine |
| Dumbbell zijwaartse raise | Dumbbell lateral raise |
| Kabel zijwaartse raise | Cable lateral raise |
| Kabel fly | Cable fly |
| Kabel curl | Cable curl |
| Kabel crunch | Cable crunch |
| Externe rotatie (rotator cuff) | Cable external rotation |
| Overhead triceps extension (kabel) | Cable overhead triceps extension |
| Triceps pushdown (kabel) | Triceps pushdown |
| Hip thrust (stang) | Barbell hip thrust |
| Liggende leg curl | Lying leg curl |
| Optrekken | Pull-up |
| Push-ups | Push-up |
| Roemeense deadlift | Romanian deadlift |
| Squat (stang) | Barbell squat |
| Staande kuitraise (machine) | Standing calf raise machine |
| Band pull-aparts | Band pull-apart |
| Olympische stang | Olympic barbell |
| Kabelstation | Cable station |
| Kuitmachine | Calf raise machine |

### 9.2 Nieuw in het datamodel

- `Program` (schema): `id`, `name`, `workoutIDs: [UUID]` (in volgorde), en `UserSettings.currentProgramID`.
- `WorkoutTemplate`: blijft een training; een training kan in meerdere schema's staan.
- `SetKind`: `.warmup`, `.working`, `.drop`, `.failure`. Dit vervangt een losse `isWarmup`-bool.
- `UserSettings`:
  - `accentID`;
  - `appearance` (`.system`, `.dark`, `.light`);
  - `defaultRestSeconds`;
  - `warmupFirstInSuperset`;
  - `creatineReminder` (aan/uit + tijd);
  - `currentGymID`.
- `Exercise.customVideoURL: URL?` en `Exercise.preferredAlternativeID: UUID?`.

---

## 10. Nog te ontwerpen (later)

- Naam van een schema wijzigen en een schema verwijderen (nu krijgt een nieuw schema de naam "Nieuw schema N").
- Trainingen binnen een schema herschikken.
- Een apparaat toevoegen en bewerken (min, max, stap, of een onregelmatige lijst), en de camera-scan met correctiestap.
- Detail van een oefening in Progressie (grafiek per oefening, geschiedenis).
- kg/lb, export en back-up.
- Onboarding: eerste gym en eerste schema kiezen.
