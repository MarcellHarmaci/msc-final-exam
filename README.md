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
Jó napot kívánok és üdvözlöm a bizottságot! Harmaci Marcell vagyok és a diplomamunkám során a statikus elemzést támogató hatékony adattárolási módszerekkel foglalkoztam a RefactorErl, Erlang programok elemzésére alkalmas szoftver környezetében.


# 1 Motiváció
1. A RefactorErl a programok elemzésekor sok adatot gyűjt a forráskódról és ezeket egy adatbázisban tárolja el.
1. Többféle fejlesztőkörnyezetbe is már integrálásra került.
(Például Vim, Emacs, Eclipse, VS Code és IntelliJ IDEA)
1. Az Erlang LS alapú, VS Code-os **diagnosztikák** integrácija során merült fel az igény egy "könnyűsúlyú" in-memory adatbázis megléte iránt. (Fontos követelmény volt a függőségmentesség megőrzése, így Erlang alapú megoldásra volt szükség.)


# 2 Részletek
1. Itt látható a RefactorErl szoftver belső felépítése:  
&rarr; A felső rétegekban található a felhasználói interfészek,  
&rarr; a középsőkben az üzleti logika,  
&rarr; valamint az alsókban az adattárolás megvalósítása.
1. A szoftver a programkódot egy szemantikus programgráfként reprezentálja:  
&rarr; Ez egy élcímkézett attribútumgráf.  
&rarr; A programkód alkotóelemeit a gráf csúcsai, a köztük fennálló kapcsolatkoat pedig az élek fejezik ki.  
&rarr; 3 rétegből áll: lexikai, szintaktukus és szemantikus adatokat egyaránt tartalmaz.  
&rarr; Ez alapján az eredeti kód teljes mértékben visszaállítható, illetve a tárolt adatokon lekérdezések és refaktorálások hajthatók végre.  
1. Az én feladatom egy ilyen struktura kezelésére alkalmas új adatbázisréteg megvalósítása volt.


# 3-4 Megfelelő adatstruktúra kiválasztása
1. A munkám megkezdésekor megvizsgáltam az Erlang nyelv által nyújtotta, kulcs-érték párok tárolására alkalmas struktúrákat.
1. 3 db mérést végeztem el azok a műveleti sebességek vizsgálatához.  
&rarr; Megvizsgáltam a lista, array, map, ets tábla, irányított gráf és dictionary struktúrákat.  
&rarr; A dictionary már az első mérésen jelentősen rosszabbul teljesített, mint a többi struktúra, így azzal további méréseket nem folytattam.  
&rarr; A 2. mérés eredményein az látható, hogy az array gyorsan szúrja be az adatokat, a map pedig gyorsan olvassa azokat.  
&rarr; Megvizsgáltam a műveleti sebességek skálázódását, ahol a map mondhatnin nem változott.
1. Ezek után megvizsgáltam a struktúrák memóriahasználatát is
&rarr; Nehéz volt megvizsgálni, mivel az Erlang dinamikus memóriakezelést használ.  
&rarr; Az figyelhető meg, hogy a struktúrák feltöltése során folyamatosan növekszik a memóriahasználat, majd a feltöltés után csökken. Ezt az okozhatja, hogy a köztes struktúráknak csak egy részét lehet újrahasználni, ezért a GC felszabadítja a már nem szükséges darabokat.  
&rarr; A mérések alapján az `ETS` és `digraph` memóriahasználata volt a legalacsonyabb.

Az adatstruktúra kiválasztásakor viszont a műveleti sebességet fontosabb tényezőnek tekintettük, ahol az `array` és `map` teljesített a legjobban. Az array-ek viszont nem kifejezetten kulcs-érték tárolók és nagy megkötésnek éreztük, hogy kizárólag egész számokkal indexelhetők az adatok, így a `map`-re esett a választás a jó skálázhatósága miatt.


# 5-6 Map alapú adatréteg
Ez után a map használatával megvalósítottam az in-memory adatbázisréteget.

## 5 Adatmodell & Architektúra
Az adatmodellt 3 rekordban definiáltam. 
1. A `state` rekord tárolja az adatbázis állapotát. Ez rendelkezik 1-1 map-pel a csúcsok és élek tárolására.
1. A csúcsokban megtalálhatóak azok attribútumai és az ode vezető és onnan kiinduló élek azonosítói.
1. Az élekben tárolásra került az élcímke és annak indexe, valamint a csúcsok, amik között értelmezett az adott él.

Az adatbázisréteg architektúrája maga is a rétegmodellt követi a "separation of concerns" elv alapján. 3 rétegből áll:
1. Az **adatbázis szerver**ből, ami az adatok tárolásáért felelős.
1. Az **adatbázis kliens interfész**ből, ami a szerver működésének elfedésére szolgál.
1. És magából az adatbázis kliensből, amin keresztül a RefactorErl adatelérése biztosított. Ez a `refcore_gendb` viselkedést megvalósító callback modul. Ez a viselkedés teszi lehetővé, hogy többféle különböző aatréteget kapcsoljunk a RefactorErl-hez.

<!-- 
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
-->

## 6 Path lekérdezés
Az adatbázisrétegnek nem csak az adatok tárolása, hanem azok lekérdezése is a feladata. A felhasználók által kiadott lekérdezéseket a RefactorErl átalakítja a saját path nyelvére. Az adatbázisréteghez már ezen a nyelven leírt lépések sorozataként érkezik meg a lekérdezés. 

A lépések feldolgozása rekurzívan történik. A lekérdezés eredményét a lépések által meghatározott részfa levelei alkotják.


# 7-8 Eredmények kiértékelése
A megvalósítást követően megvizsgáltam az új adatréteg teljesítményét és összehasonlítottam azt a RefactorErl Mnesia alapú, illetve `C++`-os NIF és Kyoto Cabinet alapú megoldásaival.

