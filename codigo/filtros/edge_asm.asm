; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = rax = width
; 	rcx = rbx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

section .data
DEFAULT REL

section .text
global edge_asm
edge_asm:									;NOTAR QUE LOS PIXELES MIDEN 1 BYTE
	push rbp
	mov rbp, rsp

	mov rax, rdx
	shr rax, 4
	mov rbx, rcx

	xor r10, r10							;r10 y r11 son contadores para iterar		
	xor r11, r11

	;COPIO PRIMER FILA SIN MODIFICAR
	.primerFila:	
		cmp r11, rax						;verificar si es la ultima columna de la fila
		je .edge
		movdqu xmm0, [rdi]
		movdqu [rsi], xmm0
		add rsi, 16
		add rdi, 16
		inc r11
		jmp .primerFila

	.edge:
	inc r10
	dec rbx									;la ultima fila no se procesa
	dec rdx									;el ultimo pixel se copia sin procesar
	
	.cicloExt:
		cmp r10, rbx						;verificar si es ultima fila de la imagen
		je .fin
		xor r11, r11						;copio primer byte sin modificar
		xor rax, rax
		mov al, [rdi]
		mov [rsi], al
		add rsi, 1
		add rdi, 1
		inc r11

	.cicloInt:
		cmp r11, rdx						;verificar si es la ultima columna de la fila
		je .ultimoPixelFila
		mov al, [rdi]
		mov byte [rsi], 0					;pongo en negro para probar
		add rsi, 1
		add rdi, 1
		inc r11
		jmp .cicloInt

	.ultimoPixelFila:
		mov al, [rdi]
		mov [rsi], al
		add rsi, 1
		add rdi, 1
		
	.proxFila:
		inc r10
		jmp .cicloExt

	.fin:
		;COPIO ULTIMA FILA SIN MODIFICAR
		xor r11, r11
		mov rax, rdx
		shr rax, 4
		.ultimaFila:	
			cmp r11, rax						
			je .return
			movdqu xmm0, [rdi]
			movdqu [rsi], xmm0
			add rsi, 16
			add rdi, 16
			inc r11
			jmp .ultimaFila

	.return:
		pop rbp
		ret