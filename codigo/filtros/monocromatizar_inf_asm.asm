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

extern monocromatizar_inf_c

global monocromatizar_inf_asm

section .text

monocromatizar_inf_asm:
	;; TODO: Implementar

	sub rsp, 8

	call monocromatizar_inf_c

	add rsp, 8

	ret
