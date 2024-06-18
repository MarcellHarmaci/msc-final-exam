# Védés
- kb 30 perc összesen
- előadás max 15p (1-2p/dia)
- kérdések:
  - védéshez kapcsolódó
  - 3 választott tágyhoz kapcsolódó

### Bizottság
- Kozsik Tamás (elnök)
- Laki Sándor
- Kaposi Ambrus
- Sinkovics Ábel külső tag






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
## Adatmodell
```erlang
-record(state, {
    nodes   = #{} :: map(), 
    edges   = #{} :: map(), 
    node_id = 0   :: integer(), 
    edge_id = 1   :: integer()
}).

-record(node, {
    id              :: integer(), 
    class           :: atom(), 
    data            :: nodeData(), 
    edges_fwd  = [] :: list(integer()), 
    edges_back = [] :: list(integer())
}).

-record(edge, {
    id   :: integer(), 
    from :: integer(), 
    tag  :: atom(), 
    idx  :: integer(), 
    to   :: integer()
}).
```

## Architektúra
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
1. termevzés
2. megvalósítás
3. kiértékelés

# Válaszdiák
- path nyelv
- path algoritmus
- mérésekről 1-2 táblázat/ábra

# Esetleges kérdések 
1. Miért nem mértem Erlang struktúrák módosítási idejét?  
A törlés hasonló eredményeket produkált, így nem hozott be új információt. (Ugyanúgy keresés és felülírás szükséges hozzá.)

1. Miért nem `array` struktúrát használtam?  
Nagy megkötésnek éreztük az integer key-t. Nem is kulcs-érték párok tárolására való.

1. A `gb_tree` tárolót miért nem vizsgáltam?  
`TODO` LearnYouSomeErlang

1. Haskell adatstruktúrák, hogy lehetne attrib gráfot ábrázolni?

1. Mi lenne ha Haskell tároló lenne?  
Erlang-Haskell együtt lassú lenne (io kontextusváltás)  
Erlang alapú volt a cél kifejezetten &rarr; **függőségmentes**

1. Path nyelvet definiáld Haskellben!  
```haskell
-- TODO
```