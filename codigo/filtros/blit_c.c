#include <stdio.h>
void blit_c (unsigned char *src, unsigned char *dst, int w, int h, int src_row_size, int dst_row_size, unsigned char *blit, int bw, int bh, int b_row_size) {

    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    unsigned char (*blit_matrix)[b_row_size]  = (unsigned char (*)[b_row_size])  blit;

    for(int i = 0; i < h; i++){

        for(int j = 0; j < w * 4; j += 4){

            dst_matrix[i][j]     = src_matrix[i][j];
            dst_matrix[i][j + 1] = src_matrix[i][j + 1];
            dst_matrix[i][j + 2] = src_matrix[i][j + 2];
            dst_matrix[i][j + 3] = src_matrix[i][j + 3];

        }
    }


    for(int i = bh - h; i < h; i++){

        for(int j = bw - w; j < w * 4; j += 4){
            if(blit_matrix[i][j] == 255 && blit_matrix[i][j + 1] == 0
               && blit_matrix[i][j + 2] == 255){
                dst_matrix[i][j] = src_matrix[i][j];
                dst_matrix[i][j + 1] = src_matrix[i][j + 1];
                dst_matrix[i][j + 2] = src_matrix[i][j + 2];
                dst_matrix[i][j + 3] = src_matrix[i][j + 3];
            }
            else{
                dst_matrix[i][j]     = blit_matrix[i][j];
                dst_matrix[i][j + 1] = blit_matrix[i][j + 1];
                dst_matrix[i][j + 2] = blit_matrix[i][j + 2];
                dst_matrix[i][j + 3] = blit_matrix[i][j + 3];

            }

        }

    }


}
