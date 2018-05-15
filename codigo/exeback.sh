#!/bin/bash  
for i in tests/img_generadas/* ;
do
    if test -f $i && test ! -x $i ;
    then
        for j in {1..100};
        do
            #echo $i
            build/tp2 -i asm -o postfiltro -t 100 ondas $i
            cat Output.txt >> asmresultadosONDAS.csv
        done
    fi
done
