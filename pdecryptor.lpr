program pdecryptor;
{$H+} //pro moznost pouziti neomezene dlouhych stringu

type freq = record  //record pro ulozeni pravdepodobnosti pismena
        perc : real;
        letter : char;
        eLetter : char
end;

type permItem = record
        index : byte; //jaké pismeno to reprezentuje ve frequencies
        value : byte; //na jaké písmeno se písmeno z indexu přehodí

end;

type bigram = record //record pro pocet dvojici/trojici
        count : integer;
        value : string;
end;

type alphabet = array [1..26] of char;
type letterFrequency = array [1..27] of integer; //27 - number of letters (not counting spaces etc.)
type wordsArray = array[1..5000] of string;
type permutation = array[1..26] of permItem;

const DESIRED_FITNESS = 35;
const MODE = 4;  //0=pouze celkový, 1=celkovy + zac + konce, 2=starý komplex, 4=dvojice/trojice
var ONLY_DECRYPT : boolean;
var vstup : string;
var eKey : alphabet = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
//var alphabetFreq: alphabet = ('a', 'i', 't', 'e', 'h', 'n', 's', 'd', 'o', 'r', 'g', 'l', 'f', 'm', 'y', 'w', 'u', 'c', 'b', 'p', 'v', 'k', 'j', 'q', 'x', 'z'); //dle starého vzorce
//var alphabetFreq: alphabet = ('a', 'i', 't', 's', 'o', 'n', 'd', 'e', 'r', 'h', 'l', 'y', 'f', 'w', 'm', 'c', 'b', 'p', 'u', 'g', 'v', 'k', 'j', 'q', 'x', 'z'); //ceklova + zac + konce
//var alphabetFreq: alphabet = ('a', 'i', 'e', 't', 'o', 'n', 's', 'h', 'r', 'd', 'l', 'c', 'u', 'm', 'w', 'f', 'g', 'y', 'p', 'b', 'v', 'k', 'j', 'x', 'q', 'z'); //ceklova
var alphabetFreq: alphabet = ('i', 'a', 'e', 'h', 't', 'n', 'd', 'r', 'o', 'g', 's', 'u', 'l', 'c', 'm', 'w', 'f', 'y', 'p', 'b', 'v', 'k', 'j', 'x', 'q', 'z'); //dvojice/trojice
var currentPerm, enPerm : permutation;
var letters, bLetters, eLetters, aLetters : letterFrequency;
var i : byte;
var ss, encryptedSs : string;
var readF, writeF : text;
var mostWords, encryptedWords, decryptedWords : wordsArray;
var numberOfWords, topDoublesTotal, topBigramsTotal, topTrigramsTotal, currentNumberOfBigrams, currentNumberOfTrigrams : integer;
var countedFrequences : array [1..26] of freq; //pole kde je ulozeno skore pro kazde pismeno
var triedPerms : longint; //pocet vyzkousenych permutaci
var differentBigrams, differentTrigrams : array [1..5000] of bigram;
var doubles : array [1..50] of string; //pole pro dvojice stejnych pismen

function invertPermutation(perm : permutation) : permutation; //vrati inverzni permutaci
var newPerm : permutation;
begin
    for i := 1 to length(perm) do
    begin
        newPerm[perm[i].value].value := i;
    end;
    invertPermutation := newPerm;
end;

procedure generateKey(var key : alphabet); //vygeneruje klic k zasifrovani + ulozi jeho permutaci cisel
var i, newPos, tempM : byte;
var temp : char;
begin
    for i:=1 to 26 do enPerm[i].value := i;
    for i:=1 to 26 do
    begin
        newPos := ((i + Random(26)+1) mod 26) + 1;
        temp := key[newPos];
        tempM := enPerm[newPos].value;
        key[newPos] := key[i];
        enPerm[newPos].value := enPerm[i].value;
        key[i] := temp;
        enPerm[i].value := tempM;
    end;
end;

function encryptString(s : string; key : alphabet) : string; //funkce pro zasifrovani textu podle vygenerovaného klice
var i, index : longint;
var c : char;
var encryptedS : string;
begin
    for i := 1 to length(s) do
    begin
        c := LowerCase(s[i]);
        index := ord(c) - ord('a') + 1;
        if((index > 0) and (index < 27)) then
        begin
            if(c = s[i]) then encryptedS := encryptedS + key[index]
            else encryptedS := encryptedS + UpCase(key[index]);
        end
        else encryptedS := encryptedS + s[i];
    end;
    encryptString := encryptedS;
