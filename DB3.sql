--//////////////////////////////////////////////////////////////////// VYGENEROVANIE TABULIEK ////////////////////////////////////////////////////////////////////////////////////////////
CREATE TABLE Pouzivatel
(
	pouzivatelske_meno   VARCHAR2(20) NOT NULL ,
	meno                 VARCHAR2(20) NOT NULL ,
	priezvisko           VARCHAR2(20) NOT NULL ,
	datum_narodenia      DATE NOT NULL ,
	email                VARCHAR2(20) NOT NULL ,
	heslo                VARCHAR2(50) NOT NULL ,
	datum_registracie    DATE NOT NULL 
);

CREATE UNIQUE INDEX XPKPouzivatel ON Pouzivatel
(pouzivatelske_meno   ASC);

ALTER TABLE Pouzivatel
	ADD CONSTRAINT  XPKPouzivatel PRIMARY KEY (pouzivatelske_meno);

CREATE TABLE Prispevky
(
	nadpis               VARCHAR2(20) NOT NULL ,
	text                 VARCHAR2(200) NOT NULL ,
	cas_pridania_prispevku DATE NOT NULL ,
	id                   INTEGER NOT NULL ,
	pouzivatelske_meno   VARCHAR2(20) NOT NULL 
);

CREATE UNIQUE INDEX XPKPrispevky ON Prispevky
(id   ASC,pouzivatelske_meno   ASC);

ALTER TABLE Prispevky
	ADD CONSTRAINT  XPKPrispevky PRIMARY KEY (id,pouzivatelske_meno);

CREATE TABLE ReakcieAKomentare
(
	komentar             VARCHAR2(100) NULL ,
	reakcie              CHAR(1) NULL  CONSTRAINT  Reakcia CHECK (reakcie IN('L', 'D', 'H')),
	datum_reakcie        DATE NULL ,
	id                   INTEGER NOT NULL ,
	pouzivatelske_meno   VARCHAR2(20) NOT NULL ,
	komentujuci          VARCHAR2(20) NOT NULL ,
	idKomentara          INTEGER NOT NULL 
);

CREATE UNIQUE INDEX XPKReakcieAKomentare ON ReakcieAKomentare
(id   ASC,pouzivatelske_meno   ASC,komentujuci   ASC,idKomentara   ASC);

ALTER TABLE ReakcieAKomentare
	ADD CONSTRAINT  XPKReakcieAKomentare PRIMARY KEY (id,pouzivatelske_meno,komentujuci,idKomentara);

CREATE TABLE Udalosti
(
	datum_udalosti       DATE NOT NULL ,
	pouzivatelske_meno   VARCHAR2(20) NOT NULL 
);

CREATE UNIQUE INDEX XPKUdalosti ON Udalosti
(datum_udalosti   ASC,pouzivatelske_meno   ASC);

ALTER TABLE Udalosti
	ADD CONSTRAINT  XPKUdalosti PRIMARY KEY (datum_udalosti,pouzivatelske_meno);

CREATE TABLE Pozvani
(
	datum_odpovede       DATE NOT NULL ,
	odpoved_ucasti       CHAR(1) NULL  CONSTRAINT  odpoved_ucasti CHECK (odpoved_ucasti IN('Y', 'N', 'M')),
	datum_udalosti       DATE NOT NULL ,
	pouzivatelske_meno   VARCHAR2(20) NOT NULL ,
	Pozvani              VARCHAR2(20) NOT NULL 
);

CREATE UNIQUE INDEX XPKpozvani ON Pozvani
(datum_udalosti   ASC,pouzivatelske_meno   ASC,Pozvani   ASC);

ALTER TABLE Pozvani
	ADD CONSTRAINT  XPKpozvani PRIMARY KEY (datum_udalosti,pouzivatelske_meno,Pozvani);

CREATE TABLE Vztahy
(
	cas_vzniku           DATE NULL ,
	pouzivatelske_meno   VARCHAR2(20) NOT NULL ,
	sledovatel           VARCHAR2(20) NOT NULL ,
	id                   INTEGER NOT NULL 
);

CREATE UNIQUE INDEX XPKVztahy ON Vztahy
(pouzivatelske_meno   ASC,sledovatel   ASC,id   ASC);

ALTER TABLE Vztahy
	ADD CONSTRAINT  XPKVztahy PRIMARY KEY (pouzivatelske_meno,sledovatel,id);

CREATE TABLE Oznaceni
(
	id                   INTEGER NOT NULL ,
	pouzivatelske_meno   VARCHAR2(20) ,
	oznaceni             VARCHAR2(20)
);

