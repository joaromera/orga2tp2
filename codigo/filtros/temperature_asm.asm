global temperature_asm

section .data
    align 16 
    maskBlend: dd 0, 1, 0, 1
    div3: times 4 dd 3
    const128: dq 128
    const32: dq 32
    const96: dq 96
    mask1: db 0, 0, 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 3, 3, 3, 3
    mask32: times 16 db 32
    mask96: times 16 db 96
    mask160: times 16 db 160
    mask224: times 16 db 224
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
    movdqu xmm9,  [maskBlend]
    movdqu xmm10, [mask1]
    movdqu xmm11, [const32]
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

        ; pslld xmm2, 16
        ; pslld xmm1, 16
        ; psrld xmm2, 16
        ; psrld xmm1, 16

        ; phaddd xmm2, xmm2       ; xmm2 = Suma horizontal de a double word
        ; phaddd xmm1, xmm1       ; xmm1 = Suma horizontal de a double word
        
        blendps xmm1, xmm2, 5   ; xmm1 = |  t4  |  t2  |  t3  |  t1 |
        psrld xmm1, 16
        
        cvtdq2ps xmm1, xmm1     ; Convierto los valores de xmm1 a float
        
        divps xmm1, xmm8        ; Divido todo por 3

        cvtps2dq xmm1, xmm1

        packusdw xmm1, xmm1     ; xmm1 = |  t4  |  t3  |  t2   |  t1  |
        packuswb xmm1, xmm1

        pshufb xmm1, xmm10

        movdqu xmm2, [const128]
        ; <t, t, t, t>          t < 32   <0, 0, 0, 4t + 128>
        movdqu xmm4, xmm1   
        paddd  xmm4, xmm4   ; <2t, 2t, 2t, 2t>
        paddd  xmm4, xmm4   ; <3t, 3t, 3t, 3t>
        paddd  xmm4, xmm4   ; <4t, 4t, 4t, 4t>
        paddd  xmm4, xmm2   ; <4t + 128, 4t + 128, 4t + 128, 4t + 128>
        pslld xmm4, 24     ; <4t + 128, 0, 0, 0>
        psrld xmm4, 24     ; <0, 0, 0, 4t + 128>
        


        movdqu xmm5, xmm1   ;<t, t, t, t>           32 <= t < 96    <0, 0, (t - 32) * 4, 255>
        paddd xmm5, xmm1
        paddd xmm5, xmm1
        paddd xmm5, xmm1    ;<(t - 32) * 4, (t - 32) * 4, (t - 32) * 4, (t - 32) * 4>
        psubd xmm5, xmm11   
        psubd xmm5, xmm11   
        psubd xmm5, xmm11        
        psubd xmm5, xmm11
        pinsrb xmm5, r9b, 12
        pinsrb xmm5, r9b, 8
        pinsrb xmm5, r9b, 4
        pinsrb xmm5, r9b, 0

        pslld xmm5, 16
        psrld xmm5, 16    

        movdqu xmm3, xmm1   ;<t, t, t, t>       96 <= t < 160
        ; ;psllw xmm3, 4       ;<t, t, t, 0>
        ; ;psrlw xmm3, 4       ;<0, t, t, t>
        ; paddd xmm3, xmm3    ;<2t,2t,2t,2t>
        ; paddd xmm3, xmm3    ;<4t,4t,4t,4t>
        ; packusdw xmm3, xmm3
        ; packuswb xmm3, xmm3
        ; pshufb xmm3, xmm10
        ; ;psubd xmm3, [const96]
        ; ;psubd xmm3, [const96]
        ; ;psubd xmm3, [const96]
        ; ;psubd xmm3, [const96]


        ;160 <= t < 224  <0, 255, 255 + 640 - 4t, 0>
        movdqu xmm6, xmm7   ;<0, 0, 0, 0>
        pinsrb xmm6, r9b, 13
        pinsrb xmm6, r9b, 9
        pinsrb xmm6, r9b, 5
        pinsrb xmm6, r9b, 1          
        psubd xmm6, xmm1
        paddd xmm6, xmm2
        psubd xmm6, xmm1
        paddd xmm6, xmm2
        psubd xmm6, xmm1
        paddd xmm6, xmm2
        psubd xmm6, xmm1
        paddd xmm6, xmm2
        paddd xmm6, xmm2    ;<640 - 4t, 640 - 4t, 255 + 640 - 4t, 640 - 4t>

        pslld xmm6, 24       ;<255 + 640 - 4t, 0, 0, 0>
        psrld xmm6, 16      ;<0, 0, 255 + 640 - 4t, 0>

        pinsrb xmm6, r9b, 14
        pinsrb xmm6, r9b, 10
        pinsrb xmm6, r9b, 6
        pinsrb xmm6, r9b, 2 ;<0, 255, 255 + 640 - 4t, 0>


        movdqu xmm7, xmm1   ;<t, t, t, t>                           224 <= t    <0,255 - 4t + 640, 0, 0>
        ; paddd  xmm7, xmm9   ;<t + 128, t + 128, t + 128, t + 128>
        ; paddd  xmm7, xmm9   ;<255, 255, 255 ,255>
        ; ;psrlw xmm7, 8       ;<0, 0, 255, 255>
        ; ;psllw xmm7, 12       ;<255, 0, 0, 0>
        ; ;psrlw xmm7, 4       ;<0, 255, 0, 0>
        ; psubd xmm7, xmm2 
        ; psubd xmm7, xmm2
        ; psubd xmm7, xmm2
        ; psubd xmm7, xmm2    ;<0, 255 - 4t, 0, 0>
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9
        ; paddd xmm7, xmm9    ;<255, 255 - 4t + 896, 255, 255>
        ; ;psllw xmm7, 4       ;<255 - 4t + 640, 255, 255, 0>
        ; ;psrlw xmm7, 12       ;<0, 0, 0, 255 - 4t + 640>
        ; ;psllw xmm7, 8       ;<0,255 - 4t + 640, 0, 0>
        ; packusdw xmm7, xmm7
        ; packuswb xmm7, xmm7
        ; pshufb xmm7, xmm10

        ; pcmpgtb xmm12, xmm1     ;[32 > t?...] Me quedo con t < 32
        ; pcmpgtb xmm13, xmm1     ;[96 > t?...] Me quedo con t < 96
        ; pxor    xmm13, xmm12    ; Me quedo con 32 <= t < 96
        ; pcmpgtb xmm14, xmm1     ;[160 > t?...] Me quedo con t < 160
        ; pxor    xmm14, xmm12
        ; pxor    xmm14, xmm13    ; Me quedo con 96 <= t < 160
        ; pcmpgtb xmm15, xmm1     ;[224 > t?...] Me quedo con t < 224
        ; pxor    xmm15, xmm12
        ; pxor    xmm15, xmm13
        ; pxor    xmm15, xmm14    ; Me quedo con 160 <= t < 224
        ; ;pcmpgtb xmm1,  xmm15    ; t > 224?
        

        ; pand xmm12, xmm4        ;[t<32, 0, 0 , t<32, ...]
        ; pand xmm13, xmm5        ;[t<96, t <96, 0,...]
        ; pand xmm14, xmm3        ;[t<160, t<160, 0, 0 ,t<160]
        ; pand xmm15, xmm6        ;[t<224, t<224, 0, 0 ,t<224]
        ; pand xmm1, xmm7         ;[t>224, t>224, 0, 0 ,t>224]


        ; por xmm12, xmm13
        ; por xmm12, xmm14
        ; por xmm12, xmm15
        ; por xmm12, xmm1        ; Las temperaturas de cada pixel estan en xmm12

        movdqu [rsi], xmm6
        add rsi, 16
		add rdi, 16
        dec rcx
		jmp .ciclo


    .fin:

    pop r9
    pop rbp
    ret
