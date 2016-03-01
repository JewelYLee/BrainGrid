/**
 *      @file IAllSynapses.h
 *
 *      @brief An interface for synapse classes.
 */

#pragma once

#include "Global.h"
#include "SimulationInfo.h"
#include "SynapseIndexMap.h"

class IAllNeurons;

class IAllSynapses
{
    public:
        virtual ~IAllSynapses() {};

        /**
         *  Setup the internal structure of the class (allocate memories and initialize them).
         *
         *  @param  sim_info  SimulationInfo class to read information from.
         */
        virtual void setupSynapses(SimulationInfo *sim_info) = 0;

        /**
         *  Cleanup the class (deallocate memories).
         */
        virtual void cleanupSynapses() = 0;

        /**
         *  Reset time varying state vars and recompute decay.
         *
         *  @param  iSyn     Index of the synapse to set.
         *  @param  deltaT   Inner simulation step duration
         */
        virtual void resetSynapse(const uint32_t iSyn, const BGFLOAT deltaT) = 0;

        /**
         *  Attempts to read parameters from a XML file.
         *
         *  @param  element TiXmlElement to examine.
         *  @return true if successful, false otherwise.
         */
        virtual bool readParameters(const TiXmlElement& element) = 0;

        /**
         *  Prints out all parameters of the neurons to ostream.
         *
         *  @param  output  ostream to send output to.
         */
        virtual void printParameters(ostream &output) const = 0;

        /**
         *  Sets the data for Synapses to input's data.
         *
         *  @param  input  istream to read from.
         *  @param  sim_info  SimulationInfo class to read information from.
         */
        virtual void deserialize(istream& input, IAllNeurons &neurons, const SimulationInfo *sim_info) = 0;

        /**
         *  Write the synapses data to the stream.
         *
         *  @param  output  stream to print out to.
         *  @param  sim_info  SimulationInfo class to read information from.
         */
        virtual void serialize(ostream& output, const SimulationInfo *sim_info) = 0;

        /**
         *  Adds a Synapse to the model, connecting two Neurons.
         *
         *  @param  iSyn        Index of the synapse to be added.
         *  @param  type        The type of the Synapse to add.
         *  @param  src_neuron  The Neuron that sends to this Synapse.
         *  @param  dest_neuron The Neuron that receives from the Synapse.
         *  @param  sum_point   Summation point address.
         *  @param  deltaT      Inner simulation step duration
         */
        virtual void addSynapse(uint32_t &iSyn, synapseType type, const int src_neuron, const int dest_neuron, BGFLOAT *sum_point, const BGFLOAT deltaT) = 0;

        /**
         *  Create a Synapse and connect it to the model.
         *
         *  @param  synapses    The synapse list to reference.
         *  @param  iSyn        Index of the synapse to set.
         *  @param  source      Coordinates of the source Neuron.
         *  @param  dest        Coordinates of the destination Neuron.
         *  @param  sum_point   Summation point address.
         *  @param  deltaT      Inner simulation step duration.
         *  @param  type        Type of the Synapse to create.
         */
        virtual void createSynapse(const uint32_t iSyn, int source_index, int dest_index, BGFLOAT* sp, const BGFLOAT deltaT, synapseType type) = 0;

        /**
         *  Create a synapse index map.
         *
         *  @param  synapseIndexMap   Reference to thw pointer to SynapseIndexMap structure.
         *  @param  sim_info          Pointer to the simulation information.
         */
        virtual void createSynapseImap(SynapseIndexMap *&synapseIndexMap, const SimulationInfo* sim_info) = 0;

        /**
         *  Get the sign of the synapseType.
         *
         *  @param    type    synapseType I to I, I to E, E to I, or E to E
         *  @return   1 or -1, or 0 if error
         */
        virtual int synSign(const synapseType type) = 0;

#if defined(USE_GPU)
    public:
        /**
         *  Allocate GPU memories to store all synapses' states,
         *  and copy them from host to GPU memory.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void allocSynapseDeviceStruct( void** allSynapsesDevice, const SimulationInfo *sim_info ) = 0;

        /**
         *  Allocate GPU memories to store all synapses' states,
         *  and copy them from host to GPU memory.
         *
         *  @param  allSynapsesDevice     Reference to the allSynapses struct on device memory.
         *  @param  num_neurons           Number of neurons.
         *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
         */
        virtual void allocSynapseDeviceStruct( void** allSynapsesDevice, int num_neurons, int maxSynapsesPerNeuron ) = 0;

