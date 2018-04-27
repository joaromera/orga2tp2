#include <stdio.h>
#include "../tp2.h"

void edge_c (unsigned char *src, unsigned char *dst, int width, int height, int src_row_size, int dst_row_size)
{
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	for (int i_d = 0, i_s = 0; i_d < height; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < width; j_d++, j_s++) {
			uchar *p_d = (uchar*)&dst_matrix[i_d][j_d];
			uchar *p_s = (uchar*)&src_matrix[i_s][j_s];
			*p_d = *p_s;
		}
	}

	for (int i = 1; i < height - 1; i++) {
		for (int j = 1; j < width - 1; j++) {
			float m00 = src_matrix[i-1][j-1] * 0.5;
			float m01 = src_matrix[i-1][j] * 1;
			float m02 = src_matrix[i-1][j+1] * 0.5;
			float m10 = src_matrix[i][j-1] * 1;
			float m11 = src_matrix[i][j] * -6;
			float m12 = src_matrix[i][j+1] * 1;
			float m20 = src_matrix[i+1][j-1] * 0.5;
			float m21 = src_matrix[i+1][j] * 1;
			float m22 = src_matrix[i+1][j+1] * 0.5;

			float edge = m00+m01+m02+m10+m11+m12+m20+m21+m22;

			if (edge < 0) {
				edge = 0;
			} else if (edge > 255) {
				edge = 255;
			}
			dst_matrix[i][j] = (unsigned char) edge;
		}
	}
}
