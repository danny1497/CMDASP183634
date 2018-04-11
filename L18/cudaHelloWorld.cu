#include <stdio.h>
#include <stdlib.h>

#include "cuda.h"

// This is my DEVICE function
// __global__ means this function is visible to the host
__global__ void kernelHelloWorld() {

	int thread = threadIdx.x; //local thread number in a block
	int block =  blockIdx.x; //block nunmber 
		
	printf("Hello World %d of block %d!\n", thread, block);
	
}

int main(int argc, char** argv) {

	int Nblocks = 10; // Number of blocks 
	int Nthreads = 3; // Number of threads

	// run the function 'kernelHelloWorld' on the DEVICE
	kernelHelloWorld <<< Nblocks, Nthreads >>> ();

	// wait for the DEVICE function to complete before moving on
	cudaDeviceSynchronize();
	
	return 0;
		
}
