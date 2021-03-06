/*
 * AllSpikingSynapses.cu
 *
 */

#include "AllSpikingSynapses.h"
#include "Book.h"

/*
 *  Allocate GPU memories to store all synapses' states,
 *  and copy them from host to GPU memory.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::allocSynapseDeviceStruct( void** allSynapsesDevice, const SimulationInfo *sim_info ) {
        allocSynapseDeviceStruct( allSynapsesDevice, sim_info->totalNeurons, sim_info->maxSynapsesPerNeuron );
}

/*
 *  Allocate GPU memories to store all synapses' states,
 *  and copy them from host to GPU memory.
 *
 *  @param  allSynapsesDevice     Reference to the allSynapses struct on device memory.
 *  @param  num_neurons           Number of neurons.
 *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
 */
void AllSpikingSynapses::allocSynapseDeviceStruct( void** allSynapsesDevice, int num_neurons, int maxSynapsesPerNeuron ) {
        AllSpikingSynapses allSynapses;

        allocDeviceStruct( allSynapses, num_neurons, maxSynapsesPerNeuron );

        HANDLE_ERROR( cudaMalloc( allSynapsesDevice, sizeof( AllSpikingSynapses ) ) );
        HANDLE_ERROR( cudaMemcpy ( *allSynapsesDevice, &allSynapses, sizeof( AllSpikingSynapses ), cudaMemcpyHostToDevice ) );
}

/*
 *  Allocate GPU memories to store all synapses' states,
 *  and copy them from host to GPU memory.
 *  (Helper function of allocSynapseDeviceStruct)
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  num_neurons           Number of neurons.
 *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
 */
void AllSpikingSynapses::allocDeviceStruct( AllSpikingSynapses &allSynapses, int num_neurons, int maxSynapsesPerNeuron ) {
        BGSIZE max_total_synapses = maxSynapsesPerNeuron * num_neurons;

        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.destNeuronIndex, max_total_synapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.W, max_total_synapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.summationPoint, max_total_synapses * sizeof( BGFLOAT* ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.sourceNeuronIndex, max_total_synapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.psr, max_total_synapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.decay, max_total_synapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.total_delay, max_total_synapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.delayQueue, max_total_synapses * sizeof( uint32_t ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.delayIdx, max_total_synapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.ldelayQueue, max_total_synapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.type, max_total_synapses * sizeof( synapseType ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.tau, max_total_synapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.in_use, max_total_synapses * sizeof( bool ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allSynapses.synapse_counts, num_neurons * sizeof( BGSIZE ) ) );
}

/*
 *  Delete GPU memories.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::deleteSynapseDeviceStruct( void* allSynapsesDevice ) {
        AllSpikingSynapses allSynapses;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allSynapsesDevice, sizeof( AllSpikingSynapses ), cudaMemcpyDeviceToHost ) );

        deleteDeviceStruct( allSynapses );

        HANDLE_ERROR( cudaFree( allSynapsesDevice ) );
}

/*
 *  Delete GPU memories.
 *  (Helper function of deleteSynapseDeviceStruct)
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 */
void AllSpikingSynapses::deleteDeviceStruct( AllSpikingSynapses& allSynapses ) {
        HANDLE_ERROR( cudaFree( allSynapses.destNeuronIndex ) );
        HANDLE_ERROR( cudaFree( allSynapses.W ) );
        HANDLE_ERROR( cudaFree( allSynapses.summationPoint ) );
        HANDLE_ERROR( cudaFree( allSynapses.sourceNeuronIndex ) );
        HANDLE_ERROR( cudaFree( allSynapses.psr ) );
        HANDLE_ERROR( cudaFree( allSynapses.decay ) );
        HANDLE_ERROR( cudaFree( allSynapses.total_delay ) );
        HANDLE_ERROR( cudaFree( allSynapses.delayQueue ) );
        HANDLE_ERROR( cudaFree( allSynapses.delayIdx ) );
        HANDLE_ERROR( cudaFree( allSynapses.ldelayQueue ) );
        HANDLE_ERROR( cudaFree( allSynapses.type ) );
        HANDLE_ERROR( cudaFree( allSynapses.tau ) );
        HANDLE_ERROR( cudaFree( allSynapses.in_use ) );
        HANDLE_ERROR( cudaFree( allSynapses.synapse_counts ) );

        // Set count_neurons to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        allSynapses.count_neurons = 0;
}

/*
 *  Copy all synapses' data from host to device.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::copySynapseHostToDevice( void* allSynapsesDevice, const SimulationInfo *sim_info ) { // copy everything necessary
        copySynapseHostToDevice( allSynapsesDevice, sim_info->totalNeurons, sim_info->maxSynapsesPerNeuron );
}

/*
 *  Copy all synapses' data from host to device.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  num_neurons           Number of neurons.
 *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
 */
void AllSpikingSynapses::copySynapseHostToDevice( void* allSynapsesDevice, int num_neurons, int maxSynapsesPerNeuron ) { // copy everything necessary
        AllSpikingSynapses allSynapses;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allSynapsesDevice, sizeof( AllSpikingSynapses ), cudaMemcpyDeviceToHost ) );

        copyHostToDevice( allSynapsesDevice, allSynapses, num_neurons, maxSynapsesPerNeuron );
}

