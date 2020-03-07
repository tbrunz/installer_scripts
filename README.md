# installer_scripts
My set of scripts for installing & configuring software (Linux & Windows packages)

I have a (64GB) thumb drive full of cached Windows and (Ubuntu) Linux application installers, plus a set of scripts to automate downloading them (if not already cached) and installing them.  It handles installing `.deb`, `.tgz`, & `.zip` package files, installing from Ubuntu repositories or PPAs, running shell scripts, compiling from source, etc. -- in all cases, presenting a uniform CLI interface and effectively hiding _how_ the packages are installed.

### Pharo-Launcher Installer

To get started, I've created a "standalone" script to automate the installation of `Pharo-Launcher` in Linux.  This script, merged from the original thumb drive script + a companion library script, does not rely on or take advantage of a cached package; there's no thumb drive here. However, this script does assume that you have already downloaded a PharoLauncher zip file.

To use the PharoLauncher installer script, download a `PharoLauncher` zip file from https://pharo.org (32-bit or 64-bit) and copy it to the directory you wish to use for your Pharo projects; I use `~/Pharo`.  Then copy the `install-pharolauncher.sh` script into the same directory and run it.  When run without any arguments, it will print a comprehensive usage and quit.  Adding `-n` or `-u` will trigger the actual installation: `$ bash install-pharolauncher.sh -u` -- you will likely be prompted for your password to enable `sudo` (as it will want to install 32-bit support libraries on 64-bit Ubuntu systems, which will allow you to run 32-bit Pharo images).

The `install-pharolauncher.sh` script will create a `pharolauncher` directory in the same location as the script, then unzip the contents of the downloaded zip file into this new directory.  The script will also create a "launcher" file (a `.desktop` file) and install it; this launcher can be found by searching for `pharo` in the `Show Applications` panel of Gnome.  Clicking the launcher icon will launch the Pharo-Launcher application.

This script requires `sudo` privileges, and can be re-run without side-effects (although you will be prompted to overwrite files from a prior installation).

### Pharo-Adjust-Cursor

This script will edit the bash scripts that launch Pharo applications (i.e., `pharolauncher`, `pharoiot`, etc.) to either enable or disable enlarging the GUI pointer.  

This is useful on Linux systems with a 4K hi-DPI screen, since currently Pharo can enlarge its fonts and other GUI features, but not the cursor.

The cursor is enlarged by first setting an environment variable, `SQUEAK_FAKEBIGCURSOR`, to a non-zero value prior to running the application script (i.e., `pharo-launcher`, `pharo-ui`, etc.).  This script achieves this by editing the app scripts to add an `env` prefix to the commands that launch a Pharo virtual machine.

This script can edit the Pharo application scripts in both directions, to add the `env` prefix or remove it, depending on the option switch included on the command line.  There are no side-effects if the same command is issued multiple times in a row.  Each edit will create a backup file, with a name extension appended that reflects the script version backed up.  Restoring a backup must be done manually.

As is typical with my scripts (and most bash scripts), adding the `-h` switch (or `--help`) will show the usage prompt, as will entering the command with no arguments.
