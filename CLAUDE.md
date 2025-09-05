# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

Open5GS uses the Meson build system. Key build commands:

```bash
# Initial setup and build
meson build --prefix=`pwd`/install
ninja -C build

# Install to configured prefix
ninja -C build install

# Run tests (only if not cross-compiling or with exe wrapper)
ninja -C build test

# Static analysis
ninja -C build analyze-cppcheck    # requires cppcheck
ninja -C build analyze-clang-tidy  # requires clang-tools
```

## Configuration System

Configuration files use a template system:
- Template files: `configs/open5gs/*.yaml.in` (e.g., `amf.yaml.in`)
- Generated files: `build/configs/open5gs/*.yaml` (e.g., `amf.yaml`)
- Installed files: `./install/etc/open5gs/*.yaml`

Templates contain placeholders like `@localstatedir@` and `@sysconfdir@` that are replaced during the build process with actual paths based on the `--prefix` option.

To modify default configurations, edit the `.yaml.in` template files in `configs/open5gs/`.

## Architecture Overview

Open5GS is a complete 5G/4G mobile core network implementation with the following structure:

### Core Components (src/)
- **Network Functions**: Each 5G/4G network function has its own directory:
  - `amf/` - Access and Mobility Management Function (5G)
  - `smf/` - Session Management Function (5G) 
  - `upf/` - User Plane Function (5G)
  - `mme/` - Mobility Management Entity (4G)
  - `sgwc/sgwu/` - Serving Gateway Control/User Plane (4G)
  - `ausf/udm/udr/nrf/nssf/pcf/bsf/scp/sepp/` - Other 5G functions
  - `hss/pcrf/` - 4G database and policy functions

### Libraries (lib/)
- `sbi/` - Service Based Interface implementation (5G)
- `nas/` - Non-Access Stratum protocol handling
- `ngap/s1ap/` - Control plane protocols (5G/4G)
- `gtp/pfcp/` - Tunneling and packet forwarding protocols
- `diameter/` - Diameter protocol (4G interfaces)
- `core/` - Core utilities and data structures
- `app/` - Application framework
- `asn1c/` - ASN.1 compiler and codecs

### Test Structure (tests/)
The test suite is organized by functionality:
- `unit/` - Unit tests for core libraries
- `registration/attach/` - Registration/attach procedures
- `handover/` - Handover scenarios
- `volte/vonr/` - Voice services
- `slice/` - Network slicing tests
- Specific test scenarios: `310014/`, `non3gpp/`, `transfer/`

## Development Workflow

### Code Quality
- Compiler: Uses GNU89 C standard with extensive warning flags
- Static analysis available via `ninja -C build analyze-cppcheck` and `ninja -C build analyze-clang-tidy`
- Source exclusions for analysis: `asn1c` and `ipfw` directories are excluded

### Testing
Tests are built and run automatically unless cross-compiling without an execution wrapper. Test executables are created in the build directory and can be run individually.

Individual test binaries can be found in `build/tests/` subdirectories and run directly for debugging specific functionality.

### Project Structure
- Each network function is essentially a standalone daemon
- Common libraries in `lib/` provide shared functionality
- Configuration is centralized but each component has its own YAML file
- Logging goes to `/var/log/open5gs/` by default (configurable via template)

## Key Files
- `src/main.c` - Common entry point for all network functions
- `lib/app/ogs-context.h` and `lib/app/ogs-init.c` - Application initialization framework
- `meson_options.txt` - Build options (currently only fuzzing support)
- `misc/static-code-analyze.sh` - Static analysis script used by build targets

## Running Network Functions

After installation, network functions can be run from `./install/bin/`:
```bash
./install/bin/open5gs-nrf    # Network Repository Function
./install/bin/open5gs-amf    # Access and Mobility Management Function
./install/bin/open5gs-smf    # Session Management Function
# ... other network functions
```

Configuration files are loaded from `./install/etc/open5gs/` and logs are written to `./install/var/log/open5gs/`.