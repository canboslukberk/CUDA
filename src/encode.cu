#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define SMAX 102
#define LMAX 15360
#include	<time.h>
#include	<sys/time.h>

//	Kernel	definition
// Decoder function which works on GPU side.
__global__ void decoder(char *cudalist, char *edited){

    int i = threadIdx.x;
    int j = blockIdx.x;
        if(*(cudalist+j*SMAX+i) == ','){
            *(edited+j*SMAX+i+1) = *(cudalist+j*SMAX+i+1);
            }
}
//Decoder function that works on CPU side.
void CpuDecoder(char *list, char *output){
    int i,j;
    for(i=0; i<LMAX; i++){
        for(j=0; j<SMAX; j++){
            if(*(list+i*SMAX+j) == ','){
               *(output+i*SMAX+j+1) = *(list+i*SMAX+j+1);
                //printf("%c", *(list+i*SMAX+j+1));
            }
        }
    }
}
//Prints the list. I used this function to test if my lists are empty or not.
void print(char *list){
    int i,j;
    for(i=0; i<LMAX; i++){
        for(j=0; j<SMAX-1; j++){
            printf("%c", *(list+i*SMAX+j));
        }
        printf("\n");
    }
}
//Writes "output" to the "decoded.txt" 
void writeToFile(char *list){

    FILE *fptr;
    if ((fptr = fopen("encoded.txt", "a+")) == NULL){
        printf("Error! opening file");
        exit(1);
    }
    int i;
    for (i=0; i<SMAX*LMAX; i++){
        if(*(list+i) != 0){
            fprintf(fptr,"%c",*(list+i));
        }
     }
    fclose(fptr);
}

//Read input file.
void readFromFile(char *list){
    int i = 0;
    char c[SMAX];
    FILE *fptr;
    if ((fptr = fopen("encodedfile.txt", "r")) == NULL){
        printf("Error! opening file");
        exit(1);
    }
    while(fgets(c, SMAX, fptr) != NULL){
        strtok(c, "\n");
        strcpy((list + i*SMAX), c);
        i++;
    }
    fclose(fptr);
}



int main()
{
    cudaDeviceReset();
    char *list;
    char *cudalist;
    char *output;
    char *edited;

    list = (char*)malloc(LMAX * SMAX * sizeof(char));
    output = (char*)malloc(LMAX * SMAX * sizeof(char));

    cudaMalloc((void **)&cudalist, LMAX * SMAX * sizeof(char));
    readFromFile(list);
    cudaMalloc((void **)&edited, LMAX * SMAX * sizeof(char));


    struct	timeval	stop,	start;
    gettimeofday(&start,	NULL);
    cudaMemcpy(cudalist, list, (LMAX * SMAX * sizeof(char)), cudaMemcpyHostToDevice);
    decoder<<<LMAX,SMAX-2>>>(cudalist, edited);
    cudaMemcpy(output, edited, (LMAX * SMAX * sizeof(char)), cudaMemcpyDeviceToHost);
    gettimeofday(&stop,	NULL);
    float	elapsed	=	(stop.tv_sec	- start.tv_sec)	*	1000.0f	+	(stop.tv_usec	- start.tv_usec)	/	1000.0f;
    printf("Code	executed on GPU	in	%f	milliseconds.\n",	elapsed);


    gettimeofday(&start,	NULL);
    CpuDecoder(list, output);
    gettimeofday(&stop,	NULL);
    elapsed	=	(stop.tv_sec	- start.tv_sec)	*	1000.0f	+	(stop.tv_usec	- start.tv_usec)	/	1000.0f;
    printf("Code	executed on CPU	in	%f	milliseconds.\n",	elapsed);



    writeToFile(output);
    free(list);
    free(output);
    cudaFree(cudalist);
    cudaFree(edited);
    return -1;
}



