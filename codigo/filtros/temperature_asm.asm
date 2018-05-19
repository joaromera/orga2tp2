global temperature_asm

section .data
    maskshuf: times 16 db 11111111b
    div3: times 4 dd 3
    mask128: times 16 db 128
    mask1: db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3

    mask32: times 4 dd 32       
    mask96: times 4 dd 96
    mask160: times 4 dd 160
    mask224: times 4 dd 224
section .text

;void temperature_asm(unsigned char *src,
;              unsigned char *dst,
;              int width,
;              int height,
;              int src_row_size,
;              int dst_row_size);

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

temperature_asm:
    push rbp
	mov rbp, rsp
    pxor xmm8, xmm8
    pxor xmm9, xmm9
	movdqu xmm8,  [div3]
    movdqu xmm9,  [maskshuf]
    movdqu xmm10, [mask1]
    movdqu xmm11, [mask128]
    movdqu xmm12, [mask32]
    movdqu xmm13, [mask96]
    movdqu xmm14, [mask160]
    movdqu xmm15, [mask224]
    push r9
    mov r9d, 255

    mov eax, edx ; eax = width
	mul ecx		 ;			;[EDX:EAX]
	mov ecx, edx ; 
	shl rcx, 32
	add ecx, eax ;rcx=width*height = [EDX:EAX]
	shr rcx, 2    ; shr= width*height/4 proceso de a 4 pixeles

    cvtdq2ps xmm8, xmm8; xmm8=|3.0|3.0|3.0|3.0|
    
    .ciclo:

        cmp rcx, 0
        je .fin
            movdqu xmm12, [mask32]  ; xmm12=|32|32|32|32|
            movdqu xmm13, [mask96]  ; xmm13=|96|96|96|96|
            movdqu xmm14, [mask160] ; xmm14=|160|160|160|160|
            movdqu xmm15, [mask224] ; xmm15=|224|224|224|224|
            movdqu xmm9,  [maskshuf]; xmm9=|0xFFFF|0xFFFF|0xFFFF|0xFFFF|
            movdqu xmm0, [rdi]      ; xmm0 = |a3 b3 g3 r3|a2 b2 g2 r2|a1 b1 g1 r1|a0 b0 g0 r0| Pixeles originales
            movdqu xmm1, xmm0       ; xmm1= xmm0
            movdqu xmm2, xmm0       ; xmm2= xmm0

            pxor xmm7, xmm7         ; Masacara para desempaquetar de byte a word
            punpcklbw xmm2, xmm7    ; xmm2 = |a1 b1 g1 r1|a0 b0 g0 r0| parte baja
            punpckhbw xmm1, xmm7    ; xmm1 = |a3 b3 g3 r3|a2 b2 g2 r2| parte alta
                                    ; Shifteo a izquierda para olvidarme del alfa
            psllq xmm1, 16          ; xmm1=|b3 g3 r3 0|b2 g2 r2 0|
            psllq xmm2, 16          ; xmm2=|b1 g1 r1 0|b0 g0 r0 0|
            psrlq xmm1, 16          ; xmm1=|0 b3 g3 r3|0 b2 g2 r2|
            psrlq xmm2, 16          ; xmm2=|0 b1 g1 r1|0 b0 g0 r0|
                                    ; Sumas horizontal
            phaddw xmm2, xmm2       ; xmm2=|0+b1 g1+r1 0+b0 g0+r0|0+b1 g1+r1 0+b0 g0+r0|
            phaddw xmm1, xmm1       ; xmm1=|0+b3 g3+r3 0+b2 g2+r2| 0+b3 g3+r3 0+b2 g2+r2|

            phaddw xmm2, xmm2       ; xmm2 =|b1+g1+r1 b0+g0+r0 b1+g1+r1 b0+g0+r0|b1+g1+r1 b0+g0+r0 b1+g1+r1 b0+g0+r0|
            phaddw xmm1, xmm1       ; xmm1 =|b3+g3+r3 b2+g2+r2 b3+g3+r3 b2+g2+r2|b3+g3+r3 b2+g2+r2 b3+g3+r3 b2+g2+r2|
                                    ; xmm2 =|s1 s0 s1 s0|s1 s0 s1 s0|
                                    ; xmm1 =|s3 s2 s3 s2|s3 s2 s3 s2|
                                    ;shuffle parte baja
                                    ; imm8 = 1 1 0 0
            pshufhw xmm2, xmm2, 01010000b; xmm2=|s1 s0 s1 s0|s1 s1 s0 s0| 
            pshufhw xmm1, xmm1, 01010000b; xmm1=|s3 s2 s3 s2|s3 s3 s2 s2|
                                    ;shuffle parte alta
            pshuflw xmm2, xmm2, 01010000b; xmm2=|s1 s1 s0 s0|s1 s1 s0 s0|
            pshuflw xmm1, xmm1, 01010000b; xmm1=|s3 s3 s2 s2|s3 s3 s2 s2|
                                         ; observar q lois s's mide words, shifteo a derecha c/paquete dobleWord
            psrld xmm2, 16;              ; xmm2=|0 s1|0 s0|0 s1|0 s0| 
            psrld xmm1, 16               ; xmm1=|0 s3|0 s2|0 s3|0 s2|
                                    ; Convierto los valores de xmm1 a float
            cvtdq2ps xmm1, xmm1         ; xmm1=|s3|s2|s3|s2|
            cvtdq2ps xmm2, xmm2         ; xmm2=|s1|s0|s1|s0|
                                        ; mesclamos los registros xmm1 y xmm2 usando el blendps
            blendps xmm1, xmm2, 0011b   ; xmm1 =|s3|s2|s1|s0|
            
            ; <t, t, t, t>          t < 32   <0, 0, 0, 4t + 128>
                                    ; Divido todo por 3
            divps xmm1, xmm8        ; xmm1 =|s3/3.0|s2/3.0|s1/3.0|s0/3.0| 
                                    ; convierto de Float a dobleWord entero
            cvtps2dq xmm1, xmm1     ; xmm1 =|t3|t2|t1|t0|
                                    ; desempaqueto de dobleWord a Word sin signo y con saturacion
            packusdw xmm1, xmm1     ; xmm1 =|t3|t2|t1|t0|t3|t2|t1|t0|
                                    ; desempaqueto Word sin signo y  byte con saturacion
            packuswb xmm1, xmm1     ; xmm1 =|t3|t2|t1|t0|t3|t2|t1|t0|t3|t2|t1|t0|t3|t2|t1|t0| 
                                    ; xmm10=|3|3|3|3|2|2|2|2|1|1|1|1|0|0|0|0|
            pshufb xmm1, xmm10      ; xmm1 = |t3|t3|t3|t3|t2|t2|t2|t2|t1|t1|t1|t1|t0|t0|t0|t0|
                                    ; xmm1 = |t4|t3|t2|t1|
            ; <t, t, t, t>          t < 32   <0, 0, 0, 4t + 128>
            movdqu xmm4, xmm1   ; xmm4=|t3|t3|t3|t3|t2|t2|t2|t2|t1|t1|t1|t1|t0|t0|t0|t0|
                                ; multiplico por 2
            paddb  xmm4, xmm1   ; xmm4=|2.t3 2.t3 2.t3 2.t3|2.t2 2.t2 2.t2 2.t2|2.t1 2.t1 2.t1 2.t1|2.t0 2.t0 2.t0 2.t0|   
            paddb  xmm4, xmm1   ; multiplico por 3
            paddb  xmm4, xmm1   ; xmm4=|4.t3 4.t3 4.t3 4.t3|4.t2 4.t2 4.t2 4.t2|4.t1 4.t1 4.t1 4.t1|4.t0 4.t0 4.t0 4.t0|
                                ; sumo 128 a cada byte de xmm4
            paddb  xmm4, xmm11  ; xmm4=|4.t3+128 4.t3+128 4.t3+128 4.t3+128|4.t2+128 4.t2+128 4.t2+128 4.t2+128|4.t1+128 4.t1+128 4.t1+128 4.t1+128|4.t0+128 4.t0+128 4.t0+128 4.t0+128|
            psrld  xmm4, 24     ; xmm4=|0 0 0 4.t3+128|0 0 0 4.t2+128|0 0 0 4.t1+128|0 0 0 4.t0+128|

            

                                ;32 <= t < 96    <0, 0, (t - 32) * 4, 255>
            movdqu xmm5, xmm1   ;xmm5=|t3|t3|t3|t3|t2|t2|t2|t2|t1|t1|t1|t1|t0|t0|t0|t0|
            paddb xmm5, xmm1
            paddb xmm5, xmm1    
            paddb xmm5, xmm1    ;xmm5=|4.t3 4.t3 4.t3 4.t3|4.t2 4.t2 4.t2 4.t2|4.t1 4.t1 4.t1 4.t1|4.t0 4.t0 4.t0 4.t0|
                                ;
            psubb xmm5, xmm11   ;xmm5=|4.t3-128 4.t3-128 4.t3-128 4.t3-128|4.t2-128 4.t2-128 4.t2-128 4.t2-128|4.t1-128 4.t1-128 4.t1-128 4.t1-128|4.t0-128 4.t0-128 4.t0-128 4.t0-128|
                                ;;xmm5=|4.(t3-32) 4.(t3-32) 4.(t3-32) 4.(t3-32)|....|4.t0-32 4.4.t0-32 4.4.t0-32 4.4.t0-32|                           
                                ; r9b=255
            pinsrb xmm5, r9b, 12; xmm5=|4.(t3-32) 4.(t3-32) 4.(t3-32) 4.(t3-32)+255|...|4.t0-32 4.4.t0-32 4.4.t0-32 4.4.t0-32|
            pinsrb xmm5, r9b, 8                 ; < a, r , g, b>
            pinsrb xmm5, r9b, 4
            pinsrb xmm5, r9b, 0 ;xmm5=|4.(t3-32) 4.(t3-32) 4.(t3-32) 255|...|4.(t0-32) 4.(t0-32) 4.(t0-32) 255|                    

            pslld xmm5, 16      ;xmm5=|4.(t3-32) 255 0 0|...|4.(t0-32) 255 0 0|
            psrld xmm5, 16      ;xmm5=|0 0 4.(t3-32) 255|...|0 0 4.(t0-32) 255|                    


            ;96 <= t < 160
            movdqu xmm3, xmm7;xmm3=|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0| 
            movdqu xmm2, xmm7;xmm2=|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|   
            paddb  xmm2, xmm1;xmm2=|t3 t3 t3 t3| t2 t2 t2 t2|t1 t1 t1 t1|t0 t0 t0 t0|
            paddb  xmm2, xmm1;xmm2=|2.t3 2.t3 2.t3 2.t3| 2.t2 2.t2 2.t2 2.t2|2.t1 2.t1 2.t1 2.t1|2.t0 2.t0 2.t0 2.t0|
            paddb  xmm2, xmm1;
            paddb  xmm2, xmm1;xmm2=|4.t3 4.t3 4.t3 4.t3|...|4.t0 4.t0 4.t0 4.t0|
            psubb xmm2, xmm11;xmm2=|4.t3-128 4.t3-128 4.t3-128 4.t3-128|...|4.t0-128 4.t0-128 4.t0-128 4.t0-128|


            pslld  xmm2, 24 ;xmm2=|4.t3-128 0 0 0|...|4.t0-128 0 0 0|        <0, 0, 0, (t - 96) * 4> 
            psrld  xmm2, 8  ;xmm2=|0 4.t3-128 0 0|...|0 4.t0-128 0 0|
            pinsrb xmm3, r9b, 12;
            pinsrb xmm3, r9b, 8 ;               ;<r, g, b, a>
            pinsrb xmm3, r9b, 4 ;
            pinsrb xmm3, r9b, 0 ;xmm3=|0 0 0 255|...|0 0 0 255|
            psubb  xmm3, xmm1; xmm3=|-t3 -t3 -t3 255-t3|...|-t0 -t0 -t0 255-t0|
            psubb  xmm3, xmm1;
            psubb  xmm3, xmm1;
            psubb  xmm3, xmm1;xmm3=|-4.t3 -4.t3 -4.t3 255-4.t3|...|-4.t0 -4.t0 -4.t0 255-4.t0|
            paddb  xmm3, xmm11;xmm3=|-4.t3+128 -4.t3+128 -4.t3+128 255-4.t3+128|...|-4.t0+128 -4.t0+128 -4.t0+128 255-4.t0+128|


            pslld  xmm3, 24;xmm3=|255-4.t3+128 0 0 0|...|255-4.t0+128 0 0 0|
            psrld  xmm3, 24;xmm3=|0 0 0 255-4.t3+128|...|0 0 0 255-4.t0+128|

            pinsrb xmm3, r9b, 13
            pinsrb xmm3, r9b, 9
            pinsrb xmm3, r9b, 5
            pinsrb xmm3, r9b, 1; xmm3=|0 0 255 255-4.(t3+32)|...|0 0 255 255-4.(t0+32)| 
            ;<0,0,255,255 - (t - 96) * 4>

            paddb xmm3, xmm2; xmm3=|0 4.(t3-32) 255 255-4.(t3+32)|...|0 4.(t0-32) 255 255-4.(t0+32)|




            ;160 <= t < 224  <0, 255, 255 + 640 - 4t, 0>
            movdqu xmm6, xmm7 ;xmm6=|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0| 
            pinsrb xmm6, r9b, 13; 
            pinsrb xmm6, r9b, 9
            pinsrb xmm6, r9b, 5
            pinsrb xmm6, r9b, 1 ;xmm6=|0 0 255 0|0 0 255 0|0 0 255 0|0 0 255 0|    <0, 0, 255, 0>         
            psubb xmm6, xmm1;xmm6=|. . 255-t3 .|. . 255-t2 .|. . 255-t1 .|. . 255-t0 .| 
            psubb xmm6, xmm1;
            psubb xmm6, xmm1;        ;<a, r, g, b>
            psubb xmm6, xmm1;xmm6=|. . 255-4.t3 .|. . 255-4.t2 .|. . 255-t1.4 .|. . 255-t0.4 .|    ;<b, b, 255 - 4t, b>
            paddb xmm6, xmm11;xmm6=|. . 255-4.t3+128 .|. . 255-4.t2+128 .|. . 255-t1.4+128 .|. . 255-t0.4+128 .|
                                    

            psrld xmm6, 8      ; <0, b, b, 255 - (t - 160) * 4>
            pslld xmm6, 24      ;<255 - (t - 160) * 4, 0, 0, 0>
            psrld xmm6, 16      ; xmm6=|0 0 255-4.t3+128 0|0 0 255-4.t2+128 0|0 0 255-t1.4+128 0|0 0 255-t0.4+128 0| <0, 0, 255 - (t - 160) * 4, 0>

            pinsrb xmm6, r9b, 14
            pinsrb xmm6, r9b, 10
            pinsrb xmm6, r9b, 6
            pinsrb xmm6, r9b, 2; xmm6=|0 255 255-4.t3+128 0|0 255 255-4.t2+128 0|0 255 255-t1.4+128 0|0 255 255-t0.4+128 0| <0, 255, 255 + 640 - 4t, 0>


            movdqu xmm7, xmm7   ;<0, 0, 0, 0>                           224 <= t    <0,255 - 4t + 640, 0, 0>
            pinsrb xmm7, r9b, 14
            pinsrb xmm7, r9b, 10
            pinsrb xmm7, r9b, 6
            pinsrb xmm7, r9b, 2 ; xmm7=|0 255 0 0|0 255 0 0|0 255 0 0|0 255 0 0|   <0, 255, 0, 0>
            psubb xmm7, xmm1;  
            psubb xmm7, xmm1
            psubb xmm7, xmm1
            psubb xmm7, xmm1 ; xmm7= |. 255-4.t3 . .|0 255-4.t2 0 0|0 255-4.t1 0 0|0 255-4.t2 . .|   <b, 255 - 4t, b, b>
            paddb xmm7, xmm11;xmm7= |. 255-4.t3+128 . .|. 255-4.t2+128 . .|. 255-4.t1+128 . .|. 255-4.t2+128 . .|


            pslld xmm7, 8      ;<255 - (t - 224) * 4, b, b, 0>
            psrld xmm7, 24     ;<0, 0, 0, 255 - (t - 224) * 4>
            pslld xmm7, 16     ;<0, 255 - (t - 224) * 4, 0, 0>
                               ;xmm7= |0 255-4.t3+128 0 0|0 255-4.t2+128 0 0|0 255-4.t1+128 0 0|0 255-4.t2+128 0 0|
            psrld xmm1,  24    ; xmm1=|0 0 0 t3|0 0 0 0 t2|0 0 0 t1|0 0 0 t0|

            pcmpgtd xmm12, xmm1     ; [32 > t?...] Me quedo con t < 32
            pcmpgtd xmm13, xmm1     ; [96 > t?...] Me quedo con t < 96
            pxor    xmm13, xmm12    ; Me quedo con 32 <= t < 96
            pcmpgtd xmm14, xmm1     ; [160 > t?...] Me quedo con t < 160
            pxor    xmm14, xmm12
            pxor    xmm14, xmm13    ; Me quedo con 96 <= t < 160
            pcmpgtd xmm15, xmm1     ; [224 > t?...] Me quedo con t < 224
            pxor    xmm15, xmm12
            pxor    xmm15, xmm13
            pxor    xmm15, xmm14    ; Me quedo con 160 <= t < 224    ; t > 224?
            pxor    xmm9,  xmm12
            pxor    xmm9,  xmm13
            pxor    xmm9,  xmm14
            pxor    xmm9,  xmm15

            pand xmm12, xmm4        ; [t<32, 0, 0 , t<32, ...]
            pand xmm13, xmm5        ; [t<96, t <96, 0,...]
            pand xmm14, xmm3        ; [t<160, t<160, 0, 0 ,t<160]
            pand xmm15, xmm6        ; [t<224, t<224, 0, 0 ,t<224]
            pand  xmm9, xmm7        ; [t>224, t>224, 0, 0 ,t>224]

            por xmm12, xmm13
            por xmm12, xmm14
            por xmm12, xmm15
            por xmm12, xmm9        ; Las temperaturas de cada pixel estan en xmm12


            psrld xmm0, 24
            pslld xmm0, 24
            por xmm12, xmm0


            movdqu [rsi], xmm12

            add rsi, 16
    		add rdi, 16
            dec rcx
    		jmp .ciclo


    .fin:

    pop r9
    pop rbp
    ret
