global temperature_asm

section .data
    div3: dq 3
section .text
;void temperature_asm(unsigned char *src,
;              unsigned char *dst,
;              int width,
;              int height,
;              int src_row_size,
;              int dst_row_size);

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size

temperature_asm:
    push rbp
	mov rbp, rsp
    pxor xmm8, xmm8
	movdqu xmm8, [div3]
    
    mov eax, edx
	mul ecx						;[EDX:EAX]
	mov ecx, edx
	shl rcx, 32
	add ecx, eax
	shr rcx, 2
    
    .ciclo:
        movdqu xmm0, [rdi]
        movdqu xmm1, xmm0       ; xmm =|p4|p3|p2|p1

        pxor xmm7, xmm7
        punpcklbw xmm0, xmm7    ; xmm0=|p2|p1
        punpckhbw xmm1, xmm7    ; xmm1=|p4|p3

        psllw xmm1, 32

        phaddw xmm0, xmm0
        phaddw xmm1, xmm1

        phaddd xmm0, xmm0
        phaddd xmm1, xmm1
        
        cvtdq2ps xmm0, xmm0
        cvtdq2ps xmm1, xmm1
        
        divps xmm0, xmm8
        divps xmm1, xmm8
        
        psrlw xmm1, 32
        packuswb xmm0, xmm1
      
        movdqu [rsi], xmm0
        add rsi, 16
		add rdi, 16
		loop .ciclo

    pop rbp
    ret
