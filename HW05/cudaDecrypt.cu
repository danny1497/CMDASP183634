#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>

#include "cuda.h"
#include "functions.c"

__device__ int cudamodprod(unsigned int a, unsigned int b, unsigned int p) {
  unsigned int za = a;
  unsigned int ab = 0;

  while (b > 0) {
    if (b%2 == 1) ab = (ab +  za) % p;
    za = (2 * za) % p;
    b /= 2;
  }
  return ab;
}

//compute a^b mod p safely
__device__ int cudamodExp(unsigned int a, unsigned int b, unsigned int p) {
  unsigned int z = a;
  unsigned int aExpb = 1;

  while (b > 0) {
    if (b%2 == 1) aExpb = cudamodprod(aExpb, z, p);
    z = cudamodprod(z, z, p);
    b /= 2;
  }
  return aExpb;
}

__global__ void findSecretKey(unsigned int *dx, unsigned int p, unsigned int g, unsigned int h) {

  int threadID = threadIdx.x;
  int blockID = blockIdx.x;
  int Nblock = blockDim.x;
  unsigned int id = threadID + (blockID*Nblock);
  //if(id<(*p-1)) {
    if (cudamodExp(g,id,p)==h) {
      dx[0]=id;
    }
  //}
}

int main (int argc, char **argv) {

  /* Part 2. Start this program by first copying the contents of the main function from 
     your completed decrypt.c main function. */

  /* Q4 Make the search for the secret key parallel on the GPU using CUDA. */
  
  //declare storage for an ElGamal cryptosytem
  unsigned int n, p, g, h, x;
  unsigned int Nints;
  int Nthreads = atoi(argv[1]);
  //get the secret key from the user
  printf("Enter the secret key (0 if unknown): "); fflush(stdout);
  char stat = scanf("%u",&x);

  printf("Reading file.\n");

  /* Q3 Complete this function. Read in the public key data from public_key.txt
    and the cyphertexts from messages.txt. */
  //FILE *pubKey,*msg;
  //unsigned int Nblocks;
  //unsigned int Nthreads,blocks;
  //FILE *pubKey = fopen("public_key.txt","r");
  //FILE *msg = fopen("message.txt","r");
	FILE *pubKey = fopen("bonus_public_key.txt","r");
  	FILE *msg = fopen("bonus_message.txt","r");
	
  fscanf(pubKey, "%u\n%u\n%u\n%u\n",&n,&p,&g,&h);
  //printf("n= %u, p = %u, g = %u, h = %u\n",n,p,g,h);
  fscanf(msg, "%u\n", &Nints);
  //printf("Nints  = %u\n", Nints);
  //unsigned int charsPerInt = (n-1)/8;
  unsigned int *Zmessage = (unsigned int *) malloc(Nints*sizeof(unsigned int));
  unsigned int *a = (unsigned int *) malloc(Nints*sizeof(unsigned int));

  for (unsigned int i = 0; i < Nints; i++) {
    fscanf(msg, "%u %u\n", &Zmessage[i],&a[i]);
    //printf("Zmessage = %u, a = %u\n",Zmessage[i],a[i]);
  }

  fclose(pubKey);
  fclose(msg);
  //unsigned int host = 0;
  //unsigned int *dx,*dp,*dg,*dh;
  /*cudaMalloc(&dx,sizeof(unsigned int));
	cudaMalloc(&dg,sizeof(unsigned int));
	cudaMalloc(&dh,sizeof(unsigned int));
	cudaMalloc(&dp,sizeof(unsigned int));
 	cudaMemcpy(dp,&g,sizeof(unsigned int),cudaMemcpyHostToDevice);
	cudaMemcpy(dg,&h,sizeof(unsigned int),cudaMemcpyHostToDevice);
	cudaMemcpy(dh,&p,sizeof(unsigned int),cudaMemcpyHostToDevice);
	*/

	// find the secret key
  /*
  if (x==0 || cudamodExp(g,x,p)!=h) {
    printf("Finding the secret key...\n");
    double startTime = clock();
    for (unsigned int i=0;i<p-1;i++) {
      if (cudamodExp(g,i+1,p)==h) {
        printf("Secret key found! x = %u \n", i+1);
        x=i+1;
      } 
    }*/
	double startTime = clock();
	//int thds = 1024;	
	//int Nblocks = (p-1+thds-1)/thds;
	unsigned int *host, *device;
	host = (unsigned int*) malloc(sizeof(unsigned int));
	cudaMalloc(&device,sizeof(unsigned int));
	int xloc = 1;
	int yloc = 1;
	int zloc = 1;	
	dim3 Block(Nthreads,yloc,zloc);
	dim3 Grid((p+Nthreads-xloc)/Nthreads,yloc,zloc);
	findSecretKey <<<Grid,Block>>>(device,p,g,h);
	cudaDeviceSynchronize();
	double endTime = clock();

  //if (x==0 || modExp(g,x,p)!=h) {
    //printf("Finding the secret key...\n");
  
  //double startTime = clock();   
  //Nthreads = 32;
  //Nblocks = (p-1)/32;
  //findSecretKey <<<Nblocks,thds>>>(dg,dh,dp,dx);
  //cudaDeviceSynchronize();
  //unsigned int size = sizeof(unsigned int);
  cudaMemcpy(host,device,sizeof(unsigned int), cudaMemcpyDeviceToHost);
  //double endTime = clock();
	x = host[0];
	ElGamalDecrypt(Zmessage,a,Nints,p,x);
	unsigned int charsPerInt = (n-1)/8;
	int buffer = 1024;
	unsigned int Nchars = Nints*charsPerInt;
	unsigned char *result = (unsigned char *) malloc(buffer*sizeof(unsigned char));
	convertZToString(Zmessage,Nints, result, Nchars);
	printf("Decrypted message: \"%s\"\n",result);
	//printf("\n");
  double totalTime = (endTime-startTime)/CLOCKS_PER_SEC;
  double work = (double) p;
  double throughput = work/totalTime;
  //printf("Secret key found! x %u \n", host);
  printf("Searching all keys took %g seconds, throughput was %g values tested per second.\n", totalTime, throughput);
	//}
  /*
	cudaFree(dg);
	cudaFree(dh);
	cudaFree(dp);
	cudaFree(dx);
	//}
	*/
	cudaFree(device);
	free(host);
	//free(Zmessage);
	//free(a);
	//free(result);
  //int buffer = 1024;
  //ElGamalDecrypt(Zmessage,a,Nints,p,x);
  //unsigned int Nchars = Nints*charsPerInt;
	/*int buffer = 1024;
	unsigned int temp = (n-1)/8;
  //unsigned int charsPerInt = temp/Nints;
	unsigned char *result = (unsigned char *) malloc(buffer*sizeof(unsigned char));
  ElGamalDecrypt(Zmessage,a,Nints,p,x);
  //unsigned int cpi = (n-1)/8;
  convertZToString(Zmessage,Nints,result,Nints*temp);
  printf("Decrypted message: \"%s\"\n",result);
  //cudaFree(device); 
  */return 0;
}
