section .data
DEFAULT REL
section .text
global blit_asm
	blit_asm:
		push rbp
		mov rbp, rsp
		mov eax, edx
		mul ecx						;[EDX:EAX]
		mov ecx, edx
		shl rcx, 32
		add ecx, eax
		shr rcx, 2
		
		.ciclo:
			movdqu xmm0, [rdi]
			movdqu [rsi], xmm0
			add rsi, 16
			add rdi, 16
			loop .ciclo

		pop rbp
	ret