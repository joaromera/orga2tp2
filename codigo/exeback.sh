#!/bin/bash  
<<<<<<< Updated upstream
for i in tests/img_generadas/* ;
do
    echo $i
    #if test -f $i && test ! -x $i ;
    #then
        #for j in {1..100};
        #do
            #echo $i
            build/tp2 -i asm -o postfiltro -t 100 monocromatizar_inf $i
            cat Output.txt >> macroMONO65536.csv
            rm Output.txt
        #done
    #fi
done
=======
# myvar=1
for i in tests/img_generadas/* ;
do
    if test -f $i && test ! -x $i ;
    then

        build/tp2 -i c -o postfiltro monocromatizar_inf $i
        cat Output.txt >> resultados.csv
    fi
done
>>>>>>> Stashed changes
