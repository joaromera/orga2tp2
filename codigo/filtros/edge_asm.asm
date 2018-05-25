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
global edge_asm
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
	movdqu xmm14, [maskAltaBaja]
	movdqu xmm15, [maskMedio]
	mov r13, rdx
	shr r13, 2								;voy a procesar de a 16 pixeles/bytes
	xor r10, r10							;r10 y r11 son contadores para iterar		
	xor r11, r11
	mov r9, rdx
	neg r9
	xor r14, r14

	;COPIO PRIMER FILA SIN MODIFICAR
	inc r10

	.primerFila:	
		cmp r14, r13						;verificar si es la ultima columna de la fila
		je .edge
		movdqu xmm0, [rdi]
		pslldq xmm0, 12
		psrldq xmm0, 12
		movd r8d, xmm0
		mov [rsi], r8d
		add rsi, 4
		add rdi, 4
		inc r14
		jmp .primerFila

	.edge:
		cmp r11, rdx
		je .proximaFila

		dec rdx

		cmp r11, rdx
		jge .ultimoPixel
		inc rdx

		mov eax, [rdi]
		cmp r11, 0
		je .primerPixel

		.continuarEdge:
		pxor xmm2, xmm2
		pxor xmm1, xmm1
		pxor xmm0, xmm0
		movd xmm0, eax
		punpcklbw xmm0, xmm1
		movd xmm1, eax
		punpcklbw xmm1, xmm2
		pslldq xmm0, 8
		paddw xmm0, xmm1			;xmm0 parte del medio

		mov eax, [rdi + rdx]
		pxor xmm3, xmm3
		pxor xmm2, xmm2
		pxor xmm1, xmm1
		movd xmm1, eax
		punpcklbw xmm1, xmm2
		movd xmm2, eax
		punpcklbw xmm2, xmm3
		pslldq xmm1, 8
		paddw xmm1, xmm2			;xmm1 parte baja de la matriz

		mov eax, [rdi + r9]
		pxor xmm4, xmm4
		pxor xmm3, xmm3
		pxor xmm2, xmm2
		movd xmm2, eax
		punpcklbw xmm2, xmm3
		movd xmm3, eax
		punpcklbw xmm3, xmm4
		pslldq xmm2, 8
		paddw xmm2, xmm3			;xmm2 parte alta de la matriz

		psrlw xmm2, 1				;divido por 2 a xmm2 y xmm1
		psrlw xmm1, 1

		pshuflw xmm0, xmm0, 10010000b
		pshufhw xmm0, xmm0, 11100101b

		pshuflw xmm1, xmm1, 10010000b
		pshufhw xmm1, xmm1, 11100101b

		pshuflw xmm2, xmm2, 10010000b
		pshufhw xmm2, xmm2, 11100101b

		psrlq xmm0, 16
		psrlq xmm1, 16
		psrlq xmm2, 16

		psllq xmm0, 16
		psllq xmm1, 16
		psllq xmm2, 16

		pmullw xmm2, xmm14			;multiplico xmm2 por los valores de la matriz
		pmullw xmm1, xmm14			;hago lo mismo para xmm1
		pmullw xmm0, xmm15			;hago lo mismo para xmm0
									
		paddw xmm1, xmm2
		paddw xmm0, xmm1			;tengo la suma de los valores en xmm0

		phaddw xmm0, xmm0
		phaddw xmm0, xmm0			;hago la suma de todas las componentes

		packuswb xmm0,xmm0
		pxor xmm2, xmm2
		punpckhbw xmm0, xmm2

		pshuflw xmm0, xmm0, 00000000b
		pshufhw xmm0, xmm0, 01010101b

		psrlq xmm0, 48
		movd eax, xmm0
		mov [rsi], al

		psrldq xmm0, 8

		movd eax, xmm0
		inc rsi
		mov [rsi], al

		inc rsi
		add rdi, 2

		add r11, 2

		jmp .edge

		.primerPixel:
			inc r11
			xor r12, r12
			mov r12b, [rdi]
			mov [rsi], r12b
			inc rsi
			jmp .continuarEdge

		.ultimoPixel:
			inc r11
			inc rdx
			xor r12, r12
			inc rdi
			mov r12b, [rdi]
			mov [rsi], r12b
			inc rsi
			inc rdi	
			jmp .edge

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
	
