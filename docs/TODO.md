# Set — to-do lijst

Status per 2026-10-20. Minimaal iOS 26 (bouwen op GitHub). Ronde 1 (training loggen) is klaar en getest.

## Klaar (wacht op test)
- [x] Ronde 2a/2b: gym-tab met machine-database, eigen gyms, stappen per machine, apparaat in oefening, wisselen in schema

- [x] Ronde 5b: volume telt dubbel bij gewicht per arm/been (met duidelijke tekst), creatine op eigen scherm met tijden en dagen
- [x] Ronde 5a: vrije training wisselt direct, toetsenbord weg bij scrollen, links/rechts apart invullen, creatine per weekdag, glas-knoppen overal
- [x] Ronde 3e: Alle trainingen eigen scherm, sheet omlaag vegen, Liquid Glass door de hele app, tabbalk-slepen gefixt
- [x] Ronde 3c: "Alle trainingen" met filter in Progressie, tabbalk lager + glijdende markering + swipen tussen schermen, lichte achtergrond in light mode

## Volgende
- [x] Profiel-tab opgeruimd (Ronde 12b): Weergave bovenaan, daaronder Instellingen met subschermen Training, Meldingen en Persoonlijk
- [ ] Apple Watch-app, of een andere manier om te zien hoe lang je nog rust hebt
- [x] Vergeten workout (Ronde 8a, wacht op test): na 1,5 uur geen set een melding, en bij openen vraagt de app "Workout sluiten?"
- [x] Gym-tab is weg (Ronde 14a): apparaten en opzetstukken staan nu in Instellingen › Gym
- [ ] Plaatje bij elke oefening (afbeelding/illustratie)
- [ ] Instellingen: kopje "Fun features" voor speelse extra's
- [x] Melding bij vergeten workout is nu een instelling (Profiel > Training, standaard aan)
- [x] Opzetstuk per record in Progressie (Ronde 9a)
- [ ] Creatine-melding koppelen aan weekplanning (geen melding op dagen dat je een shake na het sporten neemt)
- [x] Instelling "Elke week opnieuw beginnen" (Ronde 7a): Profiel > Training; op maandag weer de eerste training
- [x] Live Activity en Dynamic Island (Ronde 6a, wacht op test met Sideloadly)
- [~] Alle trainingen-pagina: tik op een training opent het detailscherm (Ronde 10a); mooier maken blijft open
- [x] Vrije training een naam geven aan het einde (Ronde 10a)
- [x] Sets per spiergroep als radardiagram, met vorige week als stippellijn (Ronde 14a)
- [ ] Menselijk lichaam met spieren (heatmap) en andere leuke extra's in Progressie
- [~] Leuker statistiekenscherm: weekdoel-ring, weken op rij, oplopende getallen (Ronde 14a); verder uitbouwen
- [x] Opzetstukken per oefening (Ronde 7a-7d): kiezen op de oefeningkaart, gewicht/stap per opzetstuk, beheren in Gym > Opzetstukken
- [x] Nieuw startscherm (Ronde 4a): tab "Start", gecentreerd, volgende training in één tik, Ready-Set-Go
- [x] Ronde 4b: kalender bovenaan, duidelijkere knoppen, Ready-Set-Go bij openen van de app (niet bij workout starten), tabvolgorde Gym > Progressie > Start > Training > Profiel
- [~] Design-ronde (Ronde 14a: nieuwe tabs, Logboek-feed, animaties); verder: moderner, nog minimalistisch (skills: ui-ux-pro-max, SwiftUI-expert, Apple HIG)
- [ ] Machine-database controleren met echte gegevens (Basic-Fit, jouw gym); geen openbare bron met stapgroottes gevonden

## Gym (in Instellingen)
- [ ] Eigen machines/sportscholen toevoegen en bewerken
- [ ] Sportschool-lijsten delen met anderen
- [ ] Basic-Fit machinelijst controleren/aanvullen na bezoek (15-10)

