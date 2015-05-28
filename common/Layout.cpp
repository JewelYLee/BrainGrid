#include "Layout.h"
#include "ParseParamError.h"
#include "Util.h"

const bool Layout::STARTER_FLAG(true);

Layout::Layout() :
    m_fixed_layout(false)
{
}

Layout::~Layout()
{
}

/**
 *  Attempts to read parameters from a XML file.
 *  @param  @param  element TiXmlElement to examine.
 *  @return true if successful, false otherwise.
 */
bool Layout::readParameters(const TiXmlElement& element)
{
    if (element.ValueStr().compare("LsmParams") == 0) {
        if (element.QueryFLOATAttribute("frac_EXC", &m_frac_excititory_neurons) != TIXML_SUCCESS) {
            throw ParseParamError("frac_EXC", "Fraction Excitatory missing in XML.");
        }
        if (m_frac_excititory_neurons < 0 || m_frac_excititory_neurons > 1) {
            throw ParseParamError("frac_EXC", "Invalid range for a fraction.");
        }

        if (element.QueryFLOATAttribute("starter_neurons", &m_frac_starter_neurons) != TIXML_SUCCESS) {
            throw ParseParamError("starter_neurons", "Fraction endogenously active missing in XML.");
        }
        if (m_frac_starter_neurons < 0 || m_frac_starter_neurons > 1) {
            throw ParseParamError("starter_neurons", "Invalid range for a fraction.");
        }
    }

    // Parse fixed layout (overrides random layouts)
    bool fRet = true;
    if (element.ValueStr().compare("FixedLayout") == 0) {
        m_fixed_layout = true;

        const TiXmlNode* pNode = NULL;
        while ((pNode = element.IterateChildren(pNode)) != NULL) {
            string activeNListFileName;
            string inhNListFileName;
            string probedNListFileName;

            if (strcmp(pNode->Value(), "A") == 0) {
                getValueList(pNode->ToElement()->GetText(), &m_endogenously_active_neuron_list);
            } else if (strcmp(pNode->Value(), "I") == 0) {
                getValueList(pNode->ToElement()->GetText(), &m_inhibitory_neuron_layout);
            }
            else if (strcmp(pNode->Value(), "LayoutFiles") == 0)
            {
                if (pNode->ToElement()->QueryValueAttribute( "inhNListFileName", &inhNListFileName ) == TIXML_SUCCESS)
                {
                    TiXmlDocument simDoc( inhNListFileName.c_str( ) );
                    if (!simDoc.LoadFile( ))
                    {
                        cerr << "Failed loading positions of inhibitory neurons list file " << inhNListFileName << ":" << "\n\t"
                            << simDoc.ErrorDesc( ) << endl;
                        cerr << " error: " << simDoc.ErrorRow( ) << ", " << simDoc.ErrorCol( ) << endl;
                        fRet = false;
                        break;
                    }
                    TiXmlNode* temp2 = NULL;
                    if (( temp2 = simDoc.FirstChildElement( "I" ) ) == NULL)
                    {
                        cerr << "Could not find <I> in positons of inhibitory neurons list file " << inhNListFileName << endl;
                        fRet = false;
                        break;
                    }
                    getValueList(temp2->ToElement()->GetText(), &m_inhibitory_neuron_layout);
                }
                if (pNode->ToElement()->QueryValueAttribute( "activeNListFileName", &activeNListFileName ) == TIXML_SUCCESS)
                {
                    TiXmlDocument simDoc( activeNListFileName.c_str( ) );
                    if (!simDoc.LoadFile( ))
                    {
                        cerr << "Failed loading positions of endogenously active neurons list file " << activeNListFileName << ":" << "\n\t"
                            << simDoc.ErrorDesc( ) << endl;
                        cerr << " error: " << simDoc.ErrorRow( ) << ", " << simDoc.ErrorCol( ) << endl;
                        fRet = false;
                        break;
                    }
                    TiXmlNode* temp2 = NULL;
                    if (( temp2 = simDoc.FirstChildElement( "A" ) ) == NULL)
                    {
                        cerr << "Could not find <A> in positons of endogenously active neurons list file " << activeNListFileName << endl;
                        fRet = false;
                        break;
                    }
                    getValueList(temp2->ToElement()->GetText(), &m_endogenously_active_neuron_list);
                }

                if (pNode->ToElement()->QueryValueAttribute( "probedNListFileName", &probedNListFileName ) == TIXML_SUCCESS) {
                    TiXmlDocument simDoc( probedNListFileName.c_str( ) );
                    if (!simDoc.LoadFile( ))
                    {
                        cerr << "Failed loading positions of probed neurons list file " << probedNListFileName << ":" << "\n\t"
                            << simDoc.ErrorDesc( ) << endl;
                        cerr << " error: " << simDoc.ErrorRow( ) << ", " << simDoc.ErrorCol( ) << endl;
                        fRet = false;
                        break;
                    }
                    TiXmlNode* temp2 = NULL;
                    if (( temp2 = simDoc.FirstChildElement( "P" ) ) == NULL)
                    {
                        cerr << "Could not find <P> in positions of probed neurons list file " << probedNListFileName << endl;
                        fRet = false;
                        break;
                    }
                    getValueList(temp2->ToElement()->GetText(), &m_probed_neuron_list);
               }
            }
        }
    }

    return fRet;
}

/**
 *  Prints out all parameters of the layout to ostream.
 *  @param  output  ostream to send output to.
 */
