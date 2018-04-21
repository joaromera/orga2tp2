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

section .text

ondas_asm:
	;; TODO: Implementar

	push rbp
	mov rbp, rsp
	sub rsp, 8

	push qword [rbp + 16]
	call ondas_c
	add rsp, 8

	add rsp, 8
	pop rbp

	ret
