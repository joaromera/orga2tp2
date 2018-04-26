;void blit_c (
;	unsigned char *src,
;	unsigned char *dst,
;	int w,
;	int h,
;	int src_row_size,
;	int dst_row_size, 
;	unsigned char *blit,
;	int bw,
;	int bh,
;	int b_row_size
;	);

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = w
; 	rcx = h
; 	r8 = src_row_size
; 	r9 = dst_row_size
;	pila_1 = [rbp+8]  = blit 
;   pila_2 = [rbp+16] = bw
;	pila_3 = [rbp+24] = bh
;	pila_4 = [rbp+32] = b_row_size

extern blit_c

section .data

DEFAULT REL

section .text

global blit_asm
blit_asm:
;COMPLETAR
	push rbp
	mov rbp, rsp
	
	mov eax, edx	; EAX= w				
	mul ecx			; [EDX:EAX]
	mov ecx, edx	;
	shl rcx, 32
	add ecx, eax	; ECX = w*h
					;contador para procesar de a 4 pixeles
	shr rcx, 2		; RCX = W*H/4 
	.ciclo:
		movdqu xmm0, [rdi]; xmm0= |p4|p3|p2|p1|




		movdqu [rsi], xmm4
		add rsi, 16
		add rdi, 16
		loop .ciclo
	
	pop rbp
	ret