void Layout::printParameters(ostream &output) const
{
    output << "frac_EXC:" << m_frac_excititory_neurons
           << " starter_neurons:" << m_frac_starter_neurons
           << endl;

    if (m_fixed_layout) {
        output << "Layout parameters:" << endl;

        cout << "\tEndogenously active neuron positions: ";
        for (size_t i = 0; i < m_endogenously_active_neuron_list.size(); i++) {
            output << m_endogenously_active_neuron_list[i] << " ";
        }

        cout << endl;

        cout << "\tInhibitory neuron positions: ";
        for (size_t i = 0; i < m_inhibitory_neuron_layout.size(); i++) {
            output << m_inhibitory_neuron_layout[i] << " ";
        }

        cout << endl;

        cout << "\tProbed neuron positions: ";
        for (size_t i = 0; i < m_probed_neuron_list.size(); i++) {
            output << m_probed_neuron_list[i] << " ";
        }

        output << endl;
    }
}

/**
 *  Creates a randomly ordered distribution with the specified numbers of neuron types.
 *  @param  neuron_types    array of the types of neurons to have in the map.
 *  @param  num_neurons number of the neurons to have in the type map.
 *  @return a flat vector (to map to 2-d [x,y] = [i % m_width, i / m_width])
 */
void Layout::generateNeuronTypeMap(neuronType neuron_types[], int num_neurons)
{
    //TODO: m_pInhibitoryNeuronLayout
    int num_inhibitory_neurons = m_inhibitory_neuron_layout.size();
    int num_excititory_neurons = num_neurons - num_inhibitory_neurons;
    DEBUG(cout << "\nInitializing neuron type map"<< endl;);

    for (int i = 0; i < num_neurons; i++) {
        neuron_types[i] = EXC;
    }

    if (m_fixed_layout) {
        DEBUG(cout << "Total neurons: " << num_neurons << endl;)
        DEBUG(cout << "Inhibitory Neurons: " << num_inhibitory_neurons << endl;)
        DEBUG(cout << "Excitatory Neurons: " << num_excititory_neurons << endl;)

        for (int i = 0; i < num_inhibitory_neurons; i++) {
            neuron_types[m_inhibitory_neuron_layout.at(i)] = INH;
        }
    } else {
        int num_excititory_neurons = (int) (m_frac_excititory_neurons * num_neurons + 0.5);
        int num_inhibitory_neurons = num_neurons - num_excititory_neurons;
        DEBUG(cout << "Total neurons: " << num_neurons << endl;)
        DEBUG(cout << "Inhibitory Neurons: " << num_inhibitory_neurons << endl;)
        DEBUG(cout << "Excitatory Neurons: " << num_inhibitory_neurons << endl;)

        DEBUG(cout << endl << "Randomly selecting inhibitory neurons..." << endl;)

        int* rg_inhibitory_layout = new int[num_inhibitory_neurons];

        for (int i = 0; i < num_inhibitory_neurons; i++) {
            rg_inhibitory_layout[i] = i;
        }

        for (int i = num_inhibitory_neurons; i < num_neurons; i++) {
            int j = static_cast<int>(rng() * num_neurons);
            if (j < num_inhibitory_neurons) {
                rg_inhibitory_layout[j] = i;
            }
        }

        for (int i = 0; i < num_inhibitory_neurons; i++) {
            neuron_types[rg_inhibitory_layout[i]] = INH;
        }
        delete[] rg_inhibitory_layout;
    }

    DEBUG(cout << "Done initializing neuron type map" << endl;);
}

/**
 *  Populates the starter map.
 *  Selects \e numStarter excitory neurons and converts them into starter neurons.
 *  @param  starter_map booleam array of neurons to initiate.
 *  @param  num_neurons number of neurons to have in the map.
 *  @param  neuron_type_map array of neuronTypes to set the starter map to.
 */
void Layout::initStarterMap(bool *starter_map, const int num_neurons, const neuronType neuron_type_map[])
{
    for (int i = 0; i < num_neurons; i++) {
        starter_map[i] = false;
    }

    if (!STARTER_FLAG) {
        for (int i = 0; i < num_neurons; i++) {
            starter_map[i] = false;
        }
        return;
    }

    if (m_fixed_layout) {
        size_t num_endogenously_active_neurons = m_endogenously_active_neuron_list.size();
        for (size_t i = 0; i < num_endogenously_active_neurons; i++) {
            starter_map[m_endogenously_active_neuron_list.at(i)] = true;
        }
    } else {
        int num_starter_neurons = (int) (m_frac_starter_neurons * num_neurons + 0.5);
        int starters_allocated = 0;

        DEBUG(cout << "\nRandomly initializing starter map\n";);
        DEBUG(cout << "Total neurons: " << num_neurons << endl;)
        DEBUG(cout << "Starter neurons: " << num_starter_neurons << endl;)

        // randomly set neurons as starters until we've created enough
        while (starters_allocated < num_starter_neurons) {
            // Get a random integer
            int i = static_cast<int>(rng.inRange(0, num_neurons));

            // If the neuron at that index is excitatory and a starter map
            // entry does not already exist, add an entry.
            if (neuron_type_map[i] == EXC && starter_map[i] == false) {
                starter_map[i] = true;
                starters_allocated++;
                DEBUG(cout << "allocated EA neuron at random index [" << i << "]" << endl;);
            }
        }

        DEBUG(cout <<"Done randomly initializing starter map\n\n";)
    }
}