CREATE UNIQUE INDEX XPKPouzivatelia ON Oznaceni
(id   ASC,pouzivatelske_meno   ASC,oznaceni   ASC);

ALTER TABLE Oznaceni
	ADD CONSTRAINT  XPKPouzivatelia PRIMARY KEY (id,pouzivatelske_meno,oznaceni);
    
    
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////// PRIDANIE PROCED�R, TRIGGROV, FUNKCI� at�.. /////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


-- Procedura 1 pridaj_sledovatela     
create or replace PROCEDURE pridaj_sledovatela(pouzivatel VARCHAR2, sledovatel varchar2, idVztahu integer)
is
    overenie varchar(20);
    overeniePreS varchar(20);
begin
    select pouzivatelske_meno into overenie from pouzivatel where pouzivatel = pouzivatelske_meno;
    select pouzivatelske_meno into overeniePreS  from pouzivatel where sledovatel = pouzivatelske_meno;
    if overenie = pouzivatel and overeniePreS = sledovatel and overenie <> overeniePreS then
        insert into Vztahy values(sysdate, pouzivatel, sledovatel, idVztahu);
    elsif pouzivatel <> overenie then
        raise_application_error(-20000, 'Dan� pu�ivate�: ' || pouzivatel || ' neexistuje preto nebolo mo�n� prida� sledovate�a');
    elsif sledovatel <> sledovatel then
         raise_application_error(-20000, 'Dan� pu�ivate�: ' || sledovatel || '  neexistuje preto nebolo mo�n� prida� sledovate�a');
    elsif overenie = overeniePreS then
        raise_application_error(-20000, 'Po�ivate� sa nem��e sledova� seba sam�ho');
    else
        raise_application_error(-20000, 'Chyba nastala niekde inde');
    end if;  
end;
/

-- Procedura 2 pridaj_udalost 
create or replace PROCEDURE pridaj_Udalost(pouzivatel varchar2, datum_udalosti date)
is
    overeniePouzivatela varchar2(20);
begin
    select pouzivatelske_meno into overeniePouzivatela from pouzivatel where pouzivatel = pouzivatelske_meno; 
    if overeniePouzivatela = pouzivatel and datum_udalosti >= sysdate then
        insert into udalosti values(pouzivatel, datum_udalosti);
    elsif  overeniePouzivatela <> pouzivatel then
        raise_application_error(-20000, 'Dan� pu�ivate�: ' || pouzivatel || ' neexistuje preto nebolo mo�n� prida� udalos�');
    elsif datum_udalosti < sysdate then
        raise_application_error(-20000, 'Nie je mo�ne prida� d�tum udalosti lebo datum je u� "v�eraj��"');
    else
        raise_application_error(-20000, 'Chyba nastala niekde inde');
    end if;
end;
/

-- Procedura 3 vymaz_pouzivatela
create or replace Procedure vymaz_pouzivatela(pouzivatel varchar2)
is
begin
    delete from pouzivatel where pouzivatelske_meno = pouzivatel;
    -- odstranenie dalsich veci spojenych s pouzivatelom je zabezpecene triggrom
end;
/

-- Procedura 4 - pridanie pou��vate�a    
create or replace procedure add_user
(p_pouzivatelske_meno IN Pouzivatel.pouzivatelske_meno%TYPE,
 p_meno IN Pouzivatel.meno%TYPE,
 p_priezvisko IN Pouzivatel.priezvisko%TYPE,
 p_datum_narodenia IN Pouzivatel.datum_narodenia%TYPE,
 p_email IN Pouzivatel.email%TYPE,
 p_heslo IN Pouzivatel.heslo%TYPE)
 IS
 BEGIN
    insert into Pouzivatel(pouzivatelske_meno, meno, priezvisko, datum_narodenia, email, heslo, datum_registracie)
    values (p_pouzivatelske_meno, p_meno, p_priezvisko, p_datum_narodenia, p_email, p_heslo, sysdate);
 END;
 /
 
-- Procedura 5 drop_tables
CREATE OR REPLACE PROCEDURE drop_tables
IS
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE vztahy';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE pozvani';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE udalosti';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE reakcieAKomentare';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE oznaceni';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE prispevky';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE pouzivatel';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
END;
/

-- Procedura 6 napln_tab_pouzivatel 
create or replace PROCEDURE napln_tab_pouzivatel(riadky integer)
is
  i NUMBER := 0;
  pouzivatelske_meno VARCHAR2(20);
  meno VARCHAR2(20);
  priezvisko VARCHAR2(20);
  datum_narodenia DATE;
  email VARCHAR2(20);
  heslo VARCHAR2(50);
  datum_registracie DATE;
  datum_od DATE :=  TO_DATE('1960-01-01', 'YYYY-MM-DD');
