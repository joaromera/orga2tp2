; void ondas_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int width,
; 	int height,
; 	int src_row_size,
;   int dst_row_size,
;	int x0,
;	int y0
; );

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
	mask1: times 4 dd 1
	mask2: dd 0, 1, 2, 3
	mask3: times 4 dd 0
	radio: times 4 dd 35
	wavelenght: times 4 dd 64.0

section .text

ondas_asm:
	;; TODO: Implementar

	push rbp
	mov rbp, rsp
	movdqu xmm8, [wavelenght]
	cvtdq2ps xmm8, xmm8
	movdqu xmm9, [radio]
	movdqu xmm10, [mask1]				;xmm10 <- |1|1|1|1| para incrementar los indices empaquetados
	movdqu xmm11, [mask2]				;xmm11 <- |0|1|2|3| primeros indices para columnas
	movdqu xmm12, [mask3]				;xmm12 <- |0|0|0|0| indices para filas
	mov r12, [rbp + 16]					;x0
	mov r13, [rbp + 24]					;y0
	xor r10, r10						
	xor r11, r11
	
	mov r12, 1							;xmm12 <- x0
	movq xmm13, r12
	packusdw xmm13, xmm13
	packusdw xmm13, xmm13				;xmm13 <- |x0|x0|x0|x0|

	mov r13, 2							;xmm13 <- y0
	movq xmm14, r13
	packusdw xmm14, xmm14
	packusdw xmm14, xmm14				;xmm13 <- |y0|y0|y0|y0|

	.cicloext:
	xor r11, r11
	; cmp r10, rdx						;verificar si es la ultima columna de la fila
	; je .fin

	;CALCULO DE PROFUNDIDAD
	movdqu xmm3, xmm11					;x - x0
	psubd xmm3, xmm13

	movdqu xmm4, xmm12					;y - y0
	psubd xmm4, xmm14						

	pmulld xmm3, xmm3					;dx*dx
	pmulld xmm4, xmm4					;dy*dy

	paddd xmm3, xmm4					;dx*dx+dy*dy
	cvtdq2ps xmm3, xmm3
	sqrtps xmm3, xmm3					;(dx*dx+dy*dy)^(1/2)
	subps xmm3, xmm9					;(dx*dx+dy*dy)^(1/2) - RADIO
	divps xmm3, xmm8


	; cmp r11, rcx						;verificar si es ultima fila de la imagen
	; je .cicloext

	.fin:
		pop rbp
		ret