## Training
- [x] Cooling-down-blok achteraan in je schema (Ronde 10b)
- [~] Schema-wijzigingen opslaan na de training (Ronde 10b): alleen oefeningen die je erbij deed; aangepaste sets/gewichten volgen
- [x] Weekplanning als weekkalender (Ronde 11a): plannen per dag of vast op een weekdag
- [x] Cardio-timer in de workout (Ronde 11a): Start bij de set, Stop vult de minuten in; knop op Start is weg
- [~] Live Activity / Dynamic Island: werkt op iPhone 8; op iOS 27 geblokkeerd door Sideloadly-signering (geparkeerd)

## Overig scherm
- [x] Startscherm met "Ready Set Go"-splash (Ronde 4)
- [ ] Trainingsgeschiedenis, sorteerbaar op type
- [ ] Week aantikken in de volumegrafiek

## App
- [x] Minimaal iOS 26, bouwen op GitHub (Ronde 14a)
- [ ] iOS 27-API's zodra GitHub een runner met Xcode 27 heeft
- [ ] Regionale tijd-/eenhedeninstelling
- [ ] Creatine-melding: acties en app-naam
- [ ] Eerste-keer-onboarding

## Onbevestigd / opletten
- [ ] Numpad: tikken op naam/kg/reps — controleren of de vertraging echt weg is

## Ronde 6b (wacht op test)
- Links/rechts-tekst alleen bij één-arm oefeningen (dumbbells, one arm, bayesian); bodyweight (muscle up) nooit.
- Creatine: 2 standaardtijden, per dag aanpasbaar (tik op dag), afvinken + bel op startscherm.
- Live Activity: appex zit correct in de IPA (gecontroleerd); leeg scherm ligt waarschijnlijk aan Sideloadly/ondertekenen. Profiel toont nu een statusblokje.

## Ronde 6c (wacht op test)
- Creatine-balkje op startscherm weggehaald. Idee: creatine-widget op het iPhone-beginscherm (later).
- Creatine-instellingen: schakelaar tweede herinnering bij "Herinnering", tijden netjes onder elkaar, tweede herinnering per dag uit te zetten.
- Live Activity: werkt in de simulator en op iPhone 8 (iOS 16.7, vergrendelscherm). Op iPhone 16 Pro/iOS 27 killt iOS de extensie door Sideloadly-ondertekening (AMFI). Testblokjes weer weggehaald. Later opnieuw proberen na Sideloadly-update. Widget-uiterlijk mooier maken staat open.

## Ronde 7a (wacht op test)
- Opzetstukken: Gym > Opzetstukken (standaard Touw, Rechte stang, V-stang, EZ-stang, Losse handgreep; toevoegen, hernoemen, eigen stap per tik, verwijderen). Per oefening kiezen via oefeningmenu > Opzetstukken kiezen; in de workout een knopje onder de naam om te wisselen. Gewicht wordt per opzetstuk onthouden (opgeslagen in de geschiedenis).
- Instelling Profiel > Training: "Elke week opnieuw beginnen" (maandag weer eerste training van je schema).
- Nog open: opzetstuk per oefening in Progressie tonen; creatine-widget (idee, later).

## Ronde 7b (wacht op test)
- Opzetstukken staan standaard klaar bij kabeloefeningen (bij losse gewichten/andere oefeningen zelf koppelen). Houd een opzetstuk ingedrukt bij het wisselen: bij deze oefening weghalen of uit je gym verwijderen. Sheet toont "Nu: Touw".
- Oefeningmenu: "Hoe vul je dit in?" alleen bij oefeningen waar dat onduidelijk is (kabels, dumbbells, een-arm): Eén gewicht in totaal / Gewicht per arm of been / Links en rechts apart, met uitleg. Ook via het i-tje onder het gewicht in de workout. Niet meer bij o.a. hanging leg raise.
- Gym: bovenaan knoppen "+ Apparaat" en "Opzetstukken".
- Open vraag: heeft de Gym-tab zelf echt nut? (apparaten uit/aan zetten, stappen per apparaat) -- na test bij Basic-Fit beslissen.

## Ronde 7c (wacht op test)
- Gym-tab: keuze bovenaan tussen "Apparaten" en "Opzetstukken"; per scherm voeg je je eigen dingen toe.
- Oefeningkaart toont "Opzetstuk: <keuze>" met uitklapknopje.
- Oefeningmenu (3 puntjes): één knop "Links en rechts apart invullen" (bij onduidelijke oefeningen). Naast de 3 puntjes een i-tje: uitleg hoe de app het bijhoudt, en kiezen tussen 2 armen/benen tegelijk of 1 arm/been.

