; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

section .data
DEFAULT REL

section .text
global edge_asm
edge_asm:
	push rbp
	mov rbp, rsp
	
	xor r10, r10
	mov r10, rcx

	.primeraFila:
		mov ah, [rdi]
		mov [rsi], ah
		lea rdi, [rdi + 1]
		lea rsi, [rsi + 1]
		loop .primeraFila

	mov rcx, r10
	sub rdx, 2
	mov r11, rdx

	.interno:

		.ciclo:
			cmp rdx, 0
			je .proxFila
			mov ah, [rdi]
			mov byte [rsi], 0
			lea rdi, [rdi + 1]
			lea rsi, [rsi + 1]
			sub rdx, 1
			jmp .ciclo
	
		.proxFila:
			mov rdx, r11
			loop .interno

	.ultimaFila:
		pop rbp
		ret