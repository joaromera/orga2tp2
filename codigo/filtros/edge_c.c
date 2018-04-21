#include <stdio.h>
#include "../tp2.h"

void edge_c (unsigned char *src, unsigned char *dst, int width, int height, int src_row_size, int dst_row_size)
{

	// ~ completar

	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	for (int i_d = 0, i_s = 0; i_d < height; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < width; j_d++, j_s++) {
			uchar *p_d = (uchar*)&dst_matrix[i_d][j_d];
			uchar *p_s = (uchar*)&src_matrix[i_s][j_s];
			*p_d = *p_s;
		}
	}

}