## Ronde 7d (wacht op test)
- i-tje onder de oefening: alleen uitleg hoe de app het logt (niets aanpassen). 3-puntjesmenu: opzetstuk-opties weg (staat al op de kaart).
- Gym > Opzetstukken: knop "+ Opzetstuk toevoegen" bovenaan.

## Ronde 8a (wacht op test)
- Vergeten workout: 1,5 uur na je laatste set komt een melding "Workout nog bezig?". Open je de app dan vraagt hij "Workout sluiten?"; sluiten slaat op met de tijd van je laatste set (niet 11 uur). Annuleer = doorgaan, hij vraagt dan pas na een half uur weer.

## Ronde 8b (wacht op test)
- Gym > apparaat (stack-machine): gewichtsstapel met pin. Tik op een plaatje en je ziet het gewicht en de stand. Het is een preview om je stappen te controleren; kiezen vanuit de workout volgt later.

## Ideeën (nog niet gepland)
- Gewichtsstapel visueel: Ronde 8b was niet wat je bedoelde en is weggehaald. Opnieuw uitwerken: eerst afspreken hoe het eruit moet zien en waar je het gebruikt (waarschijnlijk in de workout, onder een Fun features-kopje).
- Creatine-widget op het iPhone-beginscherm.

## Ronde 9a (wacht op test)
- Gewichtsstapel weer weggehaald (staat bij Ideeën).
- Profiel > Training: schakelaar "Melding bij vergeten workout".
- Progressie > records: toont het opzetstuk erbij (bijv. "Triceps \u00B7 Touw").

## Ronde 10a (wacht op test)
- Alle trainingen: tik op een training opent een eigen scherm met elke oefening en al je sets (opzetstuk, links/rechts, dropset). Daar kun je de naam wijzigen.
- Vrije training: op het eindscherm de knop "Geef deze training een naam".

## Ronde 10b (wacht op test)
- Cooling-down: in de schema-editor een blok "Cooling-down" onder je oefeningen (bijv. uitfietsen of stretchen); staat ook in het overzicht en in je workout achteraan. Telt niet mee voor volume (net als warming-up).
- Weekplanning: Profiel > Training > Weekplanning. Per weekdag een training kiezen; op die dag staat die bovenaan bij Start ("Gepland voor vandaag"). Dagen zonder keuze volgen je gewone rotatie.
- Na je training: deed je een oefening erbij die niet in het schema staat, dan staat op het eindscherm "Zet in mijn schema". Alleen nieuwe oefeningen; wijzigingen aan sets of gewicht niet.
- Start: knop "Cardio starten" kiest een cardio-oefening en start meteen een vrije training. (Nog geen lopende timer.)

## Ronde 11a (wacht op test)
- Kleuren: cooling-down blauw (knop in de editor en het vak in je workout), warming-up oranje op dezelfde manier.
- Warming-up- en cooling-downblokken tellen nu mee voor sets en volume (op het eindscherm, in Progressie en in het detailscherm). Oude trainingen blijven zoals ze waren.
- "Lege training" heet nu "Vrije training".
- Cardio starten op het startscherm is weg. In de workout staat bij een cardio-/tijdset "Start timer": de tijd loopt, "Stop en bewaar" vult de minuten in en rondt de set af. De timer loopt door als je de app sluit.
- Weekplanning: Profiel > Training > Weekplanning toont de week als kalender, met pijltjes naar andere weken. Tik op een dag: "Alleen op deze dag" (training of rustdag) of "Vast elke maandag" enz. Een losse keuze gaat voor op de vaste.

