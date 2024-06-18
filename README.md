# kérdések
1. védés menete
1. "kapcsolódó kérdések" jellege?
1. diasor tartalma

# védés
- előadás max 15p (1-2p/dia)
- kérdések
  - védéshez kapcsolódó
  - 3 tágyhoz kapcsolódó

kb 30 perc együtt



# diasor
technikai részéetek nem nagyon - SPG, gen_db nem kéne magyarázni

__inkább mese__

1. címlap: cím, 3 mondat hogy mivel
1. motiváció: referl(erl stat elemző), SPG reprezentálja a kódot, adatbázis réteg tárol &rarr; tegyük gyorsabbá IDE-ben "könnyűsúlyú" adatréteget
1. részletekről dia lehet: referl rétegek, SPG példa, (referl db-kről nem kell)
  1. megfelelő adatstruktúra kiv. táblázat, diagram
élcímézett gráfot tárolunk, csúcsokat külön tároljuk, éleket hogy reprezentáljuk(honnan hová), hozzá tároljuk a címkét
1. map 
  1. map alapú adatréteg bemutatása
  szerver,
  uml class diagram szerű modell bemutatás

1. kiértékelés  
  |  
  teljesítmény (betöltések vizsgálata, lekérdezések)
  különböző erl alkalmazásokat adtam hozzá, szemantikus lekérdezéseket futtattam  
  |  
  helyesség vizsgálat __módszere__: összehasonlító megvolt, callback-et megvalósítottam
1. össezfoglaló: ugyne elmarad a C++tól, de a mnesiatól jobb
1. továbbfejlesztési lehetőség

Melinda jegyzete:

1. Cimlap - 3 mondatban elmondod, hogy mivel foglalkoztal (hatékony, in-memory, statikus elemzés, tárolási modell)
1. Motiváció - RfactorErl (Erlang statikus elemző). SPG reprezentál, adatbázis réteg (tárol) - IDE - tegyük lightweight
1. ++ részletekről dia (rétegek, SPG)
1. Modell kiválasztása: milyen vizsgálatokat csináltál
1. Map alapú adatréteg bemutatása 
1. Eredmények értékelése
1. Helyesség vizsgálat módszere
1. Összefoglaló

# Q&A 
Miért nem módosítás? - törlés hasonló eredményeket produkált, így nem hozott be új információt.

Miért nem Array? - Nagy megkötésnek éreztük az integer key-t

# bizottság
Kozsik Tamás elnök
Laki Sándor
Kaposi Ambrus
Sinkovics Ábel külső tag


# 0 Címdia
Jó napot kívánok! Harmaci Marcell vagyok és a diplomamunkám során az Erlang nyelv és a RefactorErl statikus elemző szoftver adattárolási módszereinek vizsgálatával és egy saját  adattároló modell megalkotásával foglalkoztam, melynek segítségével egy gyors in-memory adatbázis hozható létre.

# 1 Motiváció
- integráció különböző fejlesztőkörnyezetekbe
- VS Code: erlang ls alapú diagnosztikák integrácija során merült fel
- "könnyűsúlyú" in-memory adatbázis
- (Erlang alapú megoldást szerettünk volna, hogy ne legyen külső függőség - pl C++ fordító)
- többi IDE logo

# 2 Részletek
RefactorErl rétegmodellje
- separation of concerns
- adatbázis réteg cseréje
- stabil interfész

SPG
- élcímkézett attribútumgráf
- csúcsok: programkód alkotóelemei
- élek: köztük fennálló kapcsolatok
- 3 rétegű gráf: lexikai, szintaktikai és szemantikai információt tárol
- gráf alapján felépíthető a kód; lekérdezések, refaktorálások hajthatók végre

# 3-4 Megfelelő adatstruktúra kiválasztása
vizsgált kulcs-érték tároló struktúrák: ...

Műveleti sebesség
- beszúrás, keresés, törlés műveletek
- táblázat
- map jól skálázódik

Memóriahasználat
- nehéz volt megvizsgálni, mivel az Erlang dinamikus memóriakezeléssel rendelkezik &rarr; garbage collector
- array jó

A map és az array tűnt ígéretes megoldásnak, de az array-ek esetén kizárólag egész számok használhatók kulcsként, amit túl nagy limitációnak tartottunk, így a map-et választottuk.

# 5 Map alapú adatréteg
- architektúra ábra
- rétegek bemutatása
- refcore_gendb - meghatározza az adatréteg funkcióit
- lekérdezések a RefactorErl path nyelv segítségével
  - A szemantikus lekérdezéseket a RefactorErl lefordítja a path nyelvre
  - A path nyelv a gyökérből induló lépések sorozataként írja le a keresett rekordokat
  - Az adatbázis rekurzívan dolgozza fel a lépéseket, ahogy ezen a bejárási fán látható
  - Mutasd: bejárási sorrend
- Leképezés: &rarr; lehetne 2 dia
  - state record
  - 2 map: csúcs, él
  - UML jellegű adatmodell

# 6 Eredmények kiértékelése
van ahol a Mnesia ... tranzitív lezárt ... ilyenkor nem tudja egy lekérdezésben futtatni és a Mnesia motorja optimalizálni a lekérdezést, hanem egyesével számítja ki a részeredményeket.

# 7 Helyesség vizsgálata
Teszt felépítés ábra

Adatok konzisztenziáját ellenőrzi

A RefactorErl rendelkezett egy teszt interfésszel az adatrétegek összehasonlítására. Egy callback modult kellett megvalósítanom a map alapú adatréteghez kapcsolódva. A teszt futtatásához 3 RefactorErl példányt kell elindítani. 2 különböző adatrétegeket futtat, a harmadik pedig összehasonlítja azok működését. Ehhez a callback modulok függvényeinek eredményét hasonlítja össze és ez alapján járja be a gráf egy adott részét.

# 8 Összefoglaló


# Válaszdiák
- path nyelv
- path algoritmus
- mérésekről 1-2 táblázat/ábra


# Kérdés kb
- gb_tree miért nem?
- Haskell adatstruktúrák, hogy lehetne attrib gráfot ábrázolni?
- Erlang-Haskell együtt lassú lenne (io)