BEGIN
    LOOP
    -- Generovanie n�hodn�ch hodn�t
      pouzivatelske_meno := 'user' || i;
      meno := 'Meno' || i;
      priezvisko := 'Priezvisko' || i;
      datum_narodenia :=  datum_od + FLOOR(DBMS_RANDOM.VALUE(0, sysdate - datum_od));
      email := 'email' || i || '@gmail.com';
      heslo := 'heslo' || i;
      datum_registracie := datum_narodenia + FLOOR(DBMS_RANDOM.VALUE(0, sysdate - datum_narodenia + 18));
      -- Vlo�enie hodn�t do tabu�ky Pouzivatel
      INSERT INTO Pouzivatel VALUES (pouzivatelske_meno, meno, priezvisko, datum_narodenia, email, heslo, datum_registracie);
    exit when i > riadky;
    i := i + 1;
  END LOOP;
END;
/

-- Procedura 7 napln_tab_vztahy
create or replace PROCEDURE napln_tab_vztahy(riadky integer)
is 
    i number := 1;
    pouzivatelske_meno VARCHAR2(20);
    datum1 date;
    sledovatel VARCHAR2(20);
    datum2 date;
    id integer;
begin
    loop
    SELECT pouzivatelske_meno,datum_registracie INTO pouzivatelske_meno, datum1
        FROM (SELECT pouzivatelske_meno,datum_registracie  FROM Pouzivatel ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
    SELECT pouzivatelske_meno,datum_registracie  INTO sledovatel, datum2
    FROM (SELECT pouzivatelske_meno, datum_registracie FROM Pouzivatel ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    id := i;
    if pouzivatelske_meno <> sledovatel  and datum1 > datum2 then
        insert into Vztahy VALUES (datum1 + TRUNC(DBMS_RANDOM.VALUE * (SYSDATE - datum1 + 1)) , pouzivatelske_meno, sledovatel, id);
        i:= i+1;
    elsif  pouzivatelske_meno <> sledovatel  and datum1 < datum2 then 
        insert into Vztahy VALUES (datum2 + TRUNC(DBMS_RANDOM.VALUE * (SYSDATE - datum2 + 1)) , pouzivatelske_meno, sledovatel, id);
        i:= i+1;
    end if;
    exit when i > riadky;
    end loop;
end;
/

-- Procedura 8 napln_tab_udalosti
create or replace PROCEDURE napln_tab_udalosti(riadky integer)
is 
    i number := 1; 
    meno varchar2(20);
begin
    LOOP
    
    SELECT pouzivatelske_meno INTO meno
        FROM (SELECT pouzivatelske_meno FROM Pouzivatel ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    insert into udalosti values(sysdate + TRUNC(DBMS_RANDOM.VALUE * 200), meno);
    i:= i+1;
    exit when i > riadky;
    end loop;
end;
/

--Procedura 9 napln_tab_pozvani
create or replace PROCEDURE napln_tab_pozvani(riadky integer)
is
    i number := 1; 
    konatel varchar2(20);
    datum1 date;
    pozvani varchar2(20);
    cislo integer;
    odpoved char(1);
begin
    loop
    SELECT pouzivatelske_meno, datum_udalosti INTO konatel, datum1
        FROM (SELECT pouzivatelske_meno, datum_udalosti FROM Udalosti ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    SELECT pouzivatelske_meno INTO pozvani
        FROM (SELECT pouzivatelske_meno FROM Pouzivatel ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    cislo := FLOOR(DBMS_RANDOM.VALUE(1,4));
    if cislo = 1 then
        odpoved := 'Y';
    elsif cislo = 2 then
         odpoved := 'M';
    else 
         odpoved := 'N';
    end if;
    insert into Pozvani values(datum1 - Floor(DBMS_RANDOM.VALUE(1,500)), odpoved, datum1,  konatel, pozvani);
    i := i+1;
    exit when i > riadky;
    end loop;
end;
/

-- Procedura 10 napln_tab_prispevky
create or replace PROCEDURE napln_tab_prispevky(riadky integer)
is
    i number := 1; 
    meno varchar2(20);
    datum1 date;
    nadpis varchar2(20);
    text varchar2(200);
begin
    loop
    SELECT pouzivatelske_meno, datum_registracie INTO meno, datum1
        FROM (SELECT pouzivatelske_meno, datum_registracie FROM Pouzivatel ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    nadpis := dbms_random.string('A',dbms_random.value(5,20));    
    text :=  dbms_random.string('A',dbms_random.value(10,200));
    insert into Prispevky values(nadpis,text,datum1 + DBMS_RANDOM.VALUE(0, sysdate - datum1),i,meno);
    i := i+1;
    exit when i > riadky;
    end loop;
end;
/

-- Procedura 11 napln_tab_oznaceni
create or replace PROCEDURE napln_tab_oznaceni(riadky integer)
is 
    i number := 1;
    id integer;
    meno varchar2(20);
    oznaceni varchar2(20);
    datum2 date; -- datum pridania prispevku
begin
    Loop
    SELECT pouzivatelske_meno, id, cas_pridania_prispevku  INTO meno, id, datum2
        FROM (SELECT pouzivatelske_meno, id, cas_pridania_prispevku FROM prispevky ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
        
    SELECT pouzivatelske_meno INTO oznaceni
        FROM (SELECT pouzivatelske_meno FROM Pouzivatel where datum2 > datum_registracie ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    
    insert into oznaceni values(id, meno, oznaceni);
    i := i+1;
    exit when i > riadky;
    end loop;
end;
/


-- Procedura 12 napln_tab_reakcie_a_komentare
create or replace PROCEDURE napln_tab_reakcie_a_komentare(riadky integer)
is
    i integer := 1;
    meno varchar2(20);
    id number;
    komentujuci varchar2(20);
    datum1 date; -- cas pridania prispevku 
    komentar varchar2(100);
    reakcia char(1);
    random integer;
begin
    LOOP
    select pouzivatelske_meno, id, cas_pridania_prispevku into meno, id, datum1 
        from (select pouzivatelske_meno, id, cas_pridania_prispevku from prispevky ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    select pouzivatelske_meno into komentujuci 
        from (select pouzivatelske_meno from pouzivatel where datum1 > datum_registracie ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
    random := DBMS_RANDOM.VALUE(1,4);
    komentar := DBMS_RANDOM.string('A', dbms_random.value(5,100));
    if random = 1 then
        reakcia := 'L';
    elsif random = 2 then
        reakcia := 'H';
    else
        reakcia := 'D';
    end if;
    insert into reakcieAkomentare values(komentar, reakcia, datum1 + DBMS_RANDOM.VALUE(0, sysdate - datum1),id, meno, komentujuci, i);
    i := i + 1;
    exit when i > riadky;   
    end loop;
end;
/

-- Funkcia 1 pocet_sledovatelov 
create or replace FUNCTION  pocet_sledovatelov (pouzivatel varchar2)
return integer
is
    pocet integer;
begin 
    select count(pouzivatelske_meno) into pocet from vztahy where pouzivatel = pouzivatelske_meno group by pouzivatelske_meno;
    return pocet;
end;
/

-- Funkcia 2 pocet_prispevkov
create or replace FUNCTION  pocet_prispevkov (pouzivatel varchar2)
return integer
is
    pocet integer;
begin 
    select count(pouzivatelske_meno) into pocet from prispevky where pouzivatel = pouzivatelske_meno group by pouzivatelske_meno;
    return pocet;
end;
/

-- Funkcia 3 pocet_dostanych_reakcii_komentarov_pouzivatelovi
create or replace FUNCTION  pocet_dostanych_reakcii_komentarov_pouzivatelovi (pouzivatel varchar2)
return integer
is
    pocet integer;
begin 
    select count(r.id) into pocet 
    from prispevky p
    join reakcieAkomentare r on p.id = r.id
    where pouzivatel = p.pouzivatelske_meno and r.reakcie is not null 
    group by r.id;
    return pocet;
end;
/

-- Funkcia 4 pocet_rozdanych_reakcii_komentarov__pouzivatela
create or replace FUNCTION  pocet_rozdanych_reakcii_komentarov__pouzivatela (pouzivatel varchar2)
return integer
is
    pocet integer;
begin 
    select count(komentujuci) into pocet 
    from reakcieAkomentare p
    where komentujuci = pouzivatel and reakcie is not null
    group by komentujuci;
    return pocet;
end;
/


-- Trigger 1 pri t_kaskada_zmeny_pouzivatelskeho_mena;
create or replace trigger t_kaskada_zmeny_pouzivatelskeho_mena
after update on pouzivatel
for each row 
begin
    update vztahy set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update vztahy set sledovatel = :new.pouzivatelske_meno where sledovatel = :old.pouzivatelske_meno;
    update udalosti set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update pozvani set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update pozvani set pozvani = :new.pouzivatelske_meno where pozvani = :old.pouzivatelske_meno;
    update prispevky set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update reakcieAkomentare set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update reakcieAkomentare set komentujuci = :new.pouzivatelske_meno where komentujuci = :old.pouzivatelske_meno;
    update oznaceni set pouzivatelske_meno = :new.pouzivatelske_meno where pouzivatelske_meno = :old.pouzivatelske_meno;
    update oznaceni set oznaceni = :new.pouzivatelske_meno where oznaceni = :old.pouzivatelske_meno;
end;
/

-- Trigger 2 zamedzit vytvorenia udalosti z datumom udalosti ako je aktualny datum t_kontrola_datumu_udalosti
create or replace trigger t_kontrola_datumu_udalosti
before update or insert on udalosti
for each row 
begin
    if :new.datum_udalosti < sysdate then
        raise_application_error(-20000, 'D�tum udalsti nesmie by� "v�eraj��"');
    end if;
end;
/

-- Trigger 3 kaskada vymazania pouzivatela t_k_vymazania_pouzivatela
create or replace trigger t_k_vymazania_pouzivatela
before delete on pouzivatel
for each row 
begin
    delete from vztahy where pouzivatelske_meno = :old.pouzivatelske_meno;
    delete from vztahy where sledovatel = :old.pouzivatelske_meno;
    delete from pozvani where pouzivatelske_meno = :old.pouzivatelske_meno;
    delete from pozvani where pozvani = :old.pouzivatelske_meno;
    delete from udalosti where pouzivatelske_meno = :old.pouzivatelske_meno;
    delete from reakcieAkomentare where pouzivatelske_meno = :old.pouzivatelske_meno;
    delete from reakcieAkomentare where komentujuci = :old.pouzivatelske_meno;
    delete from prispevky where  pouzivatelske_meno = :old.pouzivatelske_meno;
    delete  from oznaceni  where pouzivatelske_meno = :old.pouzivatelske_meno;
    delete from oznaceni  where oznaceni = :old.pouzivatelske_meno;
end;
/

 
 -- Trigger 4 - pri zmene textu prispevku zmenit aj cas pridania
 create or replace trigger tr_zmena_prispevku_text
 before update of text on Prispevky
 for each row
 begin
    update Prispevky
    set cas_pridania_prispevku = sysdate
    where text = :old.text;
 end;
 /
 
 -- Trigger 5 - t_zamedzenie_oznaceniu_sameho_seba
 create or replace trigger t_zamedzenie_oznaceniu_sameho_seba
 before update or insert on oznaceni 
 for each row
 begin
    if :new.oznaceni = :old.pouzivatelske_meno then
    raise_application_error(-20000, 'Pou�ivate� nem��e ozna�i� seba sam�ho');
    end if;
 end;
 /
 
 -- Trigger 6 tr_zmena_prispevku_text pri zmene textu prispevku zmenit aj cas pridania, vyuzity implicitny kurzor
 create or replace trigger tr_zmena_prispevku_text
 before update of text on Prispevky
 for each row
 begin
    update Prispevky
    set cas_pridania_prispevku = sysdate
    where text = :old.text;
    if sql%found then
        dbms_output.put_line('Text prispevku bol zmeneny, menim aj cas pridania prispevku');
    end if;    
 end;
 /
 

 
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- ////////////////////////////////////////////////////////////   AUTOMATICK� VKLADANIE A GENEROVANIE �DAJOV  ///////////////////////////////////////////////////////////////
 --//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
   
--VKLADANIE HODNOT DO TABULKY POUZIVATEL
EXEC napln_tab_pouzivatel(50);
--VKLADANIE HODNOT DO TABULKY VZTAHY
exec napln_tab_vztahy(80);
--VKLADANIE HODNOT DO TABULKY UDALOSTI
exec napln_tab_udalosti(45);
--VKLADANIE HODNOT DO TABULKY POZVANI
exec napln_tab_pozvani(20);
--VKLADANIE HODNOT DO TABULKY PRISPEVKY
exec napln_tab_prispevky(100);
--VKLADANIE HODNOT DO TABULKY OZNACENI
exec napln_tab_oznaceni(30);
--VKLADANIE HODNOT DO TABULKY REAKCIEAKOMENTARE
exec napln_tab_reakcie_a_komentare(200);
   
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////   JEDNOTLIV� V�PISI   /////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- vcerajsie prispevky

select * 
from prispevky
where extract(day from cas_pridania_prispevku) = extract(day from (sysdate - 1));
-- pouzivatel ktori nesleduje aspon 10 a jeho sleduje aspon 10  
select p.pouzivatelske_meno, count(v.sledovatel) as pocet_sledovanych_pouzivatelov
from pouzivatel p 
join vztahy v on p.pouzivatelske_meno = v.sledovatel
where exists (select 'X'
             from pouzivatel l
             join vztahy h on l.pouzivatelske_meno = h.pouzivatelske_meno
            group by h.pouzivatelske_meno
            having count(h.sledovatel) > 10)
group by v.sledovatel, p.pouzivatelske_meno
having count(v.sledovatel) < 10;

 -- 1. parametrizovana zostava - vypis prispevkov pouzivatela
select * from Prispevky
JOIN Pouzivatel USING(pouzivatelske_meno)
WHERE pouzivatelske_meno = &&vystup_pouzivatelske_meno;
undefine vystup_pouzivatelske_meno;

-- 2. V�pis pr�spevkov od pou��vate�ov sledovan�ch ur�it�m pou��vate�om.
select p.* 
from prispevky p
join (SELECT p.pouzivatelske_meno
      FROM pouzivatel p
      JOIN vztahy v ON p.pouzivatelske_meno = v.pouzivatelske_meno
      WHERE v.sledovatel =  &&vystup_pouzivatelske_meno) sub ON p.pouzivatelske_meno = sub.pouzivatelske_meno;
undefine vystup_pouzivatelske_meno;

-- 3. V�pis pou��vate�ov  s najviac sledovate�mi.
select p.pouzivatelske_meno, count(p.pouzivatelske_meno) as pocet_sledovatelov
from pouzivatel p
join vztahy v on p.pouzivatelske_meno = v.pouzivatelske_meno
group by p.pouzivatelske_meno
having count(p.pouzivatelske_meno) = (select max(count(l.pouzivatelske_meno))
            from pouzivatel l 
            join vztahy h on l.pouzivatelske_meno = h.pouzivatelske_meno
            group by l.pouzivatelske_meno);



            
-- 4. V�pis pou��vate�ov snajviac pr�spevkami
select p.pouzivatelske_meno, count(pr.pouzivatelske_meno) as pocet_prispevkov
from pouzivatel p
join prispevky pr on p.pouzivatelske_meno = pr.pouzivatelske_meno
group by p.pouzivatelske_meno
order by count(pr.pouzivatelske_meno) desc;

-- 5. V�pis pou��vate�ov snajviac komentovan�mi pr�spevkami.
select p.pouzivatelske_meno, p.id as id_prispevku, count(r.komentar) as pocet_komentov 
from prispevky p 
join reakcieAKomentare r on(p.id = r.id and r.komentar is not null)
group by p.id, p.pouzivatelske_meno
order by pocet_komentov desc;

-- 6.V�pis pou��vate�ov s pr�spevkami s najviac reakciami.
SELECT p.pouzivatelske_meno, pr.id as id_prispevku, COUNT(r.reakcie) AS pocet_reakcii
FROM pouzivatel p
JOIN prispevky pr ON (pr.pouzivatelske_meno = p.pouzivatelske_meno)
JOIN reakcieAkomentare r ON r.id = pr.id
GROUP BY p.pouzivatelske_meno, pr.id
ORDER BY COUNT(r.reakcie) DESC;

-- 7. V�pis pou��vate�ov, ktor� za�ali niekoho sledova� minul� t��de�.
SELECT p.pouzivatelske_meno, v.pouzivatelske_meno AS zacal_sledovat
FROM vztahy v
JOIN pouzivatel p ON v.sledovatel = p.pouzivatelske_meno
WHERE v.cas_vzniku >= TRUNC(SYSDATE) - INTERVAL '7' DAY AND v.cas_vzniku < TRUNC(SYSDATE);

-- 8.Vyp�sa� po�et registrovan�ch pou��vate�ov v danom obdob�
select count(pouzivatelske_meno) as pocet_registrovanych 
from pouzivatel
where datum_registracie between '27.03.2001' and '31.03.2022'; 

--9. Vyp�sa� po�et registrovan�ch pou��vate�ov pre jednotliv� roky.
SELECT EXTRACT(YEAR FROM datum_registracie) AS rok, COUNT(*) AS pocet_registrovanych
FROM pouzivatel
GROUP BY EXTRACT(YEAR FROM datum_registracie)
ORDER BY rok desc;

-- 10. V�po�et pr�rastku sledovate�ov pre jednotliv�ch pou��vate�ov za posledn�ch 365 dn�.
SELECT pouzivatelske_meno, COUNT(*) AS prirastok_sledovatelov
FROM vztahy
WHERE cas_vzniku >= SYSDATE - 365
GROUP BY pouzivatelske_meno;


--11. V�po�et priemern�ho ro�n�ho pr�rastku sledovate�ov pre jednotliv�ch pou��vate�ov
SELECT v.pouzivatelske_meno,
       CASE WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM datum_registracie) > 0 -- to mi zabezpeci pouzivatelov ktor� s� registrovan� viac ako jeden rok
            THEN COUNT(sledovatel) / (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM datum_registracie))
            ELSE 0
       END AS priemer_prirastku
FROM pouzivatel p
join vztahy v on p.pouzivatelske_meno = v.pouzivatelske_meno
GROUP BY v.pouzivatelske_meno, p.datum_registracie
ORDER BY priemer_prirastku DESC;
        

--12.V�pis najkomentovanej��ch pr�spevkov
select k.id as id_prispevku, k.pouzivatelske_meno, count(k.id) as pocet_komentov
from prispevky p
join reakcieAkomentare k on p.id = k.id
group by k.id, k.pouzivatelske_meno
order by pocet_komentov desc; 

-- 13. V�pis pr�spevkov s najviac reakciami dan�ho typu
select count(r.reakcie) as pocet_reakcii_daneho_typu, p.pouzivatelske_meno, p.id as id_prispevku, p.nadpis as nadpis_prispevku, p.text as text_prispevku, p.cas_pridania_prispevku  
from prispevky p 
join reakcieAKomentare r on(p.id = r.id and r.reakcie is not null and r.reakcie = 'D')
group by p.id, p.nadpis, p.text, p.pouzivatelske_meno, p.cas_pridania_prispevku 
order by pocet_reakcii_daneho_typu desc;


--14.V�pis najfrekventovanej�ie pou��van�ho�tagu� vdanom �asovom obdob�.
SELECT reakcie, COUNT(*) AS pocet_reakcii
FROM reakcieAkomentare
WHERE datum_reakcie BETWEEN '1.2.1999' AND '3.4.2023'
GROUP BY reakcie
ORDER BY COUNT(*) DESC;

-- 15. V�pis �tagov�, ktor� za posledn� 3 mesiace boli pou�it� menej ako 5 kr�t alebo neboli pou�it� v�bec
SELECT reakcie, COUNT(reakcie) AS pocet
FROM reakcieAkomentare
WHERE datum_reakcie >= sysdate - 90 
GROUP BY reakcie
HAVING COUNT(reakcie) < 30 OR COUNT(reakcie) is null; -- dal som 30 nech to nieco vypsise

-- 16.V�pis najakt�vnej��ch pou��vate�ov vzh�adom na pr�spevky in�ho pou��vate�a 
--(ktor� pou��vate� najviac komentoval/dal najviac reakci� na pr�spevky nejak�ho pou��vate�a
select k.komentujuci as pouzivatel, count(k.komentujuci) as pocet_zanechanych_komentov
from pouzivatel p
join reakcieAkomentare k on p.pouzivatelske_meno = k.komentujuci
group by k.komentujuci 
order by pocet_zanechanych_komentov desc;

-- 17.V�pis pr�spevkov, ktor� obsahuj� menej ako 5 tagov
SELECT *
FROM prispevky
WHERE id IN (
    SELECT id
    FROM reakcieAkomentare
    GROUP BY id
    HAVING COUNT(reakcie) < 5);
    
-- 18. V�pis pr�spevku s najviac reakciami pre ka�d�ho pou��vate�a
select p.id as id_prispevku, p.pouzivatelske_meno, count(k.reakcie) as pocet_reakcii
from prispevky p
join reakcieAkomentare k on p.id = k.id
where k.reakcie is not null and p.pouzivatelske_meno in
                                (select r.pouzivatelske_meno
                                from reakcieAkomentare r
                                where p.pouzivatelske_meno = r.pouzivatelske_meno and r.reakcie is not null
                                group by r.pouzivatelske_meno
                                order by count(r.reakcie) desc 
                                fetch first row only)
group by p.id, p.pouzivatelske_meno
order by pocet_reakcii desc;

-- 19.V�pis pr�spevku snajviac koment�rmi pre ka�d�ho pou��vate�a -- asi vacsina udajov kde je reakcia tak tam je aj komentar
select p.id as id_prispevku, p.pouzivatelske_meno, count(k.komentar) as pocet_komentarov
from prispevky p
join reakcieAkomentare k on p.id = k.id
where k.komentar is not null and p.pouzivatelske_meno in
                                (select r.pouzivatelske_meno
                                from reakcieAkomentare r
                                where p.pouzivatelske_meno = r.pouzivatelske_meno and r.komentar is not null
                                group by r.pouzivatelske_meno
                                order by count(r.komentar) desc 
                                fetch first row only)
group by p.id, p.pouzivatelske_meno
order by pocet_komentarov desc;

-- 20. V�pis pr�spevkov, ktor� nemaj� �iadny koment�r
select p.id as id_prispevku, count(p.id) as pocet_komentarov
from prispevky p
join reakcieAkomentare k on p.id = k.id
group by p.id 
having count(p.id) = 0;
                
-- 21. V�pis pr�spevkov, ktor� boli pridan� v piatok a cez v�kend
SELECT *
FROM prispevky
WHERE TO_CHAR(cas_pridania_prispevku,'D') IN (5,6,7);


-- 22.V�pis pr�spevkov, vktor�ch nebol ozna�en� ani jeden pou��vate�.
select p.id as id_prispevku 
from prispevky p
where not exists (select 'X'
                 from oznaceni o
                 where o.pouzivatelske_meno = p.pouzivatelske_meno);
            

-- 23. V�pis udalost� s najviac ��astn�kmi
select count(p.odpoved_ucasti) as pocet_Zucastneni_sa, p.pouzivatelske_meno as clovek_organizujuci_udalost,p.datum_udalosti 
from udalosti u
join pozvani p on(u.pouzivatelske_meno = p.pouzivatelske_meno and p.odpoved_ucasti = 'Y')
group by p.pouzivatelske_meno, p.datum_udalosti
order by count(p.odpoved_ucasti) desc;

-- 24. V�pis  najprest�nej��ch  udalost�  (pod�a  pou��vate�ov,  ktor�  sa  z��astnili  (prest� pou��vate�a sa r�ta pod�a po�tu sledovate�ov)
select count(v.sledovatel) as pocet_sledovatelov, v.pouzivatelske_meno as prestizna_osoba, u.pouzivatelske_meno as osoba_organizujuca_udalost, u.datum_udalosti
from udalosti u
join pozvani p on(u.pouzivatelske_meno = p.pouzivatelske_meno and p.odpoved_ucasti = 'Y')
join vztahy v on (p.pozvani = v.pouzivatelske_meno)
group by v.pouzivatelske_meno, u.pouzivatelske_meno, u.datum_udalosti
order by pocet_sledovatelov desc;


-- 25. V�pis udalosti, ktor�ch sa z��astnilo viac ako 5 �ud�.
select count(p.odpoved_ucasti) as pocet_Zucastneni_sa, p.pouzivatelske_meno as clovek_organizujuci_udalost,p.datum_udalosti 
from udalosti u
join pozvani p on(u.pouzivatelske_meno = p.pouzivatelske_meno and p.odpoved_ucasti = 'Y')
group by p.pouzivatelske_meno, p.datum_udalosti
HAVING count(p.odpoved_ucasti) > 5
order by count(p.odpoved_ucasti)desc;

-- 26. V�pis udalost�, ktor� sa bud� kona� bud�ci mesiac
V�pis udalost�, ktor� sa bud� kona� bud�ci mesiac.
select *
from udalosti 
where to_char(datum_udalosti,'MM') = to_char(add_months(sysdate, 1), 'MM');

-- 27. V�pis po�tu udalost� pre ka�d�ho pou��vate�a, ktor�ch sa z��astnil minul� rok.
select pouzivatelske_meno, pocet_zucastnenych_udalosti
from (
    select p.pouzivatelske_meno, count(n.pozvani) as pocet_zucastnenych_udalosti,
           row_number() over (partition by p.pouzivatelske_meno
                              order by count(n.pozvani) desc) as rn
    from pouzivatel p
    join pozvani n on p.pouzivatelske_meno = n.pozvani
    where p.pouzivatelske_meno in (
        select z.pozvani
        from pozvani z 
        where extract(year from z.datum_udalosti) = extract(year from add_months(sysdate, 0)) -- nemohol nastat takyto pripad ze minuly rok lebo 
                                                                                                -- udalosti sa vedia vytvorit len od sysdate vyssie preto som dal aktualnom roku
        
        and z.odpoved_ucasti = 'Y'
        group by z.pozvani
    )
    group by p.pouzivatelske_meno
)
where rn = 1;