end;
{funkce zjisti jestli uz dvojice je ulozena, jestli ano tak vypise pozici v poli
jestli ne tak 0}
function alreadyInBigrams(s : string) : integer;
var i : integer;
begin
     i := -1;
     repeat
         i := i+1;
     until (differentBigrams[i].value = s) or (i = currentNumberOfBigrams);
     if(i = currentNumberOfBigrams) then alreadyInBigrams := 0
     else alreadyInBigrams := i;
end;
{funkce zjisti jestli uz trojice je ulozena, jestli ano tak vypise pozici v poli
jestli ne tak 0}
function alreadyInTrigrams(s : string) : integer;
var i : integer;
begin
     i := -1;
     repeat
         i := i+1;
     until (differentTrigrams[i].value = s) or (i = currentNumberOfTrigrams);
     if(i = currentNumberOfTrigrams) then alreadyInTrigrams := 0
     else alreadyInTrigrams := i;
end;

procedure setBigrams(var s : string); //ulozi nejcastejsi dvojice ve stringu
var i : longint;
var c1, c2 : char;
var resp : byte;
begin
    currentNumberOfBigrams := 0;
    i := 1;
    while ((i+1) <= length(s)) do
    begin
         c1 := LowerCase(s[i]);
         c2 := LowerCase(s[i+1]);
         if((c1 >= 'a') and (c1 <= 'z') and (c2 >= 'a') and (c2 <= 'z')) then
         begin
             resp := alreadyInBigrams(c1 + c2);
             if((resp = 0) and (currentNumberOfBigrams < 5000)) then
             begin
                  currentNumberOfBigrams := currentNumberOfBigrams + 1;
                  differentBigrams[currentNumberOfBigrams].value := c1 + c2;
                  differentBigrams[currentNumberOfBigrams].count := 1;
             end
             else differentBigrams[resp].count := differentBigrams[resp].count + 1;
         end;
         i := i+1;
    end;

end;

procedure setTrigrams(var s : string); //ulozi nejcastejsi trojice ve stringu
var i : longint;
var c1, c2, c3 : char;
var resp : byte;
begin
    currentNumberOfTrigrams := 0; //globalni pocet
    i := 1;
    while ((i+2) <= length(s)) do
    begin
         c1 := LowerCase(s[i]);
         c2 := LowerCase(s[i+1]);
         c3 := LowerCase(s[i+2]);
         if((c1 >= 'a') and (c1 <= 'z') and (c2 >= 'a') and (c2 <= 'z') and (c3 >= 'a') and (c3 <= 'z')) then
         begin
             resp := alreadyInTrigrams(c1 + c2 + c3);
             if((resp = 0) and (currentNumberOfTrigrams < 5000)) then
             begin
                  currentNumberOfTrigrams := currentNumberOfTrigrams + 1;
                  differentTrigrams[currentNumberOfTrigrams].value := c1 + c2 + c3;
                  differentTrigrams[currentNumberOfTrigrams].count := 1;
             end
             else differentTrigrams[resp].count := differentTrigrams[resp].count + 1;
         end;
         i := i + 1;
    end;

