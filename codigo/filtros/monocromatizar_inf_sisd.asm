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

global monocromatizar_inf_sisd

section .data

section .text

monocromatizar_inf_sisd:
	push rbp
	mov rbp, rsp
	mov eax, edx
	mul ecx						;[EDX:EAX]
	mov ecx, edx
	shl rcx, 32
	add ecx, eax
	xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

	.ciclo:
        mov r10d, [rdi]
        
        mov r11b, r10b          ;byte más bajo en r11b
                
        mov r12w, r10w
        shr r12w, 8             ;segundo byte más bajo en r12b

        mov r13d, r10d
        shl r13d, 8
        shr r13d, 24            ;tercer byte más bajo en r13b

        shr r10d, 24            ;cuarto byte más bajo en r10b

        ;comparaciones
            mov r14b, r11b
        .compararSeg:
            cmp r12b, r14b
            jg .mayorSeg
        .compararTer:
            cmp r13b, r14b
            jg .mayorTer
            jmp .copiar
        .mayorSeg:
            mov r14b, r12b
            jmp .compararTer
        .mayorTer:
            mov r14b, r13b
        
        .copiar:
            mov r15b, r14b
            shl r15d, 8
            add r15b, r14b
            shl r15d, 8
            add r15b, r14b
            shl r15d, 8
            add r15b, r14b

            mov [rsi], r15d
            xor r15, r15
            xor r14, r14

		add rsi, 4
		add rdi, 4
		loop .ciclo

	pop rbp
	ret