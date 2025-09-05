# Open5GS Analysis

## Project Overview

Open5GS is an open-source implementation of the 5G Core and EPC (Evolved Packet Core) for mobile networks. It is written in C/C++ and uses the Meson build system. The project is designed to be a full-featured and scalable core network solution.

The architecture consists of several key components, each running as a separate process:

*   **AMF (Access and Mobility Management Function):** Manages connection and mobility for UEs.
*   **SMF (Session Management Function):** Manages sessions and IP address allocation.
*   **UPF (User Plane Function):** Forwards user data.
*   **AUSF (Authentication Server Function):** Handles UE authentication.
*   **UDM (Unified Data Management):** Stores subscriber data.
*   **UDR (Unified Data Repository):** Stores application and subscription data.
*   **PCF (Policy Control Function):** Provides policy control.
*   **NSSF (Network Slice Selection Function):** Manages network slicing.
*   **NRF (Network Repository Function):** Manages network function discovery.
*   **BSF (Binding Support Function):** Supports policy and charging control.
*   **SCP (Service Communication Proxy):** Provides indirect communication between NFs.
*   **SEPP (Security Edge Protection Proxy):** Secures inter-PLMN connections.
*   **MME (Mobility Management Entity):** Manages session and mobility for UEs in EPC.
*   **SGW (Serving Gateway):** Forwards user data in EPC.
*   **PGW (Packet Data Network Gateway):** Provides connectivity to external networks in EPC.
*   **HSS (Home Subscriber Server):** Stores subscriber data in EPC.
*   **PCRF (Policy and Charging Rules Function):** Provides policy and charging control in EPC.

Open5GS uses MongoDB as its database to store subscriber information and other network-related data. A web UI is also available for management and configuration.

## Building and Running

### Building

The project uses Meson and Ninja for building. The following commands can be used to compile the project:

```bash
meson build
ninja -C build
```

### Running

The various Open5GS components can be run individually or orchestrated using `docker-compose`.

**Individual Components:**

Each component can be started from the `build` directory. For example, to start the AMF:

```bash
./build/src/amf/open5gs-amfd
```

Each component takes a `-c` flag to specify a configuration file.

**Docker Compose:**

The `docker-compose.yml` file in the `docker` directory can be used to start all the necessary components, including the database and web UI.

```bash
cd docker
docker-compose up
```

## Development Conventions

*   **Coding Style:** The code follows a consistent C/C++ style. The `.editorconfig` file suggests using 2 spaces for indentation.
*   **Testing:** The `tests` directory contains a suite of tests for the various components. Tests can be run using `meson test -C build`.
*   **Contributions:** The `CONTRIBUTING.md` file (referenced in `README.md`) outlines the contribution process, which includes signing a Contributor License Agreement (CLA).
*   **Static Analysis:** The project includes support for `cppcheck` and `clang-tidy` for static code analysis. These can be run with `ninja -C build analyze-cppcheck` and `ninja -C build analyze-clang-tidy` respectively.
