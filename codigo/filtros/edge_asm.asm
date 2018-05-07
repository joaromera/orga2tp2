; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

section .data
	mask1: db 0, 1, 2, 3, 8, 5, 10, 7, 4 ,9 ,6, 11, 12, 13, 14, 15
DEFAULT REL

section .text
global edge_asm
edge_asm:									;NOTAR QUE LOS PIXELES MIDEN 1 BYTE
	push rbp
	mov rbp, rsp

	shr rdx, 4								;voy a procesar de a 16 pixeles/bytes
	xor r10, r10							;r10 y r11 son contadores para iterar		
	xor r11, r11

	;COPIO PRIMER FILA SIN MODIFICAR
	.primerFila:	
		cmp r11, rdx						;verificar si es la ultima columna de la fila
		je .edge
		movdqu xmm0, [rdi]
		movdqu [rsi], xmm0
		add rsi, 16
		add rdi, 16
		inc r11
		jmp .primerFila

	.edge:
		mov eax, [rdi]
		pxor xmm2, xmm2
		pxor xmm1, xmm1
		pxor xmm0, xmm0
		movd xmm0, eax
		punpcklbw xmm0, xmm1
		movd xmm1, eax
		punpcklbw xmm1, xmm2
		pslldq xmm0, 8
		paddw xmm0, xmm1

		mov eax, [rdi+rdx]
		pxor xmm3, xmm3
		pxor xmm2, xmm2
		pxor xmm1, xmm1
		movd xmm1, eax
		punpcklbw xmm1, xmm2
		movd xmm2, eax
		punpcklbw xmm2, xmm3
		pslldq xmm1, 8
		paddw xmm1, xmm2

	pop rbp
	ret