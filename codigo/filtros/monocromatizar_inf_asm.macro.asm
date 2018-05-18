; void monocromatizar_inf_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int width,
; 	int height,
; 	int src_row_size,
; 	int dst_row_size
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

%macro repeticiones 0
		movdqu xmm0, [rdi]
		movdqu xmm4, xmm0
		movdqu xmm5, xmm0

		pshufb xmm4, xmm1
		pmaxub xmm4, xmm0			;primer maximo

		pshufb xmm5, xmm2			
		pmaxub xmm4, xmm5			;maximo de maximos
		pshufb xmm4, xmm3

		movdqu [rsi], xmm4
		add rsi, 16
		add rdi, 16
%endmacro


extern monocromatizar_inf_c

global monocromatizar_inf_asm

section .data
	mask1: db 1, 1, 1, 3, 5, 5, 5, 7, 9, 9, 9, 11, 13, 13, 13, 15
	mask2: db 2, 2, 2, 3, 6, 6, 6, 7, 10, 10, 10, 11, 14, 14, 14, 15
	mask3: db 0, 0, 0, 3, 4, 4, 4, 7, 8, 8, 8, 11, 12, 12, 12, 15

section .text

monocromatizar_inf_asm:
	;; TODO: Implementar
	push rbp
	mov rbp, rsp
	movdqu xmm1, [mask1]		;xmm1 <- mask1
	movdqu xmm2, [mask2]		;xmm2 <- mask2
	movdqu xmm3, [mask3]		;xmm3 <- mask3
	mov eax, edx
	mul ecx						;[EDX:EAX]
	mov ecx, edx
	shl rcx, 32
	add ecx, eax
	shr rcx, 18

	.ciclo:
		cmp rcx, 0
		je .fin
		%rep 65536
			repeticiones
		%endrep
		dec rcx
		jmp .ciclo

	; .ciclo:
	; 	movdqu xmm0, [rdi]
	; 	movdqu xmm4, xmm0
	; 	movdqu xmm5, xmm0

	; 	pshufb xmm4, xmm1
	; 	pmaxub xmm4, xmm0			;primer maximo

	; 	pshufb xmm5, xmm2			
	; 	pmaxub xmm4, xmm5			;maximo de maximos
	; 	pshufb xmm4, xmm3

	; 	movdqu [rsi], xmm4
	; 	add rsi, 16
	; 	add rdi, 16
	; 	loop .ciclo
	.fin:
		pop rbp
		ret