## Ronde 11b (wacht op test)
- Alle sets tellen mee voor sets en volume, ook gewone warming-upsets.
- Cardio-timer: Stop vult de minuten in maar rondt de set niet af. Je kunt daarna kilometers en tijd nog aanpassen en tikt zelf op "Set klaar".
- Nieuwe oefening toevoegen: de knop "Eigen oefening: ..." staat nu bovenaan de zoekresultaten, boven het toetsenbord.
- Kalender: dagen met een geplande training krijgen een stipje. Tik op een dag: je ziet wat er gepland staat en kunt via "Plan" (alleen die dag of vast elke weekdag) inplannen. Zelfde kalender op Start, Training en Progressie.
- Training-tab: knop "Weekplanning" onder de kalender (naast Profiel).

## Ronde 12a (wacht op test)
- Training-tab: de knop "Week plannen" is klein en staat pas onder de kalender als je die uitklapt.
- Profiel opgeruimd in kopjes: Training (rusttijd, warming-up in superset, elke week opnieuw, weekplanning), Meldingen (vergeten workout, creatine), Weergave (kleur, modus), Persoonlijk (nog leeg: later kg/lb, export, back-up).

## Ronde 12b (wacht op test)
- Profiel: Weergave staat weer bovenaan. Daaronder "Instellingen" met drie rijen die naar een subscherm gaan: Training (rusttijd, warming-up in superset, elke week opnieuw, weekplanning), Meldingen (vergeten workout, creatine) en Persoonlijk (nog leeg).
- Terug vanuit weekplanning of creatine (geopend via Instellingen) brengt je terug naar het subscherm.

## Ronde 13a (wacht op test)
- Vinkje van een eerder setje per ongeluk weggehaald: de rusttimer loopt door en je krijgt "Ongedaan maken". De knop bij een gedaan setje heet nu "Terug naar huidige set".
- Superset tijdens de workout: bovenin staat een vinkje zodra je iets kiest, en de knop "Koppelen" staat boven de zoeklijst.
- Superset: de lijst scrolt naar de oefening waar je nu mee bezig bent, niet naar het begin van het blok.
- Invoer met toetsenblok is lager (kleinere toetsen), en de rustklok is weg tijdens het invullen.
- Na afloop kun je per erbij gedane oefening kiezen of hij in je schema komt.
- Na je geplande training van vandaag staat de volgende training op het startscherm, met een regel dat je de ingeplande hebt afgerond.
- Creatine staat op het startscherm: vink hem daar af of open hem.

## Ronde 13b (wacht op test)
- Volume telt automatisch goed, zonder instelling: links en rechts apart = elke kant telt mee; twee dumbbells of kabel met "Losse handgreep" (twee handgrepen tegelijk) = dubbel; één handvat, stang, touw of machine = één keer.
- Het ⓘ-scherm is weer alleen uitleg (geen keuzemenu).
- Links en rechts apart: de knop voor eigen gewicht per kant is weg. In plaats daarvan een knop om de reps links en rechts samen aan te passen (staat standaard aan, tik om ze los te zetten).

