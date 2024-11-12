from qiskit import QuantumCircuit, transpile
from qiskit.transpiler import CouplingMap
from qiskit_aer import AerSimulator
from qiskit.circuit.library import QuantumVolume
import time


## CHOOSE PARAMETERS --------------------------------------------------------------------------------------------------------------

qubits = 30                     # How many qubits does the circuit have
depth = 30                      # How many layers of quantum gates does the circuit have (Applies for Quantum Volume circuit)
num_shots = 1000                # How many times we sample the circuit

sim_method = 'statevector'      # Circuits with over 30 qubits start to require a lot of memory if using statevector simulator
sim_device = 'GPU'              # Requires system that provides GPU

use_batched_shots = True        # Enables distributing shots to multiple processess
use_cache_blocking = True       # Enables cache blocking technique. Qiskit Aer parallelizes simulations by distributing quantum states into distributed memory space.
num_blocking_qubits = 25        # Must be smaller than qubits-log2(num_processes). Smaller number of blocking qubits -> more processess (beneficial to utilize MPI by allocating more resources)
num_parallel_experiments = 1    # Does not seem to do anything when running with MPI, probably intended to be used with multithreading

start_time = time.time()





## INITIALIZE SIMULATOR BACKEND ---------------------------------------------------------------------------------------------------
sim = AerSimulator(method='statevector', device=sim_device, batched_shots_gpu=use_batched_shots)



## CREATE CIRCUIT -----------------------------------------------------------------------------------------------------------------
circuit = QuantumVolume(qubits, depth, seed=0)
circuit.measure_all()



## TRANSPILE THE FOR CIRCUIT FOR FULL COUPLING MAP --------------------------------------------------------------------------------
coupling_map = CouplingMap.from_full(qubits)
transpiled_circuit = transpile(circuit, sim, coupling_map=coupling_map, optimization_level=0)



## RUN THE SIMULATION -------------------------------------------------------------------------------------------------------------
print(f"Simulation starts in {time.time() - start_time}")
result_statevec = sim.run(transpiled_circuit, shots=num_shots, seed_simulator=12345, blocking_enabled=use_cache_blocking, blocking_qubits=num_blocking_qubits, max_parallel_experiments=num_parallel_experiments).result()
print(f"Simulation ready in {time.time() - start_time}")



## GATHER THE RESULTS AND PRINT WITH SOME ADDITIONAL METADATA ---------------------------------------------------------------------
input_data = {'Circuit' : 'Quantum Volume', 'Qubits' : qubits, 'Depth' : depth, 'Shots' : num_shots, 'Batched Shots' : use_batched_shots , 'Device' : sim_device, 'Simulation Method' : sim_method}
if (use_cache_blocking):
    num_processes = 2**(qubits - num_blocking_qubits)
    input_data['Blocking Qubits'] = num_blocking_qubits
    input_data['Num Processes'] = num_processes

dict = result_statevec.to_dict()
meta = dict['metadata']

print(f"{input_data}")
print(f"{meta}")
print(f"-------------------------------------------------------------- \n")
