; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   rbp + 16 = x0
; 	rbp + 24 = y0


global ondas_asm

section .data
	maskShuf: db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	mask1: times 4 dd 1
	mask2: dd 0, 1, 2, 3
	mask3: times 4 dd 0
	radio: times 4 dd 35.0
	wavelenght: times 4 dd 64.0
	pi: times 4 dd 3.1415
	todosdos: times 4 dd 2.0
	trainwidth: times 4 dd 3.4
	mask255: times 16 db 255


section .text

ondas_asm:
	push rbp
	mov rbp, rsp						;alineada
	push rbx
	push r9
	push r12
	push r13
	push r14
	push r15							;desalineada

	mov r9b, 255
	mov r15, 6
	mov r14, 120
	mov rbx, 5040
	shr rdx, 2

	movdqu xmm6, [pi]
	movdqu xmm7, [todosdos]
	movdqu xmm8, [wavelenght]
	movdqu xmm9, [radio]
	movdqu xmm10, [mask1]				;xmm10 <- |1|1|1|1| para incrementar los indices empaquetados
	movdqu xmm11, [mask2]				;xmm11 <- |0|1|2|3| primeros indices para columnas
	movdqu xmm12, [mask3]				;xmm12 <- |0|0|0|0| indices para filas
	movdqu xmm15, [trainwidth]
	mov r12, [rbp + 16]					;x0
	mov r13, [rbp + 24]					;y0

	pxor xmm13, xmm13
	movq xmm13, r12
	packusdw xmm13, xmm13
	packusdw xmm13, xmm13				;xmm13 <- |x0|x0|x0|x0|

	pxor xmm14, xmm14
	movq xmm14, r13
	packusdw xmm14, xmm14
	packusdw xmm14, xmm14				;xmm13 <- |y0|y0|y0|y0|

	xor r10, r10						
	xor r11, r11

	.cicloext:
	xor r11, r11
	cmp r10, rcx						;verificar si es ultima fila de la imagen
	je .fin

	.cicloint:
	cmp r11, rdx						;verificar si es el ultimo pixel de la fila
	je .proxfila

		;CALCULO DE PROFUNDIDAD
		movdqu xmm3, xmm11					
		psubd xmm3, xmm13					;x - x0

		movdqu xmm4, xmm12					
		psubd xmm4, xmm14					;y - y0	

		pmulld xmm3, xmm3					;dx*dx
		pmulld xmm4, xmm4					;dy*dy

		paddd xmm3, xmm4					;dx*dx+dy*dy
		cvtdq2ps xmm3, xmm3
		sqrtps xmm3, xmm3					;(dx*dx+dy*dy)^(1/2)
		subps xmm3, xmm9					;(dx*dx+dy*dy)^(1/2) - RADIO
		divps xmm3, xmm8					;R <- ((dx*dx+dy*dy)^(1/2) - RADIO)/WAVELENGTH	

		movdqu xmm7, xmm3
		movdqu xmm4, xmm3
		roundps xmm3, xmm3, 0001b			;trunco
		subps xmm4, xmm3					;K  <- r - floor(r)								

											;xmm3 <- R
											;xmm4 <- K
		
		movdqu xmm5, xmm4
		paddd xmm10, xmm10
		cvtdq2ps xmm10, xmm10
		mulps xmm5, xmm10
		divps xmm10, xmm10
		cvtps2dq xmm10, xmm10
		mulps xmm5, xmm6 
		subps xmm5, xmm6					;xmm5 <- T = k*2*PI-PI

		movdqu xmm3, xmm7
		divps xmm3, xmm15					;r/traindiwth
		mulps xmm3, xmm3					;(r/trainwidth) * (r/trainwidth)
		cvtdq2ps xmm10, xmm10
		addps xmm3, xmm10					;1 + (r/trainwidth * r/trainwidth)
		movdqu xmm4, xmm10					;xmm4 <- |1|1|1|1|
		divps xmm4, xmm3					;a = 1 / 1 + (r/trainwidth * r/trainwidth)
		cvtps2dq xmm10, xmm10

											;xmm5 <- t
											;xmm4 <- a

			;sin taylor
			movdqu xmm1, xmm5					;xmm1 <- t

			movdqu xmm3, xmm5					;calculamos x al cubo
			mulps xmm3, xmm5
			mulps xmm3, xmm5

			movq xmm2, r15
			packssdw xmm2, xmm2
			packssdw xmm2, xmm2
			cvtdq2ps xmm2, xmm2

			divps xmm3, xmm2
			subps xmm1, xmm3					;x - x^3 / 6

			movdqu xmm3, xmm5					;calculamos x a la quinta
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5

			movq xmm2, r14
			packssdw xmm2, xmm2
			packssdw xmm2, xmm2
			cvtdq2ps xmm2, xmm2

			divps xmm3, xmm2
			addps xmm1, xmm3					;x - x^3 / 6 + x^5 / 120

			movdqu xmm3, xmm5					;calculamos x a la septima
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5

			movq xmm2, rbx
			packssdw xmm2, xmm2
			packssdw xmm2, xmm2
			cvtdq2ps xmm2, xmm2

			divps xmm3, xmm2
			subps xmm1, xmm3					;x - x^3 / 6 + x^5 / 120 - x^7 / 5040

			mulps xmm4, xmm1					;XMM4 <- PROFUNDIDAD
			mulps xmm4, xmm8					;XMM4 <- PROFUNDIDAD * 64

	;agrego profundidad
	cvtps2dq xmm4, xmm4

	movdqu xmm7, xmm4
	pshufd xmm4, xmm4, 11111111b				;me quedo con el primero

	pxor xmm3, xmm3

	movdqu xmm1, [rdi]							;levanto imagen
	movdqu xmm0, xmm1
	punpckhbw xmm1, xmm3						;desempaqueto imagen
	movdqu xmm2, xmm1
	punpckhwd xmm1, xmm3
	punpcklwd xmm2, xmm3
	paddd xmm1, xmm4
	movdqu xmm4, xmm7
	pshufd xmm4, xmm4, 10101010b
	paddd xmm2, xmm4
	packssdw xmm2,xmm1
	movdqu xmm5, xmm2
	
	movdqu xmm1, xmm0
	punpcklbw xmm1, xmm3
	movdqu xmm2, xmm1
	punpckhwd xmm1, xmm3
	punpcklwd xmm2, xmm3
	movdqu xmm4, xmm7
	pshufd xmm4, xmm4, 01010101b
	paddd xmm1, xmm4
	movdqu xmm4, xmm7
	pshufd xmm4, xmm4, 00000000b
	paddd xmm2, xmm4
	packssdw xmm2,xmm1
	packuswb xmm2,xmm5

	psrld xmm0, 24
	pslld xmm0, 24
	
	por xmm2, xmm0
	
	movdqu [rsi], xmm2


	add rsi, 16
	add rdi, 16
	inc r11
	paddd xmm11, xmm10
	paddd xmm11, xmm10
	paddd xmm11, xmm10
	paddd xmm11, xmm10 
	jmp .cicloint

	.proxfila:
		inc r10
		paddd xmm12, xmm10
		movdqu xmm11, [mask2]
		jmp .cicloext
	
	.fin:
		pop r15
		pop r14
		pop r13
		pop r12
		pop r9
		pop rbx
		pop rbp
		ret
