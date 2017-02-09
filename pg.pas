//fpc 3.0.0

program HelloWorld;

type encryptionKey = array [1..26] of char;
type letterFrequency = array [1..27] of integer; //27 - number of letters (not counting spaces etc.)
type candidateArray = array [1..26] of char;

const DEFAULT_BAR = 20;

var eKey : encryptionKey = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
var rankedLetter : candidateArray = ('e','t','a','o','i','n','s','h','r');
var letters : letterFrequency;
var i : byte;
var ss, encryptedSs : string;

procedure generateKey(var key : encryptionKey);
var i, newPos : byte;
var temp : char;
begin
    Randomize;
    for i:=1 to 26 do
    begin
        newPos := ((i + Random(26)+1) mod 26) + 1;
        temp := key[newPos];
        key[newPos] := key[i];
        key[i] := temp;    
    end;
end;

function encryptString(s : string; key : encryptionKey) : string;
var i, index : byte;
var c : char;
var encryptedS : string;
begin
    for i:=1 to length(s) do
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

procedure setLetterFrequency(var let : letterFrequency; s : string);
var i, index : byte;
begin
    for i:=1 to length(s) do
    begin
        index := ord(s[i]) - ord('a') + 1;
        if((index > 0) and (index < 27)) then 
        begin
            let[index] := let[index] + 1;
            let[27] := let[27] + 1;
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


begin
    generateKey(eKey);
    ss := 'Be at miss or each good play home they. It leave taste mr in it fancy. She son lose does fond bred gave lady get. Sir her company conduct expense bed any. Sister depend change off piqued one. Contented continued any happiness instantly objection.';
    for i:=1 to 26 do write(eKey[i]);
    writeln();
    writeln(ss);
    encryptedSs := encryptString(ss, eKey);
    writeln(encryptedSs);
    setLetterFrequency(letters, encryptedSs);
    writeln('Numeber of letters: ', letters[27]);
    for i:=1 to 26 do
    begin
        writeln(chr(i + ord('a') - 1), '->', eKey[i], ' ', letters[ord(eKey[i]) - ord('a') + 1]:3, ' | ', (100*letters[ord(eKey[i]) - ord('a') + 1] / letters[27]):3:0, ' %'); 
    end;
    getCandidates(letters);
end.
