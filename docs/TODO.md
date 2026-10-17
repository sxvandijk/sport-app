# Set — to-do lijst

Status per 2026-10-14. Ronde 1 (training loggen) is klaar en getest.

## Klaar (wacht op test)
- [x] Ronde 2a/2b: gym-tab met machine-database, eigen gyms, stappen per machine, apparaat in oefening, wisselen in schema

- [x] Ronde 5b: volume telt dubbel bij gewicht per arm/been (met duidelijke tekst), creatine op eigen scherm met tijden en dagen
- [x] Ronde 5a: vrije training wisselt direct, toetsenbord weg bij scrollen, links/rechts apart invullen, creatine per weekdag, glas-knoppen overal
- [x] Ronde 3e: Alle trainingen eigen scherm, sheet omlaag vegen, Liquid Glass door de hele app, tabbalk-slepen gefixt
- [x] Ronde 3c: "Alle trainingen" met filter in Progressie, tabbalk lager + glijdende markering + swipen tussen schermen, lichte achtergrond in light mode

## Volgende
- [ ] Apple Watch-app, of een andere manier om te zien hoe lang je nog rust hebt
- [x] Vergeten workout (Ronde 8a, wacht op test): na 1,5 uur geen set een melding, en bij openen vraagt de app "Workout sluiten?"
- [ ] Open vraag: heeft de Gym-tab echt waarde? Blijft voor nu; later opnieuw bekijken
- [ ] Plaatje bij elke oefening (afbeelding/illustratie)
- [ ] Instellingen: kopje "Fun features" voor speelse extra's
- [x] Melding bij vergeten workout is nu een instelling (Profiel > Training, standaard aan)
- [x] Opzetstuk per record in Progressie (Ronde 9a)
- [ ] Creatine-melding koppelen aan weekplanning (geen melding op dagen dat je een shake na het sporten neemt)
- [ ] Instelling: bij een nieuwe week het schema opnieuw beginnen bij de eerste training (bv. weer Push op maandag)
- [x] Live Activity en Dynamic Island (Ronde 6a, wacht op test met Sideloadly)
- [ ] Alle trainingen-pagina anders uitwerken en mooier maken
- [ ] Leuker statistiekenscherm
- [ ] Opzetstukken per oefening (touw, rechte stang, V-stang...): kiezen welke je gebruikt, gewicht/stap per opzetstuk apart; toevoegen via Gym > accessoires
- [x] Nieuw startscherm (Ronde 4a): tab "Start", gecentreerd, volgende training in één tik, Ready-Set-Go
- [x] Ronde 4b: kalender bovenaan, duidelijkere knoppen, Ready-Set-Go bij openen van de app (niet bij workout starten), tabvolgorde Gym > Progressie > Start > Training > Profiel
- [ ] Design-ronde: moderner, nog minimalistisch (skills: ui-ux-pro-max, SwiftUI-expert, Apple HIG)
- [ ] Machine-database controleren met echte gegevens (Basic-Fit, jouw gym); geen openbare bron met stapgroottes gevonden

## Gym-tab (vervolg)
- [ ] Eigen machines/sportscholen toevoegen en bewerken
- [ ] Sportschool-lijsten delen met anderen
- [ ] Basic-Fit machinelijst controleren/aanvullen na bezoek (15-10)

## Training
- [ ] Opwarmen/afkoelblok (cooling-down)
- [ ] Schema-wijzigingen na de training opslaan in het schema
- [ ] Weekplanning
- [ ] Handmatig een cardioset starten
- [ ] Live Activity / Dynamic Island voor rust en training

## Overig scherm
- [ ] Startscherm met "Ready Set Go"-splash
- [ ] Trainingsgeschiedenis, sorteerbaar op type
- [ ] Week aantikken in de volumegrafiek

## App
- [ ] Modern iOS 27-design (nieuwere Xcode op CI nodig)
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
