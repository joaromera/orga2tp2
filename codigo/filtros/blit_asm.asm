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
    align 16 

    mask_0_255_0_255: db 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 3, 255



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

	movdqu xmm1, [mask_0_255_0_255]; xmm1=|0 255 0 255|0 255 0 255|0 255 0 255|0 255 0 255|
	pxor xmm2, xmm2; xmm2=|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|
	
	mov rbx, [rbp+8]; rbx= blit

	.ciclo:
		movdqu xmm0, [rdi]; xmm0= |p4|p3|p2|p1|

			;/** comparacion cpm 255 0 255**//
							;levantamos imgen blit	
			
			movdqu xmm3, [rbx] ; xmm3=|b4|b3|b2|b1|
			
			movdqu xmm4, xmm1; xmm4 =|0 255 0 255|0 255 0 255|0 255 0 255|0 255 0 255| 		
			pcmpeqb	xmm4, xmm3; xmm1 =|||||
			pand xmm4, xmm3; xmm4 = ||||| 	 	






















		movdqu [rsi], xmm4
		add rsi, 16
		add rdi, 16
		loop .ciclo
	
	pop rbp
	ret