/*
 *  Copy all synapses' data from host to device.
 *  (Helper function of copySynapseHostToDevice)
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  num_neurons           Number of neurons.
 *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
 */
void AllSpikingSynapses::copyHostToDevice( void* allSynapsesDevice, AllSpikingSynapses& allSynapses, int num_neurons, int maxSynapsesPerNeuron ) { // copy everything necessary 
        BGSIZE max_total_synapses = maxSynapsesPerNeuron * num_neurons;

        allSynapses.maxSynapsesPerNeuron = maxSynapsesPerNeuron;
        allSynapses.total_synapse_counts = total_synapse_counts;
        allSynapses.count_neurons = count_neurons;
        HANDLE_ERROR( cudaMemcpy ( allSynapsesDevice, &allSynapses, sizeof( AllSpikingSynapses ), cudaMemcpyHostToDevice ) );

        // Set count_neurons to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        allSynapses.count_neurons = 0;

        HANDLE_ERROR( cudaMemcpy ( allSynapses.synapse_counts, synapse_counts,
                        num_neurons * sizeof( BGSIZE ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.destNeuronIndex, destNeuronIndex,
                max_total_synapses * sizeof( int ),  cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.W, W,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.sourceNeuronIndex, sourceNeuronIndex,
                max_total_synapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.psr, psr,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.decay, decay,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.total_delay, total_delay,
                max_total_synapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.delayQueue, delayQueue,
                max_total_synapses * sizeof( uint32_t ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.delayIdx, delayIdx,
                max_total_synapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.ldelayQueue, ldelayQueue,
                max_total_synapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.type, type,
                max_total_synapses * sizeof( synapseType ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.tau, tau,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allSynapses.in_use, in_use,
                max_total_synapses * sizeof( bool ), cudaMemcpyHostToDevice ) );
}

/*
 *  Copy all synapses' data from device to host.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::copySynapseDeviceToHost( void* allSynapsesDevice, const SimulationInfo *sim_info ) {
        // copy everything necessary
        AllSpikingSynapses allSynapses;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allSynapsesDevice, sizeof( AllSpikingSynapses ), cudaMemcpyDeviceToHost ) );

        copyDeviceToHost( allSynapses, sim_info );
}

/*
 *  Copy all synapses' data from device to host.
 *  (Helper function of copySynapseDeviceToHost)
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  num_neurons           Number of neurons.
 *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
 */
void AllSpikingSynapses::copyDeviceToHost( AllSpikingSynapses& allSynapses, const SimulationInfo *sim_info ) {
        int num_neurons = sim_info->totalNeurons;
        BGSIZE max_total_synapses = sim_info->maxSynapsesPerNeuron * num_neurons;

        HANDLE_ERROR( cudaMemcpy ( synapse_counts, allSynapses.synapse_counts,
                num_neurons * sizeof( BGSIZE ), cudaMemcpyDeviceToHost ) );
        maxSynapsesPerNeuron = allSynapses.maxSynapsesPerNeuron;
        total_synapse_counts = allSynapses.total_synapse_counts;
        count_neurons = allSynapses.count_neurons;

        // Set count_neurons to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        allSynapses.count_neurons = 0;

        HANDLE_ERROR( cudaMemcpy ( destNeuronIndex, allSynapses.destNeuronIndex,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( W, allSynapses.W,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( sourceNeuronIndex, allSynapses.sourceNeuronIndex,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( psr, allSynapses.psr,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( decay, allSynapses.decay,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( total_delay, allSynapses.total_delay,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( delayQueue, allSynapses.delayQueue,
                max_total_synapses * sizeof( uint32_t ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( delayIdx, allSynapses.delayIdx,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( ldelayQueue, allSynapses.ldelayQueue,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( type, allSynapses.type,
                max_total_synapses * sizeof( synapseType ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( tau, allSynapses.tau,
                max_total_synapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( in_use, allSynapses.in_use,
                max_total_synapses * sizeof( bool ), cudaMemcpyDeviceToHost ) );
}

/*
 *  Get synapse_counts in AllSynapses struct on device memory.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::copyDeviceSynapseCountsToHost(void* allSynapsesDevice, const SimulationInfo *sim_info)
{
        AllSpikingSynapses allSynapses;
        int neuron_count = sim_info->totalNeurons;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allSynapsesDevice, sizeof( AllSpikingSynapses ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( synapse_counts, allSynapses.synapse_counts, neuron_count * sizeof( BGSIZE ), cudaMemcpyDeviceToHost ) );

        // Set count_neurons to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
       allSynapses.count_neurons = 0;
}

/* 
 *  Get summationCoord and in_use in AllSynapses struct on device memory.
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  sim_info           SimulationInfo to refer from.
 */
void AllSpikingSynapses::copyDeviceSynapseSumIdxToHost(void* allSynapsesDevice, const SimulationInfo *sim_info)
{
        AllSpikingSynapses allSynapses;
        BGSIZE max_total_synapses = sim_info->maxSynapsesPerNeuron * sim_info->totalNeurons;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allSynapsesDevice, sizeof( AllSpikingSynapses ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( destNeuronIndex, allSynapses.destNeuronIndex,
                max_total_synapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( in_use, allSynapses.in_use,
                max_total_synapses * sizeof( bool ), cudaMemcpyDeviceToHost ) );
       
        // Set count_neurons to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
       allSynapses.count_neurons = 0;
}

__device__ fpCreateSynapse_t fpCreateSpikingSynapse_d = (fpCreateSynapse_t)createSpikingSynapse;

/*
 *  Get a pointer to the device function createSynapse.
 *  The function will be called from updateSynapsesWeightsDevice device function.
 *  Because we cannot use virtual function (Polymorphism) in device functions,
 *  we use this scheme.
 *
 *  @param  fpCreateSynapse_h     Reference to the memory location 
 *                                where the function pointer will be set.
 */
void AllSpikingSynapses::getFpCreateSynapse(fpCreateSynapse_t& fpCreateSynapse_h)
{
    HANDLE_ERROR( cudaMemcpyFromSymbol(&fpCreateSynapse_h, fpCreateSpikingSynapse_d, sizeof(fpCreateSynapse_t)) );
}

/*
 *  Set some parameters used for advanceSynapsesDevice.
 *  Currently we set a member variable: m_fpChangePSR_h.
 */
void AllSpikingSynapses::setAdvanceSynapsesDeviceParams()
{
    getFpChangePSR(m_fpChangePSR_h);
}

/*
 *  Advance all the Synapses in the simulation.
 *  Update the state of all synapses for a time step.
 *
 *  @param  allSynapsesDevice      Reference to the allSynapses struct on device memory.
 *  @param  allNeuronsDevice       Reference to the allNeurons struct on device memory.
 *  @param  synapseIndexMapDevice  Reference to the SynapseIndexMap on device memory.
 *  @param  sim_info               SimulationInfo class to read information from.
 */
void AllSpikingSynapses::advanceSynapses(IAllSynapses* allSynapsesDevice, IAllNeurons* allNeuronsDevice, void* synapseIndexMapDevice, const SimulationInfo *sim_info)
{
    if (total_synapse_counts == 0)
        return;

    // CUDA parameters
    const int threadsPerBlock = 256;
    int blocksPerGrid = ( total_synapse_counts + threadsPerBlock - 1 ) / threadsPerBlock;

    // Advance synapses ------------->
    advanceSpikingSynapsesDevice <<< blocksPerGrid, threadsPerBlock >>> ( total_synapse_counts, (SynapseIndexMap*)synapseIndexMapDevice, g_simulationStep, sim_info->deltaT, (AllSpikingSynapses*)allSynapsesDevice, (void (*)(AllSpikingSynapses*, const BGSIZE, const uint64_t, const BGFLOAT))m_fpChangePSR_h );
}

__device__ fpPreSynapsesSpikeHit_t fpPreSpikingSynapsesSpikeHit_d = (fpPreSynapsesSpikeHit_t)preSpikingSynapsesSpikeHitDevice;

/*
 *  Get a pointer to the device function preSpikeHit.
 *  The function will be called from advanceNeuronsDevice device function.
 *  Because we cannot use virtual function (Polymorphism) in device functions,
 *  we use this scheme.
 *
 *  @param  fpPreSpikeHit_h       Reference to the memory location
 *                                where the function pointer will be set.
 */
void AllSpikingSynapses::getFpPreSpikeHit(fpPreSynapsesSpikeHit_t& fpPreSpikeHit_h)
{
    HANDLE_ERROR( cudaMemcpyFromSymbol(&fpPreSpikeHit_h, fpPreSpikingSynapsesSpikeHit_d, sizeof(fpPreSynapsesSpikeHit_t)) );
}

__device__ fpPostSynapsesSpikeHit_t fpPostSpikingSynapsesSpikeHit_d = (fpPostSynapsesSpikeHit_t)postSpikingSynapsesSpikeHitDevice;

/*
 *  Get a pointer to the device function ostSpikeHit.
 *  The function will be called from advanceNeuronsDevice device function.
 *  Because we cannot use virtual function (Polymorphism) in device functions,
 *  we use this scheme.
 *
 *  @param  fpostSpikeHit_h       Reference to the memory location
 *                                where the function pointer will be set.
 */
void AllSpikingSynapses::getFpPostSpikeHit(fpPostSynapsesSpikeHit_t& fpPostSpikeHit_h)
{
    HANDLE_ERROR( cudaMemcpyFromSymbol(&fpPostSpikeHit_h, fpPostSpikingSynapsesSpikeHit_d, sizeof(fpPostSynapsesSpikeHit_t)) );
}

__device__ fpChangeSynapsesPSR_t fpChangeSpikingSynapsesPSR_d = (fpChangeSynapsesPSR_t)changeSpikingSynapsesPSR;

/*
 *  Get a pointer to the device function changeSpikingSynapsesPSR.
 *  The function will be called from advanceSpikingSynapsesDevice device function.
 *  Because we cannot use virtual function (Polymorphism) in device functions,
 *  we use this scheme.
 *
 *  @param  fpChangePSR_h         Reference to the memory location
 *                                where the function pointer will be set.
 */
void AllSpikingSynapses::getFpChangePSR(fpChangeSynapsesPSR_t& fpChangePSR_h)
{
    HANDLE_ERROR( cudaMemcpyFromSymbol(&fpChangePSR_h, fpChangeSpikingSynapsesPSR_d, sizeof(fpChangeSynapsesPSR_t)) );
}

/* ------------------*\
|* # Global Functions
\* ------------------*/

/*
 *  CUDA code for advancing spiking synapses.
 *  Perform updating synapses for one time step.
 *
 *  @param[in] total_synapse_counts  Number of synapses.
 *  @param  synapseIndexMapDevice    Reference to the SynapseIndexMap on device memory.
 *  @param[in] simulationStep        The current simulation step.
 *  @param[in] deltaT                Inner simulation step duration.
 *  @param[in] allSynapsesDevice     Pointer to Synapse structures in device memory.
 *  @param[in] fpChangePSR           Pointer to the device function changePSR() function.
 */
__global__ void advanceSpikingSynapsesDevice ( int total_synapse_counts, SynapseIndexMap* synapseIndexMapDevice, uint64_t simulationStep, const BGFLOAT deltaT, AllSpikingSynapses* allSynapsesDevice, void (*fpChangePSR)(AllSpikingSynapses*, const BGSIZE, const uint64_t, const BGFLOAT) ) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if ( idx >= total_synapse_counts )
                return;

        BGSIZE iSyn = synapseIndexMapDevice->activeSynapseIndex[idx];
       
        BGFLOAT &psr = allSynapsesDevice->psr[iSyn];
        BGFLOAT decay = allSynapsesDevice->decay[iSyn];

        // Checks if there is an input spike in the queue.
        bool isFired = isSpikingSynapsesSpikeQueueDevice(allSynapsesDevice, iSyn);

        // is an input in the queue?
        if (isFired) {
                fpChangePSR(allSynapsesDevice, iSyn, simulationStep, deltaT);
        }
        // decay the post spike response
        psr *= decay;
}

/* ------------------*\
|* # Device Functions
\* ------------------*/

/*
 *  Create a Spiking Synapse and connect it to the model.
 *
 *  @param allSynapsesDevice    Pointer to the Synapse structures in device memory.
 *  @param neuron_index         Index of the source neuron.
 *  @param synapse_index        Index of the Synapse to create.
 *  @param source_x             X location of source.
 *  @param source_y             Y location of source.
 *  @param dest_x               X location of destination.
 *  @param dest_y               Y location of destination.
 *  @param sum_point            Pointer to the summation point.
 *  @param deltaT               The time step size.
 *  @param type                 Type of the Synapse to create.
 */
__device__ void createSpikingSynapse(AllSpikingSynapses* allSynapsesDevice, const int neuron_index, const int synapse_index, int source_index, int dest_index, BGFLOAT *sum_point, const BGFLOAT deltaT, synapseType type)
{
    BGFLOAT delay;
    BGSIZE max_synapses = allSynapsesDevice->maxSynapsesPerNeuron;
    BGSIZE iSyn = max_synapses * neuron_index + synapse_index;

    allSynapsesDevice->in_use[iSyn] = true;
    allSynapsesDevice->summationPoint[iSyn] = sum_point;
    allSynapsesDevice->destNeuronIndex[iSyn] = dest_index;
    allSynapsesDevice->sourceNeuronIndex[iSyn] = source_index;
    allSynapsesDevice->W[iSyn] = synSign(type) * 10.0e-9;

    allSynapsesDevice->delayQueue[iSyn] = 0;
    allSynapsesDevice->delayIdx[iSyn] = 0;
    allSynapsesDevice->ldelayQueue[iSyn] = LENGTH_OF_DELAYQUEUE;

    allSynapsesDevice->psr[iSyn] = 0.0;
    allSynapsesDevice->type[iSyn] = type;

    allSynapsesDevice->tau[iSyn] = DEFAULT_tau;

    BGFLOAT tau;
    switch (type) {
        case II:
            tau = 6e-3;
            delay = 0.8e-3;
            break;
        case IE:
            tau = 6e-3;
            delay = 0.8e-3;
            break;
        case EI:
            tau = 3e-3;
            delay = 0.8e-3;
            break;
        case EE:
            tau = 3e-3;
            delay = 1.5e-3;
            break;
        default:
            break;
    }

    allSynapsesDevice->tau[iSyn] = tau;
    allSynapsesDevice->decay[iSyn] = exp( -deltaT / tau );
    allSynapsesDevice->total_delay[iSyn] = static_cast<int>( delay / deltaT ) + 1;

    uint32_t size = allSynapsesDevice->total_delay[iSyn] / ( sizeof(uint8_t) * 8 ) + 1;
    assert( size <= BYTES_OF_DELAYQUEUE );
}

/*     
 *  Checks if there is an input spike in the queue.
 *
 *  @param[in] allSynapsesDevice     Pointer to Synapse structures in device memory.
 *  @param[in] iSyn                  Index of the Synapse to check.
 *  @return true if there is an input spike event.
 */
__device__ bool isSpikingSynapsesSpikeQueueDevice(AllSpikingSynapses* allSynapsesDevice, BGSIZE iSyn)
{
    uint32_t &delay_queue = allSynapsesDevice->delayQueue[iSyn];
    int &delayIdx = allSynapsesDevice->delayIdx[iSyn];
    int ldelayQueue = allSynapsesDevice->ldelayQueue[iSyn];

    uint32_t delayMask = (0x1 << delayIdx);
    bool isFired = delay_queue & (delayMask);
    delay_queue &= ~(delayMask);
    if ( ++delayIdx >= ldelayQueue ) {
            delayIdx = 0;
    }

    return isFired;
}

/*
 *  Prepares Synapse for a spike hit.
 *
 *  @param[in] iSyn                  Index of the Synapse to update.
 *  @param[in] allSynapsesDevice     Pointer to Synapse structures in device memory.
 */
__device__ void preSpikingSynapsesSpikeHitDevice( const BGSIZE iSyn, AllSpikingSynapses* allSynapsesDevice ) {
        uint32_t &delay_queue = allSynapsesDevice->delayQueue[iSyn];
        int delayIdx = allSynapsesDevice->delayIdx[iSyn];
        int ldelayQueue = allSynapsesDevice->ldelayQueue[iSyn];
        int total_delay = allSynapsesDevice->total_delay[iSyn];

        // Add to spike queue

        // calculate index where to insert the spike into delayQueue
        int idx = delayIdx +  total_delay;
        if ( idx >= ldelayQueue ) {
                idx -= ldelayQueue;
        }

        // set a spike
        //assert( !(delay_queue[0] & (0x1 << idx)) );
        delay_queue |= (0x1 << idx);
}

/*
 *  Prepares Synapse for a spike hit (for back propagation).
 *
 *  @param[in] iSyn                  Index of the Synapse to update.
 *  @param[in] allSynapsesDevice     Pointer to Synapse structures in device memory.
 */
__device__ void postSpikingSynapsesSpikeHitDevice( const BGSIZE iSyn, AllSpikingSynapses* allSynapsesDevice ) {
}

/*
 *  Update PSR (post synapse response)
 *
 *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
 *  @param  iSyn               Index of the synapse to set.
 *  @param  simulationStep     The current simulation step.
 *  @param  deltaT             Inner simulation step duration.
 */
__device__ void changeSpikingSynapsesPSR(AllSpikingSynapses* allSynapsesDevice, const BGSIZE iSyn, const uint64_t simulationStep, const BGFLOAT deltaT)
{
    BGFLOAT &psr = allSynapsesDevice->psr[iSyn];
    BGFLOAT &W = allSynapsesDevice->W[iSyn];
    BGFLOAT &decay = allSynapsesDevice->decay[iSyn];

    psr += ( W / decay );    // calculate psr
}

/*
 * Adds a synapse to the network.  Requires the locations of the source and
 * destination neurons.
 *
 * @param allSynapsesDevice      Pointer to the Synapse structures in device memory.
 * @param type                   Type of the Synapse to create.
 * @param src_neuron             Index of the source neuron.
 * @param dest_neuron            Index of the destination neuron.
 * @param source_x               X location of source.
 * @param source_y               Y location of source.
 * @param dest_x                 X location of destination.
 * @param dest_y                 Y location of destination.
 * @param sum_point              Pointer to the summation point.
 * @param deltaT                 The time step size.
 * @param W_d                    Array of synapse weight.
 * @param num_neurons            The number of neurons.
 */
__device__ void addSpikingSynapse(AllSpikingSynapses* allSynapsesDevice, synapseType type, const int src_neuron, const int dest_neuron, int source_index, int dest_index, BGFLOAT *sum_point, const BGFLOAT deltaT, BGFLOAT* W_d, int num_neurons, void (*fpCreateSynapse)(AllSpikingSynapses*, const int, const int, int, int, BGFLOAT*, const BGFLOAT, synapseType))
{
    if (allSynapsesDevice->synapse_counts[src_neuron] >= allSynapsesDevice->maxSynapsesPerNeuron) {
        return; // TODO: ERROR!
    }

    // add it to the list
    BGSIZE synapse_index;
    BGSIZE max_synapses = allSynapsesDevice->maxSynapsesPerNeuron;
    BGSIZE iSync = max_synapses * src_neuron;
    for (synapse_index = 0; synapse_index < max_synapses; synapse_index++) {
        if (!allSynapsesDevice->in_use[iSync + synapse_index]) {
            break;
        }
    }

    allSynapsesDevice->synapse_counts[src_neuron]++;

    // create a synapse
    fpCreateSynapse(allSynapsesDevice, src_neuron, synapse_index, source_index, dest_index, sum_point, deltaT, type );
    allSynapsesDevice->W[iSync + synapse_index] = W_d[src_neuron * num_neurons + dest_neuron] * synSign(type) * AllSynapses::SYNAPSE_STRENGTH_ADJUSTMENT;
}

/*
 * Remove a synapse from the network.
 *
 * @param[in] allSynapsesDevice         Pointer to the Synapse structures in device memory.
 * @param neuron_index   Index of a neuron.
 * @param synapse_index  Index of a synapse.
 * @param[in] maxSynapses        Maximum number of synapses per neuron.
 */
__device__ void eraseSpikingSynapse( AllSpikingSynapses* allSynapsesDevice, const int neuron_index, const int synapse_index, int maxSynapses )
{
    BGSIZE iSync = maxSynapses * neuron_index + synapse_index;
    allSynapsesDevice->synapse_counts[neuron_index]--;
    allSynapsesDevice->in_use[iSync] = false;
    allSynapsesDevice->summationPoint[iSync] = NULL;
}

/*
 * Returns the type of synapse at the given coordinates
 *
 * @param[in] allNeuronsDevice          Pointer to the Neuron structures in device memory.
 * @param src_neuron             Index of the source neuron.
 * @param dest_neuron            Index of the destination neuron.
 */
__device__ synapseType synType( neuronType* neuron_type_map_d, const int src_neuron, const int dest_neuron )
{
    if ( neuron_type_map_d[src_neuron] == INH && neuron_type_map_d[dest_neuron] == INH )
        return II;
    else if ( neuron_type_map_d[src_neuron] == INH && neuron_type_map_d[dest_neuron] == EXC )
        return IE;
    else if ( neuron_type_map_d[src_neuron] == EXC && neuron_type_map_d[dest_neuron] == INH )
        return EI;
    else if ( neuron_type_map_d[src_neuron] == EXC && neuron_type_map_d[dest_neuron] == EXC )
        return EE;

    return STYPE_UNDEF;

}

/*
 * Return 1 if originating neuron is excitatory, -1 otherwise.
 *
 * @param[in] t  synapseType I to I, I to E, E to I, or E to E
 * @return 1 or -1
 */
__device__ int synSign( synapseType t )
{
        switch ( t )
        {
        case II:
        case IE:
                return -1;
        case EI:
        case EE:
                return 1;
        }

        return 0;
}
