#!/bin/bash
build="growth_cuda"
paramSize="small-connected"
runMainBranch="yes"
if [ $# -gt 0 ] ; then
   runMainBranch=$1
fi
paramFile="validation/test-$paramSize.xml"
useH5="yes"
outputType="h5"
if [ "$useH5" = "no" ] ; then
   outputType="xml"
fi
echo "Using parameter file: $paramFile"

if [ "$runMainBranch" = "yes"  ] ; then
git checkout refactor-stable-cuda
branchName="$(git symbolic-ref -q HEAD)"
branchName=${branchName##refs/heads/}
outputFile="$branchName-$paramSize-$build-output.$outputType"
rm -f $build
{ time make -B CUSEHDF5=$useH5 $build; } &> compileOutputRSC.txt
echo "Compilation Complete"
{ time "./$build" -o $outputFile -t $paramFile; } &> runtimeScreenOutputRSC.txt
echo "Simulation Complete"

fi

git checkout forward-map-refactor
branchName="$(git symbolic-ref -q HEAD)"
branchName=${branchName##refs/heads/}
outputFile="$branchName-$paramSize-$build-output.$outputType"
rm -f $build
{ time make -B CUSEHDF5=$useH5 $build; } &> compileOutputFMR.txt
echo "Compilation Complete"
{ time "./$build" -o $outputFile -t $paramFile; } &> runtimeScreenOutputFMR.txt
echo "Simulation Complete"

