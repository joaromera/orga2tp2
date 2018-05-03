; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   rbp + 16 = x0
; 	rbp + 24 = y0

extern ondas_c

global ondas_asm

section .data
	maskShuf: db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	mask1: times 4 dd 1
	mask2: dd 0, 1, 2, 3
	mask3: times 4 dd 0
	radio: times 4 dd 35.0
	wavelenght: times 4 dd 64.0
	pi: times 4 dd 3.14159
	todosdos: times 4 dd 2.0
	trainwidth: times 4 dd 3.4


section .text

ondas_asm:
	;; TODO: Implementar

	push rbp
	mov rbp, rsp						;alineada
	push rbx
	push r12
	push r13
	push r14
	push r15							;desalineada
	sub rsp, 8

	mov r15, 6
	mov r14, 120
	mov rbx, 5040
	shr rdx, 2

	movdqu xmm15, [trainwidth]
	movdqu xmm6, [pi]
	movdqu xmm7, [todosdos]
	movdqu xmm8, [wavelenght]
	movdqu xmm9, [radio]
	movdqu xmm10, [mask1]				;xmm10 <- |1|1|1|1| para incrementar los indices empaquetados
	movdqu xmm11, [mask2]				;xmm11 <- |0|1|2|3| primeros indices para columnas
	movdqu xmm12, [mask3]				;xmm12 <- |0|0|0|0| indices para filas
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
	cmp r11, rdx						;verificar si es la ultima columna de la fila
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

		cvttps2dq xmm5, xmm3					;trunco
		cvtdq2ps xmm5, xmm5
		movdqu xmm4, xmm3
		subps xmm4, xmm5					;K  <- r - floor(r)								

											;xmm3 <- R
											;xmm4 <- K
		
		movdqu xmm5, xmm4
		mulps xmm5, xmm7
		mulps xmm5, xmm6 
		subps xmm5, xmm6					;xmm5 <- T = k*2*PI-PI

		divps xmm3, xmm15					;r/traindiwth
		mulps xmm3, xmm3					;r/trainwidth * r/trainwidth
		cvtdq2ps xmm10, xmm10
		addps xmm3, xmm10					;1 + (r/trainwidth * r/trainwidth)
		movdqu xmm4, xmm10					;xmm4 <- |1|1|1|1|
		cvtps2dq xmm10, xmm10
		divps xmm4, xmm3					;a = 1 / 1 + (r/trainwidth * r/trainwidth)

											;xmm5 <- t
											;xmm4 <- a

			;sin taylor
			movdqu xmm1, xmm5					;xmm1 <- t

			movdqu xmm3, xmm5					;calculamos x al cubo
			mulps xmm3, xmm5
			mulps xmm3, xmm5

			movq xmm2, r15
			packusdw xmm2, xmm2
			packusdw xmm2, xmm2
			cvtdq2ps xmm2, xmm2

			divps xmm3, xmm2
			subps xmm1, xmm3					;x - x^3 / 6

			movdqu xmm3, xmm5					;calculamos x a la quinta
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5
			mulps xmm3, xmm5

			movq xmm2, r14
			packusdw xmm2, xmm2
			packusdw xmm2, xmm2
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
			packusdw xmm2, xmm2
			packusdw xmm2, xmm2
			cvtdq2ps xmm2, xmm2

			divps xmm3, xmm2
			subps xmm1, xmm3					;x - x^3 / 6 + x^5 / 120 - x^7 / 5040

			mulps xmm4, xmm1					;XMM4 <- PROFUNDIDAD


			mulps xmm4, xmm8					;XMM4 <- PROFUNDIDAD * 64

	;agrego profundidad
	movdqu xmm0, [rdi]

	;cvtps2dq xmm4, xmm4
	movdqu xmm1, xmm4
	psrldq    xmm1, 8
	cvtps2pd xmm1, xmm1
	cvtps2pd xmm4, xmm4

	cvtpd2dq xmm1, xmm1
	cvtpd2dq xmm4, xmm4
	pslldq   xmm1, 8
	paddd    xmm4, xmm1
	packusdw xmm4, xmm4
	packuswb xmm4, xmm4
	pshufb   xmm4, [maskShuf]
	pslld xmm4, 8
	psrld xmm4, 8
	paddusb xmm0, xmm4

	movdqu [rsi], xmm0

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
		add rsp, 8
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret
