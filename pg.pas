program pdecryptor;
{$H+}
type freq = record
        perc : real;
        letter : char;
        eLetter : char
end;

type usedWord = record
        value : string;
        pos : longint
end;

type encryptionKey = array [1..26] of char;
type letterFrequency = array [1..27] of integer; //27 - number of letters (not counting spaces etc.)
type candidateArray = array [1..9] of char;
<<<<<<< HEAD
type words = array [1..5000] of usedWord;
type wordsArray = array[1..5000] of string;
type permutation = array[1..26] of byte;
=======
type words = array [1..35815] of usedWord;
>>>>>>> 90a921968ac2cec291814d30ca6c75f965115216

const DEFAULT_BAR = 20;

var eKey : encryptionKey = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
var rankedLetter : candidateArray = ('e','t','a','o','i','n','s','h','r');
var frequencies : encryptionKey = ('a', 'i', 'e', 't', 's', 'h', 'o', 'n', 'r', 'd', 'l', 'm', 'y', 'c', 'b', 'f', 'p', 'w', 'g', 'u', 'v', 'k', 'j', 'x', 'q', 'z');
var currentPerm : permutation = (1,9,5,20,19,8,15,14,18,4,12,13,25,3,2,6,16,23,7,21,22,11,10,24,17,26);
var mPerm : permutation = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26);
var letters, bLetters, eLetters, aLetters : letterFrequency;
var i : longint;
var ss, encryptedSs : string;
var readF, writeF : text;
var mostWords : words;
var encryptedWords : wordsArray;
var numberOfWords : integer;
var candidateKey : encryptionKey;

function invertPermutation(perm : permutation) : permutation;
var newPerm : permutation;
begin
    for i := 1 to length(perm) do
    begin
        newPerm[perm[i]] := i;
    end;
    invertPermutation := newPerm;
end;

procedure generateKey(var key : encryptionKey);
var i, newPos, tempM : byte;
var temp : char;
begin
    Randomize;
    for i:=1 to 26 do
    begin
        newPos := ((i + Random(26)+1) mod 26) + 1;
        temp := key[newPos];
        tempM := mPerm[newPos];
        key[newPos] := key[i];
        mPerm[newPos] := mPerm[i];
        key[i] := temp;
        mPerm[i] := tempM;
    end;
end;

function encryptString(s : string; key : encryptionKey) : string;
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
        else encryptedS := encryptedS +s[i];
    end;
    encryptString := encryptedS;
end;

procedure setLetterFrequency(var let : letterFrequency; var bLet : letterFrequency; var eLet : letterFrequency; var aLet : letterFrequency; s : string);
var i, index, l : longint;
var c : char;
begin
    l := length(s);
    for i:=1 to l do
    begin
        c := LowerCase(s[i]);
        index := ord(c) - ord('a') + 1;
        if((index > 0) and (index < 27)) then
        begin
            let[index] := let[index] + 1;
            let[27] := let[27] + 1;
            if((i > 1) and (s[i-1] = ' ')) then
            begin
                bLet[index] := bLet[index] + 1;
                bLet[27] := bLet[27] + 1;
                if((i+1 <= l) and (s[i+1] = ' ')) then
                begin
                    aLet[index] := aLet[index] + 1;
                    aLet[27] := aLet[27] + 1;
                end;
            end
            else if((i+1 <= l) and (s[i+1] = ' ')) then
            begin
                eLet[index] := eLet[index] + 1;
                eLet[27] := eLet[27] + 1;
            end;

        end;
    end;
end;

function getCandidates(var let : letterFrequency) : candidateArray;
var i : byte;
var numberOfCandidates : byte;
var bar, upBar : real;
var output : candidateArray;
begin
    numberOfCandidates := 0;
    bar := DEFAULT_BAR;
    while(numberOfCandidates < 5) do
    begin
        if bar <> DEFAULT_BAR then upBar := bar + 0.5
        else upBar := 100;
        for i:=1 to 26 do
        begin
            if((100*let[i]/let[27] >= bar) and (100*let[i]/let[27] < upBar)) then
            begin
                writeln(numberOfCandidates + 1, ' ', chr(i + ord('a') - 1), ' ', 100*let[i]/let[27]:3:0);
                numberOfCandidates := numberOfCandidates + 1;
                output[numberOfCandidates] := chr(i + ord('a') - 1);
            end;
        end;
        bar := bar - 0.5;
    end;
    getCandidates := output;
end;

