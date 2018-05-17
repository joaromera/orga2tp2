#!/bin/bash  
for i in tests/img_generadas/* ;
do
    echo $i
    #if test -f $i && test ! -x $i ;
    #then
        #for j in {1..100};
        #do
            #echo $i
            build/tp2 -i c -o postfiltro -t 100 temperature $i
            cat Output.txt >> cresultadosTEMP.csv
            rm Output.txt
        #done
    #fi
done