--Stanje na tablici isto?ne konferencije
SELECT
    k.punoime AS "Puno ime kluba",
    COUNT(u.utakmicaid) AS "Ukupno odigrane utakmice",
    SUM(CASE WHEN k.klubid = u.klubpobjednikid THEN 1 ELSE 0 END) AS "Ukupno pobjeda",
    SUM(CASE WHEN k.klubid = u.klubgubitnikid THEN 1 ELSE 0 END) AS "Ukupno poraza",
    ROUND(((SUM(CASE WHEN k.klubid = u.klubpobjednikid THEN 1 ELSE 0 END) / COUNT(u.utakmicaid)) * 100) / 100, 3) AS "Postotak pobjeda"
FROM
    klubovi k
LEFT JOIN
    utakmice u ON k.klubid = u.klubpobjednikid OR k.klubid = u.klubgubitnikid
LEFT JOIN
    divizije d ON k.divizijaid = d.divizijaid
LEFT JOIN
    konferencije kc ON d.konferencijaid = kc.konferencijaid
WHERE
    kc.naziv = 'Istocna'
GROUP BY
    k.klubid, k.punoime
ORDER BY
    "Postotak pobjeda" DESC;
    
--Stanje na tablici zapadne konferencije

SELECT
    k.punoime AS "Puno ime kluba",
    COUNT(u.utakmicaid) AS "Ukupno odigrane utakmice",
    SUM(CASE WHEN k.klubid = u.klubpobjednikid THEN 1 ELSE 0 END) AS "Ukupno pobjeda",
    SUM(CASE WHEN k.klubid = u.klubgubitnikid THEN 1 ELSE 0 END) AS "Ukupno poraza",
    ROUND(((SUM(CASE WHEN k.klubid = u.klubpobjednikid THEN 1 ELSE 0 END) / COUNT(u.utakmicaid)) * 100) / 100, 3) AS "Postotak pobjeda"
FROM
    klubovi k
LEFT JOIN
    utakmice u ON k.klubid = u.klubpobjednikid OR k.klubid = u.klubgubitnikid
LEFT JOIN
    divizije d ON k.divizijaid = d.divizijaid
LEFT JOIN
    konferencije kc ON d.konferencijaid = kc.konferencijaid
WHERE
    kc.naziv = 'Zapadna'
GROUP BY
    k.klubid, k.punoime
ORDER BY
    "Postotak pobjeda" DESC;

-- Gradovi u kojima se nalazi vi�e klubova
    
SELECT g.ime AS "Grad",
        LISTAGG(k.imefransize, ', ') WITHIN GROUP (ORDER BY k.punoime) AS "Fran�ize"
FROM
    gradovi g
INNER JOIN
    dvorane d ON g.gradid = d.gradid
INNER JOIN
    klubovi k ON d.dvoranaid = k.dvoranaid
GROUP BY
    g.ime
HAVING
    COUNT(*) >= 2;
    
    
-- treneri koji su u karijeri vodili vi�e od jednog kluba
SELECT t.ime, t.prezime, LISTAGG(k.punoime, ', ') WITHIN GROUP (ORDER BY k.punoime) AS klubovi
FROM treneri t
JOIN treneri_klubovi tk ON t.trenerid = tk.trenerid
JOIN klubovi k ON tk.klubid = k.klubid
GROUP BY t.ime, t.prezime
HAVING COUNT(DISTINCT tk.klubid) > 1;

-- top 5 igra?a po prosje?nom broju poena po utakmici (statistike karijere)

SELECT i.ime, i.prezime, k.punoime AS klub, sk.poeni as "POENI PO UTAKMICI"
FROM statistikekarijera sk
JOIN igraci i ON sk.igracid = i.igracid
JOIN igraci_klubovi ik ON i.igracid = ik.igracid
JOIN klubovi k ON ik.klubid = k.klubid
ORDER BY sk.poeni DESC
FETCH FIRST 5 ROWS ONLY;

-- Top 10 dr�ava po broju igra?a 

SELECT d.ime AS "Dr�ava", COUNT(i.igracid) AS "Broj igraca"
FROM igraci i
JOIN drzave d ON i.drzave_nacionalnostid = d.drzavaid
GROUP BY d.ime
ORDER BY COUNT(i.igracid) DESC
FETCH FIRST 10 ROWS ONLY;

-- Top 10 igra?a mla?ih od 30 godina koji su postigli triple double u?inke

SELECT i.ime, i.prezime, EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM i.datumrodenja) AS godine,
       k.punoime AS klub, dr.ime AS nacionalnost, COUNT(*) AS broj_triple_doubleova