end;
{
pocita frekvence pismen v textu
let - celkova frekvence pismen
bLet - frekvence pismen na zacatku slov
eLet - frekvence pismen na konci slov
aLet - frekvence jednopismenych slov
s - string ze ktereho cteme
}
procedure setLetterFrequency(var let : letterFrequency; var bLet : letterFrequency; var eLet : letterFrequency; var aLet : letterFrequency; var s : string);
var i, index, delka : longint;
var min, j : integer;
var c : char;
var tempB : bigram;
begin
    delka := length(s);
    for i:=1 to delka do
    begin
        c := LowerCase(s[i]);
        index := ord(c) - ord('a') + 1;
        if((index > 0) and (index < 27)) then //je to pismeno od a-z
        begin
            let[index] := let[index] + 1;
            let[27] := let[27] + 1;
            if((i > 1) and (s[i-1] = ' ')) then
            begin
                bLet[index] := bLet[index] + 1; //pocatecni pismena slov
                bLet[27] := bLet[27] + 1;
                if((i+1 <= delka) and (s[i+1] = ' ')) then
                begin
                    aLet[index] := aLet[index] + 1; //jednopisemnova slova
                    aLet[27] := aLet[27] + 1;
                end;
            end
            else if((i+1 <= delka) and (s[i+1] = ' ')) then
            begin
                eLet[index] := eLet[index] + 1; //koncici pismena
                eLet[27] := eLet[27] + 1;
            end;

        end;
    end;

    setBigrams(s); //spocte dvojice
    setTrigrams(s); //spocte trojice

    for i := 0 to currentNumberOfBigrams-1 do //seradi dvojce podle poctu
    begin
       min := i+1;
       for j:=(1+i) to currentNumberOfBigrams do if(differentBigrams[j].count > differentBigrams[min].count) then min := j;
       tempB := differentBigrams[i+1];
       differentBigrams[i+1] := differentBigrams[min];
       differentBigrams[min] := tempB;
    end;
    //od ted jen vypis toho co se spocitalo
    topBigramsTotal := 0;
    writeln('nejcastejsi dvojice');
    for i := 1 to 20 do
    begin
        writeln(differentBigrams[i].value, ' #', differentBigrams[i].count);
        topBigramsTotal := topBigramsTotal + differentBigrams[i].count*2;
    end;
    writeln();
    writeln('nejcastejsi dvojice stejnych pismen');
    i := 1;
    j := 0;
    topDoublesTotal := 0;
    repeat //ulozi 5 nejcastejsich dvojic
          if(differentBigrams[i].value[1] = differentBigrams[i].value[2]) then
          begin
               writeln(differentBigrams[i].value, ' #', differentBigrams[i].count);
               j := j+1;
               doubles[j] := differentBigrams[i].value;
               topDoublesTotal := topDoublesTotal + differentBigrams[i].count;
          end;
          i := i +1;
    until (j = 5) or (i = currentNumberOfBigrams);

    for i := 0 to currentNumberOfTrigrams-1 do //seradi trojice podle poctu
    begin
       min := i+1;
       for j:=(1+i) to currentNumberOfTrigrams do if(differentTrigrams[j].count > differentTrigrams[min].count) then min := j;
       tempB := differentTrigrams[i+1];
       differentTrigrams[i+1] := differentTrigrams[min];
       differentTrigrams[min] := tempB;
    end;
    writeln();
    writeln('nejcastejsi trojice');
    topTrigramsTotal := 0;
    for i := 1 to 3 do
    begin
       topTrigramsTotal := topTrigramsTotal + differentTrigrams[i].count*3;
       writeln(differentTrigrams[i].value, ' #', differentTrigrams[i].count);
    end;

end;

function getSub(c : char; key : alphabet) : char; //pomocna funkce pro zjisteni jake pismeno bylo zasifrovano kterym (pro kontrolu)
var i : byte;
begin
        i := 1;
        while key[i] <> c do i := i+1;
        getSub := chr(i + ord('a') - 1);
end;
function permutePerm(ar : permutation; perm : permutation) : permutation; //funkce pro permutovani "ar" permutaci "perm"
var i : byte;
var output : permutation;
begin
    for i := 1 to 26 do
    begin
         output[perm[i].value].value := ar[i].value;
         output[i].index := i;
    end;
    permutePerm := output;
end;