## 7 Adatbázis feltöltése
1. Először a kódbázis adatbázisba való betöltéséhez szükséges időt vizsgáltam meg a Mnesia adatbázis forráskódjával.
1. 5x ismételtem meg a mérést és ezek átlagát vettem végeredményül.
1. Itt az volt látható, hogy az Erlang alapú Mnesiához képest jelentős teljesítménynövekedést sikerült elérni. A C++ alapú megoldásokat viszont nem múlta felül.

## 8 Szemantikus lekérdezések
A szemantikus lekérdezésekhez szükséges idő vizsgálatakor 13 különböző lekérdezést vizsgáltam meg 2 adatbázison. A kisebbik szintén a Mnesia forrsákódját tartalmazta és ~95ezer csúcsot és ~900ezer élet tartalmazott. A nagyobb adatbázisba még betöltöttem az Erlang SSH és Edoc alkalmazások forrását, így ~950ezer csúcsos, >2millió éles adatbázist kapva.

1. Az esetek többségében itt is az figyelhető meg, hogy a map-es adatbázis gyorsabb, mint a Mnesiás. 
1. Ez alól kivételt képeztek például a 3-as és 6-os lekérdezések. Ezek lokalizált adatokat kérdeztek le a Mnesia forrásához kapcsolódóan. Ilyen esetekben a Mnesia jobb volt, mint általában. 
1. Viszont a 7-13 lekérdezéseknél nagyon jó eredményeket mutatott az új adatbázis. A Mnesia alapú adatréteg általában táblák kapcsolásával, 1 lekérdezésben kérdezi le a szükséges adatokat, melyet a Mnesia adatbázis motorja optimalizál. Ezt viszont nem minden esetben tudja megtenni, például adatfolyammal kapcsolatok lekérdezése esetén sem. Ilyenkor a Mnesia is a map-hoz hasonlóan sok kis lekérdezés részeredményeiből építi fel a végső eredményt. Ilyenkor az adatstruktúrák adatelérési sebessége jobban megmutatkozik a mérési eredményeken.  
(Ilyenkor tranzitív lezártat kell számolni)


# 9 Helyesség vizsgálata (konzisztencia)
A működés gyorsaságán kívül a műveletek helyességét is megvizsgáltam. A RefactorErl már rendelkezett egy teszt interfésszel az adatrétegek ellenőrzésére. Ennek használatáhzo egy callback modult kellett megvalósítanom, ami a map alapú adatréteghez kapcsolódva végez el műveleteket.
1. A teszt futtatásához 3 RefactorErl példányt kell elindítani.  
&rarr; Kettőt az összehasonlítás alatt álló adatrétegek számára  
&rarr; És egy harmadikat a tesztek futtatására. Ez kapcsolódik az adatbázisokhoz és **ellenőrzi az adatok konzisztenciáját**.  

Az új map alapú adatbázis átment a teszteken, így igazoltam annak helyes működését.


# 10 Összefoglaló
Összefoglalva tehát a diplomamunkám során:
1. Előzetes méréseket végeztem, hogy megvizsgáljam az Erlang adattárolóit. Ez alapján kiválasztottam a map adatstruktúrát.
2. Ennek segítségével megvalósítottam egy attribútumgráfok tárolására alkalmas, in-memory adatbáziskezelőt és integráltam azt a RefactorErl rendszerébe.
3. Végezetül pedig leteszteltem az elkészült szoftver működését, valamint méréseket végeztem. Ezek alapján jelentős teljesítmény növekedést sikerült elérni az alapértelmezett Mnesiás adatréteghez képest, mind betöltési, mind lekérdezési idők tekintetében.


# Válaszdiák
- path nyelv
- path algoritmus
- mérésekről 1-2 táblázat/ábra

# Esetleges kérdések 
1. Miért nem mértem Erlang struktúrák módosítási idejét?  
A törlés hasonló eredményeket produkált, így nem hozott be új információt. (Ugyanúgy keresés és felülírás szükséges hozzá.)

1. Miért nem `array` struktúrát használtam?  
Nagy megkötésnek éreztük az integer key-t. Nem is kulcs-érték párok tárolására való.

1. A `gb_tree` tárolót miért nem vizsgáltam? (**G**eneral **B**alanced Tree)  
- A map-ek kifejezetten a `gb_tree`-k és `dict`-ek helyettesítő utódjaként jött létre.
- Mivel *balanced*, ezért bizonyos beszúrások során szükség lehet a fa kiegyenlítésére, ami lassítja a beszúrásokat.
- A `gb_tree` teljesítménye hasonló a `dict`-éhez, amit hamar ki is zártam, pedig jellemzően a `dict` olvasási sebessége jobb, mint a `gb_tree`-é.

1. Haskell adatstruktúrák, hogy lehetne attrib gráfot ábrázolni?
- Az adatmodell rekordjait lehet algebrai adattípusként ábrázolni.
- A `gen_server` helyett `State Monad`-ot lehetne használni az állapot tárolására.
- A `refcore_gendb` helyett lehetne egy `class`, ami eltárolja a DB kliens interfészét.
- &uarr; Ennek egy példánya megvalósíthatná a `refcore_gendb` metódusait, mint a `refdb_map` callback modul.
- &uarr; `State Monad` ennek a példány függvényeinek használatával manipulálhatja a gráfot.

1. Mi lenne ha Haskell tároló lenne?  
Erlang-Haskell együtt lassú lenne (io kontextusváltás)  
Erlang alapú volt a cél kifejezetten &rarr; **függőségmentes**

1. Path nyelvet definiáld Haskellben!  
```haskell
-- TODO
```