        /**
         *  Delete GPU memories.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void deleteSynapseDeviceStruct( void* allSynapsesDevice ) = 0;

        /**
         *  Copy all synapses' data from host to device.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void copySynapseHostToDevice( void* allSynapsesDevice, const SimulationInfo *sim_info ) = 0;

        /**
         *  Copy all synapses' data from host to device.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  num_neurons           Number of neurons.
         *  @param  maxSynapsesPerNeuron  Maximum number of synapses per neuron.
         */
        virtual void copySynapseHostToDevice( void* allSynapsesDevice, int num_neurons, int maxSynapsesPerNeuron ) = 0;

        /**
         *  Copy all synapses' data from device to host.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void copySynapseDeviceToHost( void* allSynapsesDevice, const SimulationInfo *sim_info ) = 0;

        /**
         *  Get synapse_counts in AllSynapses struct on device memory.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void copyDeviceSynapseCountsToHost(void* allSynapsesDevice, const SimulationInfo *sim_info) = 0;

        /** 
         *  Get summationCoord and in_use in AllSynapses struct on device memory.
         *
         *  @param  allSynapsesDevice  Reference to the allSynapses struct on device memory.
         *  @param  sim_info           SimulationInfo to refer from.
         */
        virtual void copyDeviceSynapseSumIdxToHost(void* allSynapsesDevice, const SimulationInfo *sim_info) = 0;

        /**
         *  Advance all the Synapses in the simulation.
         *  Update the state of all synapses for a time step.
         *
         *  @param  allSynapsesDevice      Reference to the allSynapses struct on device memory.
         *  @param  allNeuronsDevice       Reference to the allNeurons struct on device memory.
         *  @param  synapseIndexMapDevice  Reference to the SynapseIndexMap on device memory.
         *  @param  sim_info               SimulationInfo class to read information from.
         */
        virtual void advanceSynapses(IAllSynapses* allSynapsesDevice, IAllNeurons* allNeuronsDevice, void* synapseIndexMapDevice, const SimulationInfo *sim_info) = 0;

        /**
         *  Get a pointer to the device function createSynapse.
         *  The function will be called from updateSynapsesWeightsDevice device function.
         *  Because we cannot use virtual function (Polymorphism) in device functions,
         *  we use this scheme.
         *
         *  @param  fpCreateSynapse_h     Reference to the memory location 
         *                                where the function pointer will be set.
         */
        virtual void getFpCreateSynapse(unsigned long long& fpCreateSynapse_h) = 0;

        /**
         *  Set some parameters used for advanceSynapsesDevice.
         *  Currently we set a member variable: m_fpChangePSR_h.
         */
        virtual void setAdvanceSynapsesDeviceParams() = 0;

        /**
         *  Get a pointer to the device function changePSR.
         *  The function will be called from advanceSynapsesDevice device function.
         *  Because we cannot use virtual function (Polymorphism) in device functions,
         *  we use this scheme.
         *
         *  @param  fpChangePSR_h         Reference to the memory location
         *                                where the function pointer will be set.
         */
        virtual void getFpChangePSR(unsigned long long& fpChangePSR_h) = 0;
#else // !defined(USE_GPU)
    public:
        /**
         *  Advance all the Synapses in the simulation.
         *  Update the state of all synapses for a time step.
         *
         *  @param  sim_info  SimulationInfo class to read information from.
         *  @param  neurons   The Neuron list to search from.
         */
        virtual void advanceSynapses(const SimulationInfo *sim_info, IAllNeurons *neurons) = 0;

        /**
         *  Advance one specific Synapse.
         *
         *  @param  iSyn      Index of the Synapse to connect to.
         *  @param  sim_info  SimulationInfo class to read information from.
         *  @param  neurons   The Neuron list to search from.
         */
        virtual void advanceSynapse(const uint32_t iSyn, const SimulationInfo *sim_info, IAllNeurons *neurons) = 0;

        /**
         *  Remove a synapse from the network.
         *
         *  @param  neuron_index   Index of a neuron to remove from.
         *  @param  iSyn           Index of a synapse to remove.
         */
        virtual void eraseSynapse(const int neuron_index, const uint32_t iSyn) = 0;
#endif // defined(USE_GPU)
};