procedure setNewPerm(); //permutuje vytvorene permutace, ale jen jejich jiste casti
var i, pos, temp : byte;
var perm : permutation;
var defaultPerm : permutation;
begin
     for i:= 1 to 26 do
     begin
        defaultPerm[i].value := ord(alphabetFreq[i]) - ord('a') + 1; //permutace na zaklade frekvence
        defaultPerm[i].index := i;
        perm[i].value := i; //obycejna permutace od 1 do 26;
     end;
     if(MODE = 2) then
     begin
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 1;
            temp := perm[i].value;
            perm[i].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
            pos := (Random(4) + i) mod 4 + 3;
            temp := perm[i + 2].value;
            perm[i + 2].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 7 do
       begin
            pos := (Random(7) + i) mod 7 + 7;
            temp := perm[i + 6].value;
            perm[i + 6].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 9 do
       begin
            pos := (Random(9) + i) mod 9 + 14;
            temp := perm[i + 13].value;
            perm[i + 13].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
          pos := (Random(4) + i) mod 4 + 23;
          temp := perm[i + 22].value;
          perm[i + 22].value := perm[pos].value;
          perm[pos].value := temp;
       end;
     end
     else if (MODE = 4) then
     begin
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 1;
            temp := perm[i].value;
            perm[i].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
            pos := (Random(4) + i) mod 4 + 3;
            temp := perm[i + 2].value;
            perm[i + 2].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
            pos := (Random(4) + i) mod 4 + 7;
            temp := perm[i + 6].value;
            perm[i + 6].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 7 do
       begin
            pos := (Random(7) + i) mod 7 + 11;
            temp := perm[i + 10].value;
            perm[i + 10].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 3 do
       begin
          pos := (Random(3) + i) mod 3 + 18;
          temp := perm[i + 17].value;
          perm[i + 17].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
          pos := (Random(3) + i) mod 3 + 21;
          temp := perm[i + 20].value;
          perm[i + 20].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
          pos := (Random(4) + i) mod 4 + 23;
          temp := perm[i + 22].value;
          perm[i + 22].value := perm[pos].value;
          perm[pos].value := temp;
       end;
     end
     else if (MODE = 0) then
     begin
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 1;
            temp := perm[i].value;
            perm[i].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 3 do
       begin
            pos := (Random(3) + i) mod 3 + 3;
            temp := perm[i + 2].value;
            perm[i + 2].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
            pos := (Random(4) + i) mod 4 + 6;
            temp := perm[i + 5].value;
            perm[i + 5].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 10;
            temp := perm[i + 9].value;
            perm[i + 9].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 12;
            temp := perm[i + 11].value;
            perm[i + 11].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 7 do
       begin
          pos := (Random(7) + i) mod 7 + 14;
          temp := perm[i + 13].value;
          perm[i + 13].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
          pos := (Random(2) + i) mod 2 + 21;
          temp := perm[i + 20].value;
          perm[i + 20].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
          pos := (Random(4) + i) mod 4 + 23;
          temp := perm[i + 22].value;
          perm[i + 22].value := perm[pos].value;
          perm[pos].value := temp;
       end;
     end
     else   //MODE = 1
     begin
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 1;
            temp := perm[i].value;
            perm[i].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
            pos := (Random(2) + i) mod 2 + 3;
            temp := perm[i + 2].value;
            perm[i + 2].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 6 do
       begin
            pos := (Random(6) + i) mod 6 + 5;
            temp := perm[i + 4].value;
            perm[i + 4].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
            pos := (Random(4) + i) mod 4 + 11;
            temp := perm[i + 10].value;
            perm[i + 10].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 3 do
       begin
            pos := (Random(3) + i) mod 3 + 15;
            temp := perm[i + 14].value;
            perm[i + 14].value := perm[pos].value;
            perm[pos].value := temp;
       end;
       for i := 1 to 3 do
       begin
          pos := (Random(3) + i) mod 3 + 18;
          temp := perm[i + 17].value;
          perm[i + 17].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 2 do
       begin
          pos := (Random(2) + i) mod 2 + 21;
          temp := perm[i + 20].value;
          perm[i + 20].value := perm[pos].value;
          perm[pos].value := temp;
       end;
       for i := 1 to 4 do
       begin
          pos := (Random(4) + i) mod 4 + 23;
          temp := perm[i + 22].value;
          perm[i + 22].value := perm[pos].value;
          perm[pos].value := temp;
       end;
     end;


     defaultPerm := permutePerm(defaultPerm, perm); //vytvori novou permutace podle frekvence tim ze pouzije permutaci perm, ktera jen prehazi 1-2 2-6 atd
     for i := 1 to 26 do //v podstate roztridi permutaci od a-z jelikoz do ted byla podle frekvence
     begin
         currentPerm[ord(countedFrequences[i].letter) - ord('a') + 1].value := defaultPerm[i].value;
         currentPerm[ord(countedFrequences[i].letter) - ord('a') + 1].index := i;
     end;
     triedPerms := triedPerms + 1;
end;
{
metoda udeli kazdemu pismenu skore na zaklade pravdepodobnosti a pote to porovna
s polem frequencies kde jsou dana pismena podle pravdepodobnosti
}
procedure sumUpFrequencies(var let, bLet, eLet, aLet : letterFrequency; var eKey : alphabet);
var i, j, min : byte;
var temp : real;
var tempF : freq;
var letterCount : integer;

