; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

section .data
	maskAltaBaja: dw 1, 1, 2, 1, 1, 1, 2, 1
	maskMedio:    dw 1, 1, -6, 1, 1, 1, -6, 1
DEFAULT REL

section .text
global edge_asm}
edge_asm:									;NOTAR QUE LOS PIXELES MIDEN 1 BYTE
	push rbp
	mov rbp, rsp
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	movdqu xmm14, [maskAltaBaja] ;xmm14=|1|2|1|1|1|2|1|1|
	movdqu xmm15, [maskMedio]	 ;xmm15=|1|-6|1|1|1|-6|1|1|
	mov r13, rdx                 ;r13=width  
	shr r13, 2					 ;r13=width/4 voy a procesar de a 16 pixeles/bytes
								 ;r10 y r11 son contadores para iterar
	xor r10, r10				 ;r10=0		
	xor r11, r11				 ;r11=0	
	mov r9, rdx					 ;r9=width
	neg r9						 ;r9=-width
	xor r14, r14			     ;r14=0

	;COPIO PRIMER FILA SIN MODIFICAR
	inc r10
;
	.primerFila:	
		cmp r14, r13						;verificar si es la ultima columna de la fila
		je .edge
		movdqu xmm0, [rdi]	;xmm0=|a3 b3 g3 r|a2 b2 g2 r2|a1 b1 g1 r1|a0 b0 g0 r0|	
		pslldq xmm0, 12		;xmm0=|a3 b3 g3 r3|0|0|0| shifteo xmm0 12 bytes a izquierda
		psrldq xmm0, 12		;xmm0=|0|0|0|a3 b3 g3 r3| shifteo xmm0 12 bytes a derecha
		movd r8d, xmm0		;r8d=|a3 b3 g3 r3| Muevo la parte baja de xmm0 a r8d
 		mov [rsi], r8d		; copio a memoria la primer fila sin modificar
		add rsi, 4
		add rdi, 4
		inc r14
		jmp .primerFila

	.edge:
		cmp r11, rdx	; cmp contadorPixel width
		je .proximaFila

		dec rdx

		cmp r11, rdx	; cmp  contadorPixel width
		jge .ultimoPixel ; veo si no estoy en la ulima columna de pixeles
		inc rdx					;Caso q estoy aplicando el edge

		mov eax, [rdi]			;eax=|a b g r|
		cmp r11, 0				;comparo si estoy en el primer pixel
		je .primerPixel		

		.continuarEdge:
								;Caso centro de la matriz
		pxor xmm2, xmm2			;xmm2=|0 0 0 0|
		pxor xmm1, xmm1			;xmm1=|0 0 0 0|
		pxor xmm0, xmm0			;xmm0=|0 0 0 0|
		movd xmm0, eax			;xmm0=|0|0|0|a b g r|
		punpcklbw xmm0, xmm1	;xmm0=|0|a b g r| convert de byte a word parte baja
		movd xmm1, eax			;xmm1=|0|0|0|a b g r|
		punpcklbw xmm1, xmm2	;xmm1=|0|a b g r|
		pslldq xmm0, 8			;xmm0=|a b g r|0|
		paddw xmm0, xmm1		;xmm0=|a b g r|a b g r| Centro: centro de la matriz

								;Parte baja de la matriz
		mov eax, [rdi + rdx]	;eax=|a b g r| 
		pxor xmm3, xmm3			;xmm3=|0|0|0|0|
		pxor xmm2, xmm2			;xmm2=|0|0|0|0|
		pxor xmm1, xmm1			;xmm1=|0|0|0|0|
		movd xmm1, eax			;xmm1=|0|0|0|a b g r|
		punpcklbw xmm1, xmm2	;xmm1=|0|a b g r| conver de byte a word parte baja
		movd xmm2, eax			;xmm2=|0|0|0|a b g r|
		punpcklbw xmm2, xmm3	;xmm2=|0|a b g r|
		pslldq xmm1, 8			;xmm1=|a b g r|0|
		paddw xmm1, xmm2		;xmm1=|a b g r|a b g r| Baja: parte baja de la matriz

		mov eax, [rdi + r9]		;mov eax,[rdi-width]
		pxor xmm4, xmm4			;xmm4=|0|0|0|0|
		pxor xmm3, xmm3			;xmm3=|0|0|0|0|
		pxor xmm2, xmm2			;xmm2=|0|0|0|0|
		movd xmm2, eax			;xmm2=|0|0|0|a b g r|
		punpcklbw xmm2, xmm3	;xmm2=|0|a b g r|
		movd xmm3, eax			;xmm3=|0|0|0|a b g r|
		punpcklbw xmm3, xmm4	;xmm3=|0|a b g r|
		pslldq xmm2, 8			;xmm2=|a b g r|0|;
		paddw xmm2, xmm3		;xmm2=|a b g r|a b g r| Alta: parte alta de la matriz
								;divido por 2 a xmm2 y xmm1
		psrlw xmm2, 1			;xmm2=|a/2 b/2 g/2 r/2|a/2 b/2 g/2 r/2| Alta
		psrlw xmm1, 1			;xmm1=|a/2 b/2 g/2 r/2|a/2 b/2 g/2 r/2| Baja

									 ;xmm0=|a b g r|a b g r| Centro
		pshuflw xmm0, xmm0, 10010000b;xmm0=|a b g r|b g r r| shift word parte baja [63:0]
		pshufhw xmm0, xmm0, 11100101b;xmm0=|a b g g|b g r r|  shift word parte alta [127:64]
 
 									 ;xmm1=|a/2 b/2 g/2 r|a/2 b/2 g/2 r/2| Baja
		pshuflw xmm1, xmm1, 10010000b;xmm1=|a/2 b/2 g/2 r/2|b/2 g/2 r/2 r/2| 
		pshufhw xmm1, xmm1, 11100101b;xmm1=|a/2 b/2 g/2 g/2|b/2 g/2 r/2 r/2|

									 ;xmm2=|a/2 b/2 g/2 r/2|a/2 b/2 g/2 r/2| Alta
		pshuflw xmm2, xmm2, 10010000b;xmm2=|a/2 b/2 g/2 r/2|b/2 g/2 r/2 r/2|
		pshufhw xmm2, xmm2, 11100101b;xmm2=|a/2 b/2 g/2 g/2|b/2 g/2 r/2 r/2|
									;shiftea cada paquete quad word a derecha cant de bits
		psrlq xmm0, 16; 			;xmm0=|0 a b g|0 b g r| Centro
		psrlq xmm1, 16;				;xmm1=|0 a/2 b/2 g/2|0 b/2 g/2 r/2| BAja
		psrlq xmm2, 16				;xmm2=|0 a/2 b/2 g/2|0 b/2 g/2 r/2| Alta
									;;shiftea cada paquete quad word a izquierda cantidad de bit
		psllq xmm0, 16				;xmm0=|a b g 0|b g r 0| Centro
		psllq xmm1, 16				;xmm1=|a/2 b/2 g/2 0|b/2 g/2 r/2 0| Baja
		psllq xmm2, 16				;xmm2=|a/2 b/2 g/2 0|b/2 g/2 r/2 0| Alta

									;multiplico xmm2 por los valores de la matriz
									;xmm14=|1 2 1 1|1 2 1 1|
									;xmm15=|1 -6 1 1|1 -6 1 1|
		pmullw xmm2, xmm14			;xmm2=|a/2 b g/2 0|b/2 g r/2 0| Alta
		pmullw xmm1, xmm14			;xmm1=|a/2 b g/2 0|b/2 g r/2 0| Baja
		pmullw xmm0, xmm15			;xmm0=|a -6*b g 0|b -6*g r 0| Centro
									
		paddw xmm1, xmm2			;xmm1=|a/2+a/2 b+b g/2*g/2 0|b/2+b/2 g+g r/2*r/2 0| Baja + Alta
		paddw xmm0, xmm1			;xmm0=|a+a/2+a/2 -6*b+b+b g+g/2*g/2 0|
									;     |b+b/2+b/2 -6*g+g+g r+r/2*r/2 0| Centro + Baja + Alta
									;Sima horizontal
									;xmm0=|s7 s6 s5 s4| s3 s2 s1 s0|
		phaddw xmm0, xmm0			;xmm0=|s7+s6 s5+s4 s3+s2 s1+s0|s7+s6 s5+s4 s3+s2 s1+s0|
		phaddw xmm0, xmm0			;xmm0=|s7+s6+s5+s4 s3+s2+s1+s0 s7+s6+s5+s4 s3+s2+s1+s0|
									;     |s7+s6+s5+s4 s3+s2+s1+s0 s7+s6+s5+s4 s3+s2+s1+s0|  
									;xmm0=|s[7:4] s[3:0] s[7:4] s[3:0]|s[7:4] s[3:0] s[7:4] s[3:0]| 
									; Empaqueto de word a byte
		packuswb xmm0,xmm0			;xmm0=|s[7:4] s[3:0] s[7:4] s[3:0]|s[7:4] s[3:0] s[7:4] s[3:0]|
									;	  |s[7:4] s[3:0] s[7:4] s[3:0]|s[7:4] s[3:0] s[7:4] s[3:0]| 
		pxor xmm2, xmm2				;desempaqueto de byte a word la parte alta de xmm2
		punpckhbw xmm0, xmm2		;xmm0=|s[7:4] s[3:0] s[7:4] s[3:0]|s[7:4] s[3:0] s[7:4] s[3:0]|

		pshuflw xmm0, xmm0, 00000000b	;xmm0=|s[7:4] s[3:0] s[7:4] s[3:0]|s[3:0] s[3:0] s[3:0] s[3:0]|
		pshufhw xmm0, xmm0, 01010101b	;xmm0=|s[7:4] s[7:4] s[7:4] s[7:4]|s[3:0] s[3:0] s[3:0] s[3:0]|
									;shiftea cada paquete quad word a derecha 48  bits
		psrlq xmm0, 48; 			;xmm0=|0 0 0 s[7:4]|0 0 0 s[3:0]|
		movd eax, xmm0				;eax=|0 s[3:0]|
		mov [rsi], al				;[rsi]= al[7:0] byte
									; shifteo al xmm0 en 8 bytes
		psrldq xmm0, 8				;xmm0=|0 0 0 0|0 0 0 s[7:4]|

		movd eax, xmm0				;eax=|0 s[7:4]|
		inc rsi
		mov [rsi], al				;[rsi]=eax[7:0]

		inc rsi
		add rdi, 2

		add r11, 2

		jmp .edge

	.primerPixel:
		inc r11
		xor r12, r12
		mov r12b, [rdi]		; compio el primer pixel de la fila
		mov [rsi], r12b
		inc rsi				;; incremento puntero a proximos pixeles de imagen de destino
		jmp .continuarEdge

	.ultimoPixel:
		inc r11				;
		inc rdx
		xor r12, r12		;
		inc rdi
		mov r12b, [rdi]		; copio el ultimo pixel de la columna sin modificar.
		mov [rsi], r12b
		inc rsi				; incremento puntero a proximos pixeles de imagen de destino	
		inc rdi				; incremento puntero a proximos pixeles de la imagen fuente
		jmp .edge           ; salto al edge

	.proximaFila:
		inc r10
		xor r11, r11
		dec rcx
		cmp r10, rcx
		je .ultimaFila
		inc rcx
		jmp .edge

	.ultimaFila:
		cmp r11, r13						;verificar si es la ultima columna de la fila
		je .fin
		movdqu xmm0, [rdi]
		pslldq xmm0, 12
		psrldq xmm0, 12
		movd r8d, xmm0

		mov [rsi], r8d 
		add rsi, 4
		add rdi, 4
		inc r11
		jmp .ultimaFila

	.fin:
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbp
	ret
	