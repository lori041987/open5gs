<p align="center"><a href="https://open5gs.org" target="_blank" rel="noopener noreferrer"><img width="100" src="https://open5gs.org/assets/img/open5gs-logo-only.png" alt="Open5GS logo"></a></p>

## Getting Started

Please follow the [documentation](https://open5gs.org/open5gs/docs/) at [open5gs.org](https://open5gs.org/)!

## Configuration

The configuration files for Open5GS, such as `amf.yaml`, are generated from template files during the build process. Here's a step-by-step explanation of how it works:

1.  **Template Files:** In the `/home/wnc/Downloads/source_code/open5gs-2.7.6/configs/open5gs` directory, you'll find files with a `.yaml.in` extension, such as `amf.yaml.in`. These are the template files. If you look inside `amf.yaml.in`, you'll see placeholders like `@localstatedir@` and `@sysconfdir@`.

2.  **Meson Configuration:** The `meson.build` file in the `/home/wnc/Downloads/source_code/open5gs-2.7.6/configs` directory is the key to the process. It uses Meson's `configure_file` function.

3.  **Substitution:** When you run `meson build --prefix=`pwd`/install`, Meson does the following:
    *   It determines the actual paths for variables like `prefix`, `sysconfdir`, and `localstatedir` based on the `--prefix` you provide.
    *   It reads the `.yaml.in` template files.
    *   It replaces the placeholders (e.g., `@localstatedir@`) with the actual paths it just determined.
    *   It creates the final `.yaml` files (e.g., `amf.yaml`) in the `build/configs/open5gs` directory.

4.  **Installation:** When you run `ninja -C build install`, the `install` target copies the generated `.yaml` files from the `build/configs/open5gs` directory to your specified installation directory, which is `./install/etc/open5gs`.

In short, the `.yaml.in` files are templates that get filled in with the correct paths during the build process, creating the final configuration files that are then installed. This allows the configuration to be flexible and adapt to different installation locations.

### Modifying the Default Configuration

If you want to change the default configuration that is installed with Open5GS, you should modify the `.yaml.in` files located in the `/home/wnc/Downloads/source_code/open5gs-2.7.6/configs/open5gs/` directory.

Any changes you make to these `.yaml.in` files will be reflected in the final `.yaml` configuration files after you build and install the project.

**Important Note:** Modifying these files will change the default configuration for *every* subsequent build and installation. If you only want to make temporary or site-specific changes, it's often better to edit the installed `.yaml` files in your `./install/etc/open5gs` directory directly after running `ninja install`.

## Custom Build and Run

### Building and Installing

To build and install a custom version of Open5GS, follow these steps:

```bash
# Navigate to the Open5GS source directory
cd open5gs.x.x.x

# Configure the build with a custom installation prefix
meson build --prefix=`pwd`/install

# Compile the project
ninja -C build

# Install the project to the custom prefix
cd build
ninja install
```

### Running the Custom Build

Once the custom build is installed, you can run the Open5GS components from the `./install/bin` directory:

```bash
./install/bin/open5gs-*
```

*   **Configuration:** The default configuration files will be loaded from `./install/etc/open5gs/`.
*   **Logging:** The default log files will be created in `./install/var/log/open5gs/`.

### Using a Custom Build with Systemd

If you have Open5GS installed as a systemd service but want to use your custom-built binaries, you can use the `modify_open5gs_version.sh` script. This script updates the systemd service files to point to your custom binaries and configuration files.

**Before running the script, you may need to edit it to set the correct paths for your custom build.**

```bash
# Make the script executable
chmod +x modify_open5gs_version.sh

# Run the script to update the systemd service files
./modify_open5gs_version.sh
```

The script will modify the `ExecStart`, `User`, and `Group` directives in the `open5gs-*.service` files located in `/lib/systemd/system/`.

## Sponsors

If you find Open5GS useful for work, please consider supporting this Open Source project by [Becoming a sponsor](https://github.com/sponsors/acetcom). To manage the funding transactions transparently, you can donate through [OpenCollective](https://opencollective.com/open5gs).

<p align="center">
  <h3 align="center">Special Sponsor</h3>
</p>

<p align="center">
  <a target="_blank" href="https://mobi.com">
  <img alt="special sponsor mobi" src="https://open5gs.org/assets/img/mobi-open5GS.png" width="400">
  </a>
</p>

<p align="center">
  <a target="_blank" href="https://open5gs.org/#sponsors">
      <img alt="sponsors" src="https://open5gs.org/assets/img/sponsors.svg">
  </a>
</p>

## Community

- Problem with Open5GS can be filed as [issues](https://github.com/open5gs/open5gs/issues) in this repository.
- Other topics related to this project are happening on the [discussions](https://github.com/open5gs/open5gs/discussions).
- Voice and text chat are available in Open5GS's [Discord](https://discordapp.com/) workspace. Use [this link](https://discord.gg/GreNkuc) to get started.

## Contributing

If you're contributing through a pull request to Open5GS project on GitHub, please read the [Contributor License Agreement](https://open5gs.org/open5gs/cla/) in advance.

## License

- Open5GS Open Source files are made available under the terms of the GNU Affero General Public License ([GNU AGPL v3.0](https://www.gnu.org/licenses/agpl-3.0.html)).
- [Commercial licenses](https://open5gs.org/open5gs/support/) are also available from [NewPlane](https://newplane.io/) at [sales@newplane.io](mailto:sales@newplane.io).

## Support

Technical support and customized services for Open5GS are provided by [NewPlane](https://newplane.io/) at [support@newplane.io](mailto:support@newplane.io).