begin
    for i:=1 to 26 do
    begin
        countedFrequences[i].perc := 0;
        temp := (100*let[i] / let[27]); //procento i-teho pismene v textu
        if(MODE <> 0) then temp := temp + 100*bLet[i] / bLet[27]; //procento i-teho pismene na zacatku slov v textu
        if(MODE <> 0) then temp := temp + (100*eLet[i] / eLet[27]); //procento i-teho pismene na konci slov v textu
        if(aLet[27] = 0) then aLet[27] := 1; //jestli nebylo nalezeno zadne jednopismenove slovo prirad ze se nalezlo 1 (kvuli deleni nulou)
        temp := temp + (100*aLet[i] / aLet[27])*10; //zvysi procenta pismenum ktere se nachazeji samotna v textu (a,i) 10x, jelikoz tato 2 jsou jista
        if(MODE <> 4) then countedFrequences[i].perc := temp; //zaznamena pro i-te pismeno kolik ma "skore" a
        countedFrequences[i].letter := chr(ord('a') + i - 1); //priradi mu char
        countedFrequences[i].eLetter := getSub(countedFrequences[i].letter, eKey); //a pismeno ktere sifruje

        letterCount := 0;
        for j := 1 to 3 do //pocita kolikrat se i-te pismeno nachazi v trojicich (prvni 3 trojce)
        begin
             if((ord(differentTrigrams[j].value[1])-ord('a')+1) = i) then letterCount := letterCount + differentTrigrams[j].count;
             if((ord(differentTrigrams[j].value[2])-ord('a')+1) = i) then letterCount := letterCount + differentTrigrams[j].count;
             if((ord(differentTrigrams[j].value[3])-ord('a')+1) = i) then letterCount := letterCount + differentTrigrams[j].count;
        end;
        if(MODE = 2) then countedFrequences[i].perc := countedFrequences[i].perc + (100*letterCount/topTrigramsTotal)*3; //priradi dalsi skore na zaklade vyskytu
        if(MODE = 4) then countedFrequences[i].perc := (100*letterCount/topTrigramsTotal)*10;
        letterCount := 0;
        for j := 1 to 20 do //to same pro dvojice akorat jich pocitame 20
        begin
             if((ord(differentBigrams[j].value[1])-ord('a')+1) = i) then letterCount := letterCount + differentBigrams[j].count;
             if((ord(differentBigrams[j].value[2])-ord('a')+1) = i) then letterCount := letterCount + differentBigrams[j].count;
        end;
        if(MODE = 2) then countedFrequences[i].perc := countedFrequences[i].perc + (100*letterCount/topBigramsTotal)*2; //to same pro dvojice
        if(MODE = 4) then countedFrequences[i].perc := countedFrequences[i].perc +(100*letterCount/topBigramsTotal)*10;

        if((MODE = 4) and (countedFrequences[i].perc = 0)) then
        begin
             countedFrequences[i].perc := countedFrequences[i].perc + (100*let[i] / let[27]); //nejdrive priradi dle dvojic/trojic pote zbytek (mensi nasobek)
             //writeln(countedFrequences[i].letter, ' ', (100*let[i] / let[27]):4:3);
        end;

        if(aLet[27] = 0) then aLet[27] := 1; //jestli nebylo nalezeno zadne jednopismenove slovo prirad ze se nalezlo 1 (kvuli deleni nulou)
        countedFrequences[i].perc := countedFrequences[i].perc + (100*aLet[i] / aLet[27])*10; //zvysi procenta pismenum ktere se nachazeji samotna v textu (a,i) 10x, jelikoz tato 2 jsou jista
    end;



    for i := 0 to 25 do //roztridi pole countedFrequences podle skore (perc) sestupne
    begin
       min := i+1;
       for j:=(1+i) to 26 do if(countedFrequences[j].perc > countedFrequences[min].perc) then min := j;
       tempF := countedFrequences[i+1];
       countedFrequences[i+1] := countedFrequences[min];
       countedFrequences[min] := tempF;
    end;
    for i := 1 to 26 do  //vypis odhadu
    begin
         writeln('#', i:2, ' ', countedFrequences[i].letter, ' = odhad(', alphabetFreq[i], ') opravdu(', countedFrequences[i].eLetter ,') ', countedFrequences[i].perc:5:2);
         currentPerm[ord(countedFrequences[i].letter) - ord('a') + 1].value := ord(alphabetFreq[i]) - ord('a') + 1; //vytvori 1. potencialni desifrovaci permutaci
         currentPerm[ord(countedFrequences[i].letter) - ord('a') + 1].index := i; //pismeno na indexu nahradi pismeno value (1-26)
    end;