FROM statistikeigraca si
JOIN igraci i ON si.igracid = i.igracid
JOIN igraci_klubovi ik ON i.igracid = ik.igracid
JOIN klubovi k ON ik.klubid = k.klubid
JOIN drzave dr ON i.drzave_nacionalnostid = dr.drzavaid
WHERE si.poeni >= 10
AND si.skokovi >= 10
AND si.asistencije >= 10
AND EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM i.datumrodenja) < 30
GROUP BY i.ime, i.prezime, EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM i.datumrodenja),
         k.punoime, dr.ime
ORDER BY broj_triple_doubleova DESC
FETCH FIRST 10 ROWS ONLY;

-- Top 3 utakmice iz doigravanja po razlici poena

SELECT u.utakmicaid AS "UTAKMICA ID",
       kd.imefransize || ' - ' || kg.imefransize AS Utakmica,
       su.brojpoenadomacina || ' - ' || su.brojpoenagosta AS Rezultat,
       'doigravanje' AS "VRSTA UTAKMICE",
       ABS(su.brojpoenadomacina - su.brojpoenagosta) AS "RAZLIKA POENA"
FROM utakmice u
JOIN klubovi kd ON u.klubdomacinid = kd.klubid
JOIN klubovi kg ON u.klubgostid = kg.klubid
JOIN statistikeutakmica su ON u.utakmicaid = su.utakmicaid
WHERE 'Doigravanje' IN (SELECT vrsta FROM vrsteutakmica)
ORDER BY "RAZLIKA POENA" DESC
FETCH FIRST 3 ROW ONLY;


-- Igra?i iz isto?ne konferencije s najvi�e skokova po utakmici

SELECT DISTINCT i.ime, i.prezime, i.visina, k.imefransize AS fran�iza, sk.skokovi AS broj_skokova
FROM igraci i
JOIN igraci_pozicije ip ON i.igracid = ip.igracid
JOIN pozicije p ON ip.pozicijaid = p.pozicijaid
JOIN klubovi k ON i.igracid = k.klubid
JOIN statistikekarijera sk ON i.igracid = sk.igracid
JOIN divizije d ON k.divizijaid = d.divizijaid
JOIN konferencije kc ON d.konferencijaid = kc.konferencijaid
WHERE p.naziv IN ('Visoko krilo', 'Centar')
AND kc.naziv = 'Istocna'
ORDER BY sk.skokovi DESC
FETCH FIRST 5 ROWS ONLY;

-- Broj utakmica koje je odsudio svaki sudac
SELECT s.ime, s.prezime, d.ime AS nacionalnost, COUNT(u.sudacid) AS "BROJ ODSU?ENIH UTAKMICA"
FROM suci s
JOIN drzave d ON s.drzave_nacionalnostid = d.drzavaid
JOIN utakmice u ON s.sudacid = u.sudacid
GROUP BY s.ime, s.prezime, d.ime;

-- Igra?i koji su vi�i od 2m, a odigrali su vi�e od 40 minuta u utakmici
SELECT 
    i.ime,
    i.prezime,
    i.visina,
    si.utakmicaid,
    k.punoime AS klub,
    dr.ime AS nacionalnost,
    si.minutaza AS broj_minuta,
    p.naziv AS pozicija
FROM 
    statistikeigraca si
JOIN 
    igraci i ON si.igracid = i.igracid
JOIN 
    igraci_klubovi ik ON i.igracid = ik.igracid
JOIN 
    klubovi k ON ik.klubid = k.klubid
JOIN 
    drzave dr ON i.drzave_nacionalnostid = dr.drzavaid
JOIN 
    igraci_pozicije ip ON i.igracid = ip.igracid
JOIN 
    pozicije p ON ip.pozicijaid = p.pozicijaid
WHERE 
    i.visina > 2.0
    AND si.minutaza > 40
ORDER BY 
    si.utakmicaid DESC
FETCH FIRST 10 ROWS ONLY;



-- Najbolji igra?i po postoku pogo?enih slobodnih bacanja

SELECT 
    i.ime,
    i.prezime,
    dr.ime AS nacionalnost,
    ROUND((si.pogodenaslobodnabacanja / si.pokusajislobodnihbacanja) * 100, 2) AS postotak_slobodnih_bacanja
FROM 
    statistikeigraca si
JOIN 
    igraci i ON si.igracid = i.igracid
JOIN
    drzave dr ON i.drzave_nacionalnostid = dr.drzavaid
ORDER BY 
    postotak_slobodnih_bacanja DESC
FETCH FIRST 5 ROWS ONLY;

































