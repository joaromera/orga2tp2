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

    mov eax, edx
	mul ecx						;[EDX:EAX]
	mov ecx, edx
	shl rcx, 32
	add ecx, eax
	shr rcx, 2

    cvtdq2ps xmm8, xmm8
    
    .ciclo:

        cmp rcx, 0
        je .fin
        movdqu xmm12, [mask32]
        movdqu xmm13, [mask96]
        movdqu xmm14, [mask160]
        movdqu xmm15, [mask224]
        movdqu xmm9,  [maskshuf]
        movdqu xmm0, [rdi]      ; xmm0 = | p4 | p3 | p2 | p1 | Pixeles originales
        movdqu xmm1, xmm0       ; xmm1 = | p4 | p3 | p2 | p1 |
        movdqu xmm2, xmm0       ; xmm2 = | p4 | p3 | p2 | p1 |

        pxor xmm7, xmm7         ; Masacara para desempaquetar a word
        punpcklbw xmm2, xmm7    ; xmm2 = |    p2    |    p1    |
        punpckhbw xmm1, xmm7    ; xmm1 = |    p4    |    p3    |

        psllq xmm1, 16          ; Shifteo a izquierda para olvidarme del alfa
        psllq xmm2, 16
        psrlq xmm1, 16
        psrlq xmm2, 16

        phaddw xmm2, xmm2       ; xmm2 = Suma horizontal de a word
        phaddw xmm1, xmm1       ; xmm1 = Suma horizontal de a word

        phaddw xmm2, xmm2       ; xmm2 = Suma horizontal de a word
        phaddw xmm1, xmm1       ; xmm1 = Suma horizontal de a word

        pshufhw xmm2, xmm2, 01010000b
        pshufhw xmm1, xmm1, 01010000b
        pshuflw xmm2, xmm2, 01010000b
        pshuflw xmm1, xmm1, 01010000b

        psrld xmm2, 16
        psrld xmm1, 16

        cvtdq2ps xmm1, xmm1     ; Convierto los valores de xmm1 a float
        cvtdq2ps xmm2, xmm2
        
        blendps xmm1, xmm2, 0011b   ; xmm1 = |  t4  |  t2  |  t3  |  t1  |
        
        ; <t, t, t, t>          t < 32   <0, 0, 0, 4t + 128>
        divps xmm1, xmm8        ; Divido todo por 3

        cvtps2dq xmm1, xmm1

        packusdw xmm1, xmm1     ; xmm1 = |  t4  |  t3  |  t2   |  t1  |
        packuswb xmm1, xmm1

        pshufb xmm1, xmm10

        ; <t, t, t, t>          t < 32   <0, 0, 0, 4t + 128>
        movdqu xmm4, xmm1                               ;<a, r, g, b>
        paddb  xmm4, xmm1   ; <2t, 2t, 2t, 2t>
        paddb  xmm4, xmm1   ; <3t, 3t, 3t, 3t>
        paddb  xmm4, xmm1   ; <4t, 4t, 4t, 4t>
        paddb  xmm4, xmm11  ; <4t + 128, b, b, b>
        psrld  xmm4, 24      ; <0, 0, 0, x>

        


        movdqu xmm5, xmm1   ;<t, t, t, t>           32 <= t < 96    <0, 0, (t - 32) * 4, 255>
        paddb xmm5, xmm1
        paddb xmm5, xmm1    
        paddb xmm5, xmm1
        psubb xmm5, xmm11


        pinsrb xmm5, r9b, 12
        pinsrb xmm5, r9b, 8                 ; < a, r , g, b>
        pinsrb xmm5, r9b, 4
        pinsrb xmm5, r9b, 0                     ;<b, b, (t - 32) * 4, 255>

        pslld xmm5, 16                          ;<(t - 32) * 4 , 255, 0, 0>
        psrld xmm5, 16                          ;<0, 0, x, 255>



        movdqu xmm3, xmm7   ;<0, 0, 0, 0>       96 <= t < 160
        movdqu xmm2, xmm7
        paddb  xmm2, xmm1  ; <t, t, t, t>
        paddb  xmm2, xmm1
        paddb  xmm2, xmm1
        paddb  xmm2, xmm1   ;<b, 4t, b, b>
        psubb xmm2, xmm11


        pslld  xmm2, 24     ;<0, 0, 0, (t - 96) * 4> 
        psrld  xmm2, 8      ;<0, (t - 96) * 4, 0, 0>
        pinsrb xmm3, r9b, 12
        pinsrb xmm3, r9b, 8                 ;<r, g, b, a>
        pinsrb xmm3, r9b, 4
        pinsrb xmm3, r9b, 0 ;<0,0,0,255>
        psubb  xmm3, xmm1
        psubb  xmm3, xmm1
        psubb  xmm3, xmm1
        psubb  xmm3, xmm1   ;<b , b, b, 255 - 4t>
        paddb  xmm3, xmm11


        pslld  xmm3, 24      ;<255 + (96 - t) * 4, 0, 0, 0>
        psrld  xmm3, 24      ;<0, 0, 0, 255 + (96 - t) * 4>

        pinsrb xmm3, r9b, 13
        pinsrb xmm3, r9b, 9
        pinsrb xmm3, r9b, 5
        pinsrb xmm3, r9b, 1 ;<0,0,255,255 - (t - 96) * 4>

        paddb xmm3, xmm2




        ;160 <= t < 224  <0, 255, 255 + 640 - 4t, 0>
        movdqu xmm6, xmm7   ;<0, 0, 0, 0>
        pinsrb xmm6, r9b, 13
        pinsrb xmm6, r9b, 9
        pinsrb xmm6, r9b, 5
        pinsrb xmm6, r9b, 1 ;<0, 0, 255, 0>         
        psubb xmm6, xmm1
        psubb xmm6, xmm1
        psubb xmm6, xmm1        ;<a, r, g, b>
        psubb xmm6, xmm1    ;<b, b, 255 - 4t, b>
        paddb xmm6, xmm11
                                

        psrld xmm6, 8      ; <0, b, b, 255 - (t - 160) * 4>
        pslld xmm6, 24      ;<255 - (t - 160) * 4, 0, 0, 0>
        psrld xmm6, 16      ; <0, 0, 255 - (t - 160) * 4, 0>

        pinsrb xmm6, r9b, 14
        pinsrb xmm6, r9b, 10
        pinsrb xmm6, r9b, 6
        pinsrb xmm6, r9b, 2 ;<0, 255, 255 + 640 - 4t, 0>


        movdqu xmm7, xmm7   ;<0, 0, 0, 0>                           224 <= t    <0,255 - 4t + 640, 0, 0>
        pinsrb xmm7, r9b, 14
        pinsrb xmm7, r9b, 10
        pinsrb xmm7, r9b, 6
        pinsrb xmm7, r9b, 2 ;<0, 255, 0, 0>
        psubb xmm7, xmm1 
        psubb xmm7, xmm1
        psubb xmm7, xmm1
        psubb xmm7, xmm1    ;<b, 255 - 4t, b, b>
        paddb xmm7, xmm11


        pslld xmm7, 8      ;<255 - (t - 224) * 4, b, b, 0>
        psrld xmm7, 24     ;<0, 0, 0, 255 - (t - 224) * 4>
        pslld xmm7, 16     ;<0, 255 - (t - 224) * 4, 0, 0>

        psrld xmm1,  24

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