end;

procedure saveWords(s : string); //ulozi poprve zasifrovana slova do encryptedWords
var temp : string;
var c : char;
var i : longint;
begin
        temp := '';
        numberOfWords := 0;
        for i:=1 to length(s) do
        begin
                c := LowerCase(s[i]);
                if((c >= 'a') and (c <= 'z')) then temp := temp + c
                else
                begin
                        if(length(temp) > 0) then
                        begin
                            numberOfWords := numberOfWords + 1;
                            encryptedWords[numberOfWords] := temp;
                        end;
                        temp := '';
                end;
        end;
end;

procedure loadMostWords(); //ulozi 5000 nejpouzivanejsi anglickych slov do pameti (pole mostWords)
var f : text;
var i : longint;
var temp : string;
begin
        assign(f, '5k.txt');
        reset(f);
        i := 1;
        while not SeekEof(f) do
        begin
            readln(f, temp);
            mostWords[i] := temp;
            i := i + 1;
        end;
        close(f);
end;

{s1>s2 <=> lexComp(s1,s2)}
function lexComp(s1, s2 : string) : boolean; //lexikograficke porovnani stringu - pouzito k roztrideni mostWords
var i : byte;
begin
        if(length(s1) > length(s2)) then lexComp := true
        else
        begin
                if(length(s1) < length(s2)) then lexComp := false
                else
                begin
                        for i:=1 to length(s1) do
                        begin
                                if(s1[i] > s2[i]) then
                                begin
                                        lexComp := true;
                                        break;
                                end
                                else if (s1[i] < s2[i]) then
                                begin
                                     lexComp := false;
                                     break;
                                end;
                                lexComp := false;
                        end;

                end;
        end;
end;

procedure sortMostWords(var ar : wordsArray; start, konec : longint); //quicksort lexikograficky nejpouzivanejsich pismen, aby se v nich dalo binarne vyhledavat
var pivot, temp : string;
var s, e : longint; {start end}
begin
    s := start;
    e := konec;
    pivot := ar[(start + konec) div 2];
    repeat
        while lexComp(pivot, ar[s]) do s := s + 1;
        while lexComp(ar[e], pivot) do e := e - 1;
        if(s < e) then
        begin
            temp := ar[s];
            ar[s] := ar[e];
            ar[e] := temp;
            s := s + 1;
            e := e - 1;
        end
        else if (s = e) then
        begin
            s := s + 1;
            e := e - 1;
        end;
    until s > e;
    if(start < e) then sortMostWords(ar, start, e);
    if(konec > s) then sortMostWords(ar, s, konec);
end;

function isInMostWords(s : string) : boolean;  //funkce ktera vrati boolean podle toho jestli se dane slovo (string) nachazi v nejcastejsich. binarni vyhledavani
var i, j, k : longint;
begin
    i := 1;
    j := length(mostWords);
    repeat
          k := (i+j) div 2;
          if(lexComp(s, mostWords[k])) then i := k+1
          else j := k-1;
    until (mostWords[k] = s) or (i > j);
    if(mostWords[k] = s) then isInMostWords := true
    else isInMostWords := false;
end;

function getNumberOfGoodWords(var ar : wordsArray) : integer;  //vrati procento slov z pole "ar" co se nachazeji v mostWords (nejcastejsich 5000)
var i, output : integer;
begin
    output := 0;
    for i := 1 to numberOfWords do
    begin
       if(isInMostWords(ar[i])) then output := output + 1;
    end;
    getNumberOfGoodWords := (100*output) div numberOfWords;
end;

function decryptString(var s : string; var perm : permutation) : string;  //desifruje string pomoci permutace (substituce)
var i, index : longint;
var c : char;
var decryptedS : string;
begin
    decryptedS := '';
    for i := 1 to length(s) do
    begin
        c := s[i];
        index := ord(c) - ord('a') + 1;
        if((index > 0) and (index < 27)) then
        begin
             decryptedS := decryptedS + chr(perm[index].value + ord('a') - 1);
        end
        else decryptedS := decryptedS + s[i];
    end;
    decryptString := decryptedS;
