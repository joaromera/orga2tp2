#!/bin/bash  
for i in tests/img_generadas/* ;
do
    if test -f $i && test ! -x $i ;
    then
        for j in {1..100};
        do
            #echo $i
            build/tp2 -i c -o postfiltro -t 100 ondas $i
            cat Output.txt >> resultados.csv
        done
    fi
done