## Ronde 14a (wacht op test)
- Nieuwe tabs: Voeding (optioneel) · Logboek · Start · Training · Progressie. Start is een gevulde accentcirkel.
- Instellingen › Functionaliteiten: Voeding aan/uit (standaard uit). Zet je hem uit, dan schuiven de andere tabs op.
- Logboek: je trainingen als feed per week, met filter (Alles, PR's, per training), kaarten met volume/sets/minuten, top-oefeningen en spiergroepbalk. Tik = detailscherm.
- Progressie & Profiel: profielkop, weekdoel-ring met weken op rij, oplopende getallen, staven die één voor één groeien, radardiagram voor sets per spiergroep. Tandwiel rechtsboven = Instellingen.
- Instellingen: Weergave, Functionaliteiten, en subschermen Training, Gym (apparaten en opzetstukken), Meldingen, Persoonlijk.
- Voeding (eerste versie): doel kiezen (cutten, onderhouden, bulken), maaltijden van vandaag met kcal en eiwit, creatine afvinken.
- Animaties: vinkje ploept bij Set klaar, "sets te gaan" rolt omlaag, tabicoon veert, knoppen deuken in.
- Minimaal iOS 26. De iPhone 8 Plus (iOS 16) kan de app niet meer installeren.


## Ronde 13c (wacht op test)
- Meer opzetstukken in de standaardlijst (o.a. lat-stang, parallelle greep, smalle greep, enkelband). Gyms waar je de lijst zelf hebt aangepast houden hun eigen lijst; voeg nieuwe zelf toe.
- One-arm oefeningen staan standaard op links en rechts apart.
- Test: rechte stang, 12 x 25 kg telt als 300 kg volume.

## Ronde 14b (wacht op test, branch ronde-14b, nog niet in main)
- Voeding: balk bovenin met kcal gegeten, hoeveel er nog mag en eiwit. "Doel aanpassen": cutten/onderhouden/bulken plus eigen kcal en eiwit. Maaltijden loggen met naam, kcal, eiwit; snel opnieuw toevoegen van eerdere maaltijden (geen productendatabase).
- Supplementen in Voeding: creatine, omega 3, magnesium en eigen supplementen. Afvinken per dag, per supplement een eigen herinnering met "Gehad"-knop.
- Voeding staat standaard aan. Creatine staat niet meer op Start.
- Start-tab: alleen de bliksem, geen cirkel. Tab "Progressie" heet weer "Profiel"; kalender eruit (staat op Start en Training).
- Nog te doen: redesign door de hele app (workout, schema/training instellen, sheets).

## Ronde 14c (wacht op test, branch ronde-14b)
Voeding
- Doel instellen: tandwiel op Voeding (of tik op "x van y gegeten") opent "Jouw doel": geslacht, leeftijd, lengte, gewicht, hoe actief, cutten/onderhouden/bulken. De app rekent kcal, eiwit, koolhydraten en vet uit (Mifflin-St Jeor) en je kunt alles daarna nog fijn afstellen.
- Op je scherm: koolhydraten, vetten, water en supplementen zijn aan/uit te zetten.
- Nieuw scherm: dagstrook met voortgangsringetjes (pijlen = vorige/volgende week), halve-cirkelmeter met wat je nog mag eten, drie cirkels (koolhydraten, eiwit, vet), optioneel water.
- Maaltijden per moment (ontbijt, lunch, diner, snacks) met + : invoer met naam, kcal, eiwit, koolhydraten, vet; snel opnieuw toevoegen.
- Vorige dagen: tik een dag in de strook. "Kopieer dag" of kopieer één maaltijd, ga naar een andere dag en tik "Plak".
Redesign
- Basis: kaarten met lichtrand en accentgloed, kleurrijkere achtergrond, hoofdknoppen met kleurverloop. Werkt door in de hele app (workout, sheets, editor, logboek).
- Start: volgende training in een grote kaart met label.
- Profiel: weekdoel en totalen in één kaart, daaronder kopjes Verloop, Balans, Prestaties.
- Nog niet gedaan: oefenfoto's, eigen opmaak per scherm in workout/schema-editor, Logboek en Training verder uitwerken, lichte modus nalopen.

## Ronde 14d (wacht op test, branch ronde-14b)
- Voeding: halve cirkel is nu een balk; "Voeding" als titel weg; de datum linksboven is een knop die een grote kalender opent; alles compacter zodat de maaltijdvakken al zichtbaar zijn. Water staat onder de maaltijden.
- Supersets: geen gekleurde vakken meer. Een dunne lijn in de accentkleur langs de oefeningen, kopje "SUPERSET A", en nummers A1, A2 (B1, B2 voor de volgende).
- Oefenfoto's: 74 oefeningen hebben een foto (free-exercise-db, public domain, in de app meegeleverd). Te zien in de open oefening, de lijst in de workout, het schemaoverzicht, de editor, oefening toevoegen/wisselen en de uitleg (die wisselt tussen begin- en eindstand). Eigen oefeningen krijgen een symbool.
- Nog open: foto's kloppen soms niet 100% bij Basic-Fit-namen (bijv. Cable Deltoid Side Raise); eigen foto per oefening kiezen; foto's op Start en Logboek.

## Ronde 14e (klaargezet, nog geen IPA)
- Gemini-illustraties: de app laadt ze automatisch (voorrang boven de foto's). Werkwijze: Stan levert PNG's per oefening (naam uit docs/gemini-oefenafbeeldingen.md, bv. `incline-dumbbell-press.png`), Claude draait `python3 tools/import_art.py <map-of-zip>`. Dat snijdt de twee standen los, verwijdert de witte rand en maakt er 640 px JPG's van (~30 kB per stand) in `SportApp/Resources/ExerciseArt`.
- Als eerste staat "Incline dumbbell press" erin. Oefeningen zonder illustratie houden de foto.
- Uitleg-scherm toont een illustratie in zijn geheel (niet bijgesneden).
- GIF/video-animaties: bewust uitgesteld (1,5 MB per GIF; later eventueel als MP4 ~170 kB).
- Nog niet gebouwd of getest op CI; eerstvolgende IPA bevat dit.

## Ronde 14f (notities van Stan, wacht op test, branch ronde-14b, geen IPA gemaakt)
- Geschiedenis: klokknop naast de drie puntjes in de open oefening. Toont de laatste 8 keren met alle sets.
- Cooling-down: knop "Cooling-down" naast "Oefening" onderaan de workout. Blauw blok achteraan, telt mee.
- Eigen oefeningen bewerken: naam (wordt overal doorgevoerd), soort (nu ook "Op tijd", dus trilplaat is geen cardio meer), spiergroep, verwijderen. Bij Instellingen en via nieuwe oefening-aanmaken.
- Instellingen: "Gym" heet nu "Apparaten & oefeningen" met tabs Apparaten / Opzetstukken / Oefeningen. Wissel gym staat bovenaan. Oefeningen-tab: zoeken, "Zelf toegevoegd" bovenaan, rest per spiergroep.
- Eindscherm: nieuw ontwerp (gradient-vink, statistieken in een kaart, oefenlijst met afbeeldingen).
- CI groen (macos-15, 76 tests) op de versie vóór de laatste kleine tekstwijziging op het eindscherm (dubbele kop weg).
- Nog niet getest op toestel. Let op: bestaande trilplaat staat nog als cardio; zet hem via Instellingen > Apparaten & oefeningen > Oefeningen op "Op tijd".
- Wacht op: Stans Gemini-afbeeldingen (met zijn eigen hoofd), zip met namen uit docs/gemini-oefenafbeeldingen.md.

## Ronde 14g (wacht op test, branch ronde-14b, IPA gebouwd van 9c9cd0b)
- Klokknop in de workout opent nu een volledig scherm per oefening: grote afbeelding (wisselt begin/eind), aantal keer gedaan, beste set, laatste keer, "Vandaag" en alle vorige keren met hun sets.
- Training verwijderen: knop op het detailscherm van een training in het Logboek (met bevestiging) en "Deze training niet bewaren" op het eindscherm.
- Supersets in de workout: geen streep meer, maar een ronde omlijnde kaart met "SUPERSET A · n oefeningen" bovenin. Ook in overzicht en editor.
- Setrijen: nummer als ronde knop (huidige set in accentkleur), vinkje als gevulde cirkel, huidige rij met gloed.
- Open: lange oefeningnamen in een superset breken af op 3 regels (info-, klok- en puntjesknop nemen ruimte). Setrijen/invoerbalk verder verfijnen, editorvelden.

## Ronde 14h (wacht op test, branch ronde-14b)
- Scrollen: na een set blijft de set die je invult in beeld (niet meer naar de bovenkant van de oefening). Scrollen en openen/sluiten van kaarten is nu geanimeerd, ook bij een superset.
- Oefenkaart: kleinere titel, info-knop uit de kop (staat al onderin bij het invullen), opzetstuk als eigen balk eronder, tekst breekt netter af.
- Invoerbalk: ronde min/plus-knoppen, groot getal met eenheid eronder, actief veld met gloed. Zelfde stijl in de editor-velden.
- Cooling-down toevoegen: via de drie puntjes van de workout (knop onderaan is weg).
- Logboek: foto's in de kaarten en in het detail; drie puntjes met "Training verwijderen"; potloodje achter de naam.
- Eindscherm: oefeningen zijn klikbaar en openen het detailscherm van die oefening (terug-knop gaat naar het eindscherm).
- Setnummers in trainingsdetail gefixt (stonden op 4, 5, 6).
- Niet getest op toestel: of de animaties echt soepel aanvoelen.