end;
{
prepise pole encryptedWords novymi potencialne desifrovanymi slovy
implementovano protoze je rychlejsi
desifrovat mnoho malych stringu oproti jednomu velkemu jednou
}
procedure setDecryptedWords(var perm : permutation);
var i : longint;
begin
        for i:=1 to numberOfWords do
        begin
           decryptedWords[i] := decryptString(encryptedWords[i], perm);
        end;
end;

procedure crack();  //hlavni metoda zkousi klice dokud nenalezne ten, ktery desifruje text a aspon 20(DESIRED_FITNESS)% slov je znamych
var fitness : byte;
var lastPerm : permutation;
begin
    triedPerms := 0;
    write('prvni permutace k desifrovani: ':41);
    for i:=1 to 26 do write(currentPerm[i].value:2, ' ');
    writeln();
    fitness := 0;
    while fitness < DESIRED_FITNESS do
    begin
       lastPerm := currentPerm; //uloz si starou permutaci (kvuli potencialnimu vypisu dobre permutace)
       //s := decryptString(enS, lastPerm);
       //saveWords(s);              // zhruba 5x pomalejší
       setDecryptedWords(lastPerm);
       fitness := getNumberOfGoodWords(decryptedWords);
       setNewPerm(); //do currentPerm uloz novou permutaci
    end;
    writeln('mozny klic s presnosti: ', fitness);

    for i:=1 to 26 do write(lastPerm[i].value:3);
    writeln();
    for i:=1 to 26 do write(enPerm[i].value:3);

    writeln();
    rewrite(writeF);
    for i:=1 to numberOfWords do
    begin
           writeln(writeF, decryptedWords[i], ' ', encryptedWords[i]);
    end;
end;

begin
    writeln('Chcete pouze desifrovat?');
    readln(vstup);
    if(vstup = 'ano') then ONLY_DECRYPT := true
    else ONLY_DECRYPT := false;
    Randomize();
    generateKey(eKey);
    write('klic: ');
    for i:=1 to 26 do write(eKey[i]);
    writeln();

    assign(readF, 'vstup.txt');
    assign(writeF, 'vystup.txt');
    reset(readF);
    while not eof(readF) do
    begin
        readln(readF, encryptedSs);
        ss := ss + encryptedSs + ' ';
    end;
    close(readF);
    //writeln(ss);
    writeln('delka textu: ', length(ss));
    if(not ONLY_DECRYPT) then encryptedSs := encryptString(ss, eKey)
    else encryptedSs := ss;
    writeln(length(encryptedSs));
    if(not ONLY_DECRYPT) then
    begin
         rewrite(writeF);
         writeln(writeF, encryptedSs);
    end;
    //writeln(encryptedSs);
    writeln();
    //writeln(decryptString(encryptedSs, invertPermutation(mPerm)));
    saveWords(encryptedSs);

    loadMostWords();
    sortMostWords(mostWords, 1, length(mostWords));
    setLetterFrequency(letters, bLetters, eLetters, aLetters, encryptedSs);
    writeln();
    writeln('Pocet pismen: ', letters[27], ' | Pocet slov: ', numberOfWords);
    writeln('"Tabulka" sifry');
    for i:=1 to 26 do
    begin
        writeln(chr(i + ord('a') - 1), '->', eKey[i], ' ', letters[ord(eKey[i]) - ord('a') + 1]:3, ' | ', (100*letters[ord(eKey[i]) - ord('a') + 1] / letters[27]):5:2, ' % | ',
        (100*bLetters[ord(eKey[i]) - ord('a') + 1] / bLetters[27]):5:2, ' % | ',
        (100*eLetters[ord(eKey[i]) - ord('a') + 1] / eLetters[27]):5:2, ' %');
    end;
    writeln();
    writeln('Odhad pismen na zaklade frekvence');
    sumUpFrequencies(letters, bLetters, eLetters, aLetters, eKey);
    writeln();
    write('permutace (klic z zasifrovani): ':41);
    for i:=1 to 26 do write(enPerm[i].value:2, ' ');
    enPerm := invertPermutation(enPerm);
    writeln();
    write('inverzni permutace (klic k desifrovani): ':41);
    for i:=1 to 26 do write(enPerm[i].value:2, ' ');
    writeln();
    crack();
end.
