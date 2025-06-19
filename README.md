# vehicular-canal-estimator

## Configuration JSON file description

Each simulation is configured using a JSON file (see `src/simulation/config/`).  
Below is a description of the main fields and their expected dimensions:

- **nb_samples**: _(scalar)_ Number of signals (samples) to generate for the simulation.
- **seed**: _(scalar)_ Random seed for reproducibility.
- **snr**: _(scalar)_ Signal-to-noise ratio (in dB) for the simulation.

### `vehicles` section

- **nb_vehicles**: _(scalar)_ Number of vehicles in the simulation.
- **d_min**, **d_max**: _(scalar)_ Minimum and maximum distance between vehicles.
- **v_min**, **v_max**: _(scalar)_ Minimum and maximum speed of vehicles (in m/s).
- **initial_pos**: _(array of shape [N, 3])_ Initial positions of vehicles, where each row is `[x, y, z]`.

### `buildings` section

- **position**: _(array of shape [N, 3])_ Positions of buildings, each row is `[x, y, z]`.
- **height**: _(array of shape [N])_ Height of each building.
- **length**: _(array of shape [N])_ Length of each building.
- **eps_r**: _(scalar)_ Relative permittivity of the buildings.

### `emitter` section

- **modulation_type**: _(string)_ Modulation type (`bpsk`, `qpsk`, `16qam`, `64qam`).
- **params**:
  - **sps**: _(scalar)_ Samples per symbol.
  - **fc**: _(scalar)_ Carrier frequency (in Hz).
  - **fs**: _(scalar)_ Sampling frequency (in Hz).

### `antenna` section

- **tx**: _(object)_ Transmitter antenna parameters
  - **position**: _(scalar or [3])_ Index or position of the TX antenna.
  - **velocity**: _(array of shape [3])_ Velocity vector `[vx, vy, vz]` for TX.
- **rx**: _(object)_ Receiver antenna parameters
  - **position**: _(scalar or [3])_ Index or position of the RX antenna.
  - **velocity**: _(array of shape [3])_ Velocity vector `[vx, vy, vz]` for RX.

---

**Example:**  
See [`src/simulation/config/crossing.json`](src/simulation/config/crossing.json) for a complete example.