function getSub(c : char; key : encryptionKey) : char;
var i : byte;
begin
        i := 1;
        while key[i] <> c do i := i+1;
        getSub := chr(i + ord('a') - 1);
end;

function permuteKey(ar : encryptionKey; perm : permutation) : encryptionKey;
var i, j : byte;
var output : encryptionKey;
begin
    for i := 1 to 26 do output[perm[i]] := ar[i];
    permuteKey := output;
end;

function permutePerm(ar : permutation; perm : permutation) : permutation;
var i, j : byte;
var output : permutation;
begin
    for i := 1 to 26 do output[perm[i]] := ar[i];
    permutePerm := output;
end;

procedure sumUpFrequencies(var let, bLet, eLet, aLet : letterFrequency; var eKey : encryptionKey);
var i, j, min : byte;
var tempA : array [1..26] of freq;
var key : encryptionKey = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
var temp : real;
var tempF : freq;
begin
    for i:=1 to 26 do
    begin
        temp := (100*let[i] / let[27]);
        temp := temp + sqrt(100*bLet[i] / bLet[27]);
        temp := temp + sqrt((100*eLet[i] / eLet[27])*0.25);
        if(aLet[27] = 0) then aLet[27] := 1;
        temp := temp + (100*aLet[i] / aLet[27]);
        tempA[i].perc := temp;
        tempA[i].letter := chr(ord('a') + i - 1);
        tempA[i].eLetter := getSub(tempA[i].letter, eKey);
        //writeln(chr(ord('a') + i -1), ' ', temp:5:2, ' %');
    end;
    for i := 0 to 25 do
    begin
       min := i+1;
       for j:=(1+i) to 26 do if(tempA[j].perc > tempA[min].perc) then min := j;
       tempF := tempA[i+1];
       tempA[i+1] := tempA[min];
       tempA[min] := tempF;
    end;
    for i := 1 to 26 do
    begin
         //defaultPerm[i] := ord(tempA[i].letter) - ord('a') + 1;
         writeln('#', i, ' ', tempA[i].letter, '(', tempA[i].eLetter ,') ', tempA[i].perc:5:2, ' %');
         candidateKey[i] := tempA[i].letter;
         currentPerm[ord(tempA[i].letter) - ord('a') + 1] := ord(frequencies[i]) - ord('a') + 1;
    end;
    candidateKey := permuteKey(candidateKey, currentPerm);
    {for i := 1 to 26 do
    begin
         write(defaultPerm[i], ' ');
    end;
    writeln();
    for i := 1 to 26 do
    begin
         write(candidateKey[i]);
    end;}
end;

procedure saveWords(s : string);
var f : text;
var temp : string;
var c : char;
var i : longint;
begin
        assign(f, 'slova.txt');
        rewrite(f);
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
                            writeln(f, temp);
                        end;
                        temp := '';
                end;
        end;
        close(f);
end;

procedure loadMostWords();
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
            mostWords[i].value := temp;
            mostWords[i].pos := i;
            i := i + 1;
        end;
        close(f);
end;

{s1>s2 <=> lexComp(s1,s2)}
function lexComp(s1, s2 : string) : boolean;
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

procedure sortMostWords(var ar : words; start, konec : longint); {quicksort lexikograficky}
var pivot, temp : usedWord;
var s, e : longint; {start end}
begin
    s := start;
    e := konec;
    pivot := ar[(start + konec) div 2];
    repeat
        while lexComp(pivot.value, ar[s].value) do s := s + 1;
        while lexComp(ar[e].value, pivot.value) do e := e - 1;
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

function isInMostWords(s : string) : boolean;
var i, j, k : longint;
begin
    i := 1;
    j := length(mostWords);
    repeat
          k := (i+j) div 2;
          if(lexComp(s, mostWords[k].value)) then i := k+1
          else j := k-1;
    until (mostWords[k].value = s) or (i > j);
    if(mostWords[k].value = s) then isInMostWords := true
    else isInMostWords := false;
end;

function getNumberOfGoodWords(var ar : wordsArray; print : boolean) : integer;
var i, output : integer;
begin
    output := 0;
    for i := 1 to numberOfWords do
    begin
       if(isInMostWords(ar[i])) then
       begin
            output := output + 1;
            if(print) then writeln(ar[i]);
       end;
    end;
    getNumberOfGoodWords := (100*output) div numberOfWords;
end;

