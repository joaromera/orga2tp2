#!/bin/bash  
for i in tests/img_generadas/* ;
do
    echo $i
    #if test -f $i && test ! -x $i ;
    #then
        #for j in {1..100};
        #do
            #echo $i
            build/tp2 -i asm -o postfiltro -t 100 monocromatizar_inf $i
            cat Output.txt >> asmresultadosMONOsisd.csv
            rm Output.txt
        #done
    #fi
done