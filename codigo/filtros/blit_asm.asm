; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = w
; 	rcx = h
; 	r8 = src_row_size
; 	r9 = dst_row_size
;	pila_1 = [rbp+8]  = blit 
;   pila_2 = [rbp+16] = blit width
;	pila_3 = [rbp+24] = blit height
;	pila_4 = [rbp+32] = b_row_size
extern blit_c
section .data
    align 16
	maskMagenta: db 255	 ,0, 255, 255, 255, 0, 255, 255, 255, 0, 255, 255, 255, 0, 255, 255
	maskCero: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 
DEFAULT REL
section .text
global blit_asm
blit_asm:
	push rbp
	mov rbp, rsp

	movdqu xmm15, [maskMagenta]
	movdqu xmm13, [maskCero]
	mov rax, rdx
	mov rbx, rcx
	mov r15, [rbp+16]

	sub rbx, [rbp+32]
	shr rax, 2

	xor r10, r10						
	xor r11, r11


	;COPIO FILAS SIN MODIFICAR HASTA H - BH
	.precicloext:
		xor r11, r11
		cmp r10, rbx						;verificar si es ultima fila de la imagen antes del blit
		je .blit

	.precicloint:
		cmp r11, rax						;verificar si es la ultima columna de la fila
		je .preproxfila
		movdqu xmm0, [rdi]
		movdqu [rsi], xmm0
		add rsi, 16
		add rdi, 16
		inc r11
		jmp .precicloint

	.preproxfila:
		inc r10
		jmp .precicloext


	;INTRODUZCO BLIT
	.blit:
		mov rax, rdx
		sub rax, [rbp+24]
		shr rax, 2
		shr rdx, 2
		
	.cicloext:
		xor r11, r11
		cmp r10, rcx						;verificar si es ultima fila de la imagen
		je .fin

	.cicloint:
		cmp r11, rax						;verificar si es la ultima columna de la fila
		je .insertblit
		movdqu xmm0, [rdi]
		movdqu [rsi], xmm0
		add rsi, 16
		add rdi, 16
		inc r11
		jmp .cicloint

	.proxfila:
		inc r10
		jmp .cicloext

	.insertblit:
		cmp r11, rdx
		je .proxfila
		movdqu xmm0, [rdi]
		movdqu xmm14, [r15]
		pcmpeqd xmm15, xmm14   ; filtro los valores color magenta
		movdqu xmm12, xmm15	   ; paso la mascara a xmm12
		pcmpeqd xmm15, xmm13   ; filtro los valores que no son magenta
		pand xmm12, xmm0       ; Me quedo con los velores de xmm0 que tengo que poner en la imagen
		pand xmm15, xmm14      ; Me quedo con los valores de blit que tengo que poner en la imagen
		por xmm15, xmm12 	   ; Junto los dos valores en xmm15
		movdqu [rsi], xmm15	   ; Copio todo a dst
		movdqu xmm15, [maskMagenta]
		movdqu xmm13, [maskCero]
		add r15, 16
		add rsi, 16
		add rdi, 16
		inc r11
		jmp .insertblit

	.fin:
		pop rbp
		ret