function newKey(thisPerm : permutation) : permutation;
var i, pos, temp : byte;
var newPerm : permutation = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26);
begin
     for i := 1 to 2 do
     begin
          pos := (Random(2) + i) mod 2 + 1;
          temp := newPerm[i];
          newPerm[i] := newPerm[pos];
          newPerm[pos] := temp;
     end;
     for i := 1 to 4 do
     begin
          pos := (Random(4) + i) mod 4 + 3;
          temp := newPerm[i + 2];
          newPerm[i + 2] := newPerm[pos];
          newPerm[pos] := temp;
     end;
     for i := 1 to 7 do
     begin
          pos := (Random(7) + i) mod 7 + 7;
          temp := newPerm[i + 6];
          newPerm[i + 6] := newPerm[pos];
          newPerm[pos] := temp;
     end;
     for i := 1 to 9 do
     begin
          pos := (Random(9) + i) mod 9 + 14;
          temp := newPerm[i + 13];
          newPerm[i + 13] := newPerm[pos];
          newPerm[pos] := temp;
     end;
     for i := 1 to 4 do
     begin
        pos := (Random(4) + i) mod 4 + 23;
        temp := newPerm[i + 22];
        newPerm[i + 22] := newPerm[pos];
        newPerm[pos] := temp;
     end;
     newKey := permutePerm(thisPerm, newPerm);
end;

function decryptString(s : string; keyPerm : permutation) : string;
var i, index : longint;
var c : char;
var decryptedS : string;
begin
    decryptedS := '';
    for i := 1 to length(s) do
    begin
        c := LowerCase(s[i]);
        index := ord(c) - ord('a') + 1;
        if((index > 0) and (index < 27)) then
        begin
             decryptedS := decryptedS + chr(keyPerm[index] + ord('a') - 1);
        end
        else decryptedS := decryptedS + s[i];
    end;
    decryptString := decryptedS;
end;

procedure crack(encryptedString : string);
var fitness : byte;
var currentKey,lastKey : permutation;
var s : string;
begin

    currentKey := currentPerm;
    writeln('KEY');

    for i:=1 to 26 do write(currentKey[i], ' ');
    writeln('');
    fitness := 0;
    while fitness < 40 do
    begin
       lastKey := currentKey;
       s := decryptString(encryptedString, lastKey);
       saveWords(s);
       fitness := getNumberOfGoodWords(encryptedWords, false);
       currentKey := newKey(currentKey);
    end;
    writeln('KEY ', fitness);
    //getNumberOfGoodWords(encryptedWords, false);

    for i:=1 to 26 do write(lastKey[i], ' ');

    writeln();
    writeln(s);
end;

begin
    Randomize();
    generateKey(eKey);
    for i:=1 to 26 do write(eKey[i]);
    writeln();

    assign(readF, 'input.txt');
    assign(writeF, 'output.txt');
    reset(readF);
    while not eof(readF) do
    begin
        readln(readF, encryptedSs);
        writeln(encryptedSs);
        ss := ss + encryptedSs + ' ';
    end;

    writeln(ss);
    writeln(length(ss));
    encryptedSs := encryptString(ss, eKey);
    writeln(encryptedSs);
    writeln();
    writeln();
    writeln(decryptString(encryptedSs, invertPermutation(mPerm)));
    saveWords(ss);

    loadMostWords();
    sortMostWords(mostWords, 1, length(mostWords));
    setLetterFrequency(letters, bLetters, eLetters, aLetters, encryptedSs);

    writeln('Number of letters: ', letters[27], ' | Number of words: ', numberOfWords, ' | known: ', getNumberOfGoodWords(encryptedWords, false));
    for i:=1 to 26 do
    begin
        writeln(chr(i + ord('a') - 1), '->', eKey[i], ' ', letters[ord(eKey[i]) - ord('a') + 1]:3, ' | ', (100*letters[ord(eKey[i]) - ord('a') + 1] / letters[27]):5:2, ' % | ',
        (100*bLetters[ord(eKey[i]) - ord('a') + 1] / bLetters[27]):5:2, ' % | ',
        (100*eLetters[ord(eKey[i]) - ord('a') + 1] / eLetters[27]):5:2, ' %');
    end;
    sumUpFrequencies(letters, bLetters, eLetters, aLetters, eKey);
    writeln();
    for i:=1 to 26 do write(mPerm[i], ' ');
    mPerm := invertPermutation(mPerm);
    writeln();
    for i:=1 to 26 do write(mPerm[i], ' ');
    writeln();
    crack(encryptedSs);
   // getCandidates(letters);
end.
