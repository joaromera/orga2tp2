; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = width
; 	rcx = height
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   rbp + 16 = x0
; 	rbp + 24 = y0


global ondas_asm

section .data
	maskShuf: db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
	mask1: times 4 dd 1
	mask2: dd 0, 1, 2, 3
	mask3: times 4 dd 0
	radio: times 4 dd 35.0
	wavelenght: times 4 dd 64.0
	pi: times 4 dd 3.1415
	todosdos: times 4 dd 2.0
	trainwidth: times 4 dd 3.4
	mask255: times 16 db 255


section .text

ondas_asm:
	push rbp
	mov rbp, rsp						;alineada
	push rbx
	push r9
	push r12
	push r13
	push r14
	push r15							;desalineada

	mov r9b, 255
	mov r15, 6
	mov r14, 120
	mov rbx, 5040
	shr rdx, 2

	movdqu xmm6, [pi]			;xmm6=|PI|PI|PI|PI| 
	movdqu xmm7, [todosdos]		;xmm7=|2.0|2.0|2.0|2.0|
	movdqu xmm8, [wavelenght]	;xmm8=|64.0|64.0|64.0|64.0|
	movdqu xmm9, [radio]		;xmm9=|35.0|35.0|35.0|35.0|
	movdqu xmm10, [mask1]		;xmm10=|1|1|1|1| para incrementar los indices empaquetados
	movdqu xmm11, [mask2]		;xmm11=|3|2|1|0| primeros indices para columnas
	movdqu xmm12, [mask3]		;xmm12=|0|0|0|0| indices para filas
	movdqu xmm15, [trainwidth]	;xmm15=|TRAINWIDTH|TRAINWIDTH|TRAINWIDTH|TRAINWIDTH|
	mov r12, [rbp + 16]			;r12=x0
	mov r13, [rbp + 24]			;r12=y0

	pxor xmm13, xmm13
	movq xmm13, r12				;xmm13=|0|0|0|x0|
	packusdw xmm13, xmm13		;xmm13=|0|0|0|x0|0|0|0|x0|
	packusdw xmm13, xmm13		;xmm13=|0 0 0 x0|0 0 0 x0|0 0 0 x0|0 0 0 x0|		                 ;xmm13 <- |x0|x0|x0|x0|

	pxor xmm14, xmm14			
	movq xmm14, r13				;xmm14=|0|0|0|y0|
	packusdw xmm14, xmm14		;xmm14=|0|0|0|y0|0|0|0|y0|
	packusdw xmm14, xmm14		;xmm14=|0 0 0 y0|0 0 0 y0|0 0 0 y0|0 0 0 y0|		;xmm13 <- |y0|y0|y0|y0|

	xor r10, r10				; r10=0 contador fila		
	xor r11, r11; 				; r11=0 contador columna

	.cicloext:
		xor r11, r11
		cmp r10, rcx						;verificar si es ultima fila de la imagen
		je .fin

			.cicloint:
			cmp r11, rdx						;verificar si es el ultimo pixel de la fila
			je .proxfila

				;CALCULO DE PROFUNDIDAD
				movdqu xmm3, xmm11					;xmm3=|x3|x2|x1|x0| 
				psubd xmm3, xmm13					;xmm3=|x3-x_0|x2-x_0|x1-x_0|x0-x_0|    				x - x0

				movdqu xmm4, xmm12					;xmm4=|0|0|0|0|
				psubd xmm4, xmm14					;xmm4=|0-y0|0-y0|0-y0|0-y0|						y - y0	
													;sabiendo dx3=3-x3,dx2=2-x2,dx1=1-x1, dx0=0-x0
				pmulld xmm3, xmm3					;xmm3=|dx3*dx3|dx2*dx2|dx1*dx1|dx0*dx0| 												dx*dx
				pmulld xmm4, xmm4					;xmm4=|dy3*dy3|dy2*dy2|dy1*dy1|dy0*dy0| 												dy*dy
													;dx*dx+dy*dy
				paddd xmm3, xmm4					;xmm3=|dx3*dx+dy3*dy3|...|dx0*dx0+dy0*dy0|
				 									; Convertimos de doble word integer a Flota
				cvtdq2ps xmm3, xmm3					;xmm3= Convertimos de doble word integer a Flota	
													;Sacamos raiz cuadrada a cada paquet dword, o sea (dx*dx+dy*dy)^(1/2)
				sqrtps xmm3, xmm3					;xmm3=|(dx3*dx3+dy3*d3)^(1/2)|...|(dx0*dx0+dy0*dy0)^(1/2)|
													;Calculo la distancia meno el radio, o sea (dx*dx+dy*dy)^(1/2) - RADIO 
													;xmm9=|RADIO|RADIO|RADIO|RADIO|
				subps xmm3, xmm9					;xmm3=|dxy3-RADIO|dxy2-RADIO|dxy1-RADIO|dxy0-RADIO| donde dxy es la distancia
													;xmm8=|WAVELENGTH|WAVELENGTH|WAVELENGTH|WAVELENGTH|
													; R <- ((dx*dx+dy*dy)^(1/2) - RADIO)/WAVELENGTH
				divps xmm3, xmm8					;xmm3=|R1|R2|R3|R3|	

				movdqu xmm7, xmm3					;xmm7=|R1|R2|R3|R3|
				movdqu xmm4, xmm3					;xmm4=|R1|R2|R3|R3|
													;El valor 0001b me permite activar la opcion de TRUNCAR c/u Float
													;Donde floor(R) es el el truncamiento
				roundps xmm3, xmm3, 0001b			;xmm3=xmm3=|floor(R3)|floor(R2)|floor(R1)|floor(R0)|

													;K  <- R - floor(R)
				subps xmm4, xmm3					;xmm4=|R3-floor(R3)|R2-floor(R2)|R1-floor(R1)|R0-floor(R0)|								
													;xmm4=|k3|k2|k1|k0|
													;xmm3 <- R
													;xmm4 <- K
				
				movdqu xmm5, xmm4					;xmm5=|k3|k2|k1|k0|
													;xmm10=|1|1|1|1| 
				paddd xmm10, xmm10					;xmm10=|2|2|2|2|
				cvtdq2ps xmm10, xmm10				;xmm10=|2|2|2|2| convierto a Floats
				mulps xmm5, xmm10					;xmm5=|k3*2|k2*2|k1*2|k0*2| multiplico por 2 a los k's
				divps xmm10, xmm10					;xmm10=|1.0|1.0|1.0|1.0| floats
				cvtps2dq xmm10, xmm10				;xmm10=|1|1|1|1| convertimos de floats a integer
													;xmm6=|PI|PI|PI|PI|
				mulps xmm5, xmm6 					;xmm5=|k3*2*PI|k2*2*PI|k1*2*PI|k0*2*PI|
													;Queremos realizar lo siguiente  t = k*2*PI-PI
				subps xmm5, xmm6					;xmm5=|k3*2*PI-PI|k2*2*PI-PI|k1*2*PI-PI|k0*2*PI-PI|
													;xmm5=|t3|t2|t1|t0| donde t=k*2*PI-PI 

				movdqu xmm3, xmm7					;xmm3=|R1|R2|R3|R3|
													;R/TRAINDIWTH
				divps xmm3, xmm15					;xmm3=|R3/TRAINDIWTH|R2/TRAINDIWTH|R1/TRAINDIWTH|R0/TRAINDIWTH|
													;R/TRAINDIWTH * R/TRAINDIWTH
				mulps xmm3, xmm3					;xmm3=|R3/TRAINDIWTH*R3/TRAINDIWTH|...|R0/TRAINDIWTH*R0/TRAINDIWTH|
				cvtdq2ps xmm10, xmm10				;xmm10=|1.0|1.0|1.0|1.0| convertimos de Integer a Floats
													;1 + (R/TRAINDIWTH * R/TRAINDIWTH)
				addps xmm3, xmm10					;xmm3=|1 + R1/TRAINDIWTH * R1/TRAINDIWTH)|...|1 + R0/TRAINDIWTH * R0/TRAINDIWTH)|
				movdqu xmm4, xmm10					;xmm4= |1.0|1.0|1.0|1.0|
													;A = 1 / 1 + (R/TRAINDIWTH * R/TRAINDIWTH)
				divps xmm4, xmm3					;xmm4=|A3|A2|A1|A0|
				cvtps2dq xmm10, xmm10				;xmm10=|1|1|1|1| Convierto de Floats a Integer

													;xmm5 <- t
													;xmm4 <- a

					;sin taylor
					movdqu xmm1, xmm5				;xmm1=|t3|t2|t1|t0|
													;calculamos x al cubo
					movdqu xmm3, xmm5				;xmm3=|t3|t2|t1|t0|
					mulps xmm3, xmm5				;xmm3=|t3^2|t2^2|t1^2|t0^2|
					mulps xmm3, xmm5				;xmm3=|t3^3|t2^3|t1^3|t0^3|	

					movq xmm2, r15					;xmm2=|0|0|0|6|
					packssdw xmm2, xmm2				;xmm2=|0|6|0|6|
					packssdw xmm2, xmm2				;xmm2=|6|6|6|6|
					cvtdq2ps xmm2, xmm2				;xmm2=|6|6|6|6| convierto de integer a Floats

					divps xmm3, xmm2				;xmm3=|(t3^3)/6|(t2^3)/|(t1^3)/6|(t0^3)/6|
					subps xmm1, xmm3				;xmm1=|t3-(t3^3)/6|t2-(t2^3)/|t1-(t1^3)/6|t0-(t0^3)/6|
													;calculamos x a la quinta
					movdqu xmm3, xmm5				;xmm3=|t3|t2|t1|t0|	
					mulps xmm3, xmm5				
					mulps xmm3, xmm5
					mulps xmm3, xmm5
					mulps xmm3, xmm5				;xmm3=|t3^5|t2^5|t1^5|t0^5|

					movq xmm2, r14					;xmm2=|0|0|0|120|
					packssdw xmm2, xmm2				;xmm2=|0|120|0|120|
					packssdw xmm2, xmm2				;xmm2=|120|120|120|120|
					cvtdq2ps xmm2, xmm2				;xmm2=|120|120|120|120| Convertimos de Integer a Float

					divps xmm3, xmm2				;xmm3=|t3^5/120|t2^5/120|t1^5/120|t0^5/120|
					addps xmm1, xmm3				;xmm1=|t3-(t3^3)/6+t3^5/120|...|t0-(t0^3)/6+t0^5/120|
													;calculamos t a la septima
					movdqu xmm3, xmm5				;xmm3=|t3|t2|t1|t0|	
					mulps xmm3, xmm5
					mulps xmm3, xmm5
					mulps xmm3, xmm5
					mulps xmm3, xmm5
					mulps xmm3, xmm5
					mulps xmm3, xmm5				;xmm3=|t3^7|t2^7|t1^7|t0^7|

					movq xmm2, rbx					;xmm2=|0|0|0|5040|
					packssdw xmm2, xmm2
					packssdw xmm2, xmm2
					cvtdq2ps xmm2, xmm2				;xmm2=|5040|5040|5040|5040|

					divps xmm3, xmm2				;xmm3=|t3^7/5040|t2^7/5040|t1^7/5040|t0^7/5040|
					subps xmm1, xmm3				;xmm1=|t3-(t3^3)/6+t3^5/120-t3^7/5040|...|t0-(t0^3)/6+t0^5/120-t0^7/5040|

					mulps xmm4, xmm1				;xmm4=|A3*(t3-t3^3/6+t3^5/120-t3^7/5040)|...|A1*(t0-t0^3/6+t0^5/120-t0^7/5040(|
					mulps xmm4, xmm8					;XMM4 <- PROFUNDIDAD * 64

			;agrego profundidad
			cvtps2dq xmm4, xmm4

			movdqu xmm7, xmm4
			pshufd xmm4, xmm4, 11111111b				;me quedo con el primero

			pxor xmm3, xmm3

			movdqu xmm1, [rdi]							;levanto imagen
			movdqu xmm0, xmm1
			punpckhbw xmm1, xmm3						;desempaqueto imagen
			movdqu xmm2, xmm1
			punpckhwd xmm1, xmm3
			punpcklwd xmm2, xmm3
			paddd xmm1, xmm4
			movdqu xmm4, xmm7
			pshufd xmm4, xmm4, 10101010b
			paddd xmm2, xmm4
			packssdw xmm2,xmm1
			movdqu xmm5, xmm2
			
			movdqu xmm1, xmm0
			punpcklbw xmm1, xmm3
			movdqu xmm2, xmm1
			punpckhwd xmm1, xmm3
			punpcklwd xmm2, xmm3
			movdqu xmm4, xmm7
			pshufd xmm4, xmm4, 01010101b
			paddd xmm1, xmm4
			movdqu xmm4, xmm7
			pshufd xmm4, xmm4, 00000000b
			paddd xmm2, xmm4
			packssdw xmm2,xmm1
			packuswb xmm2,xmm5

			psrld xmm0, 24
			pslld xmm0, 24
			
			por xmm2, xmm0
			
			movdqu [rsi], xmm2


			add rsi, 16
			add rdi, 16
			inc r11
			paddd xmm11, xmm10
			paddd xmm11, xmm10
			paddd xmm11, xmm10
			paddd xmm11, xmm10 
			jmp .cicloint

		.proxfila:
			inc r10
			paddd xmm12, xmm10
			movdqu xmm11, [mask2]
			jmp .cicloext
	
	.fin:
		pop r15
		pop r14
		pop r13
		pop r12
		pop r9
		pop rbx
		pop rbp
		ret
