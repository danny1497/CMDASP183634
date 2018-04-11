#! /bin/bash
#
#PBS -l walltime=00:10:00
#PBS -l nodes=1:ppn=28
#PBS -W group_list=newriver
#PBS -q open_q
#PBS -j oe

cd $PBS_O_WORKDIR

module purge
module load gcc openmpi

make

for nums in `seq 1 28`
do
	mpiexec -n $nums main;
done;

