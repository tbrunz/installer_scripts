
README for all Ubuntu installer scripts
================================================================================
18 MAY 2014 for v2.1.0

These scripts automate the installation of a number of Ubuntu applications 
& packages that are not installed by default in the Ubuntu Desktop Edition, 
and are useful to have, yet cannot be installed easily from the Ubuntu Software 
Center.  

The reasons for this vary:

* The package is not in the Ubuntu repositories, ie.,
  - The package is available only from the developer's web site; 
  - The package (or a newer version) is available only from a PPA;

* A newer version of the package needs to be backported from a later distro, 

* Canonical can't include the package due to redistribution restrictions, 

* The package requires additional hand-configuration after installation, 

* The package requires the installation of additional packages:
  - Some apps will not install or function without additional packages;
  - Some apps are enhanced with plugins, which lack installers; 
  - Some apps benefit from adding some of the "suggested" packages;

* The set of packages is too large to install one-by-one using the Ubuntu 
  Software Center GUI tool.

The names of the scripts suggest their application/package; however, each 
script has a usage prompt that provides more information.  (And the 'usage'
prompt will safely display without actually installing or changing anything.)


HOW TO USE
--------------------------------------------------------------------------------

1.) Install Ubuntu ('Desktop' or 'Server', 32- or 64-bit, natively or in a VM).

2.) Update your installation (via the Update Manager).

3.) Be sure that the 'universe' and 'multiverse' repos are enabled (default).

4.) Copy the 'linux' folder to your system.  Assuming you're reading this file 
    either from the Google Drive repo or from a copy on a thumb drive, it 
    should be somewhere inside a top-level folder called "linux" -- that's the 
    folder you want (it's about 1 GB total).  It doesn't matter where you put 
    it on your hard drive.

5.) Open a terminal window (Ctrl-Alt-T is the keyboard shortcut).

6.) Surf inside the 'linux' directory to the 'z-scripts' directory to launch 
    scripts.  All of the scripts are launched using this command format: 
    
        bash ./install-base.sh -u  [this is an example!]
        
    (Note that if you run the script above, it will first update the repo list,
    then download needed packages, then install the packages.  Read on about 
    how you can avoid updating the repo list every time you run a script; it 
    usually only needs to be done once or twice during installation.  Since 
    the update process takes a long time and is annoying to wait for, it's 
    worth knowing how you can skip it most of the time...)

All of these scripts will respond with a 'usage' prompt if invoked with '-h' 
(or '--help') as a parameter, or with no parameters.  For example, 

        bash ./install-base.sh
        bash ./install-base.sh -h
    
will both display information about the "base" packages install script and will 
list the packages that it will install.

NOTE THAT RUNNING THESE SCRIPTS WILL NOT INSTALL OR CHANGE YOUR SYSTEM 
UNLESS AN INSTALLATION SWITCH IS INCLUDED ON THE COMMAND LINE.  This allows 
you to safely run each script to get more information about it, including 
instructions on how to install it.

Currently there are exceptions to the above rule:
        
    * 'fix-ubuntu.sh' has no 'usage', but queries Y/N? before doing anything.


"FIX-UP" SCRIPTS
--------------------------------------------------------------------------------
Some of these scripts don't actually install packages; they "fix up" parts of 
Ubuntu to "improve" its behavior or configurations.  (It's up to you if you 
want these changes; none of these need to be run.)

Currently, these fix-up scripts are:
    
bash ./fix-apt.sh
    * Removes duplicate repository source URLs from the main sources file, if 
      it finds the same line in one of the third-party '.list' files.  (This 
      prevents a recurring error about duplicates when updating the system.)

sudo bash ./fix-bash.sh
    * Mainly changes '.bashrc' alias defs for ll/l/la for some/all users.
    
bash ./fix-ubuntu.sh
    * Prompts you to install the 'gnotifier' extension in Firefox.
    * Instructs you on how to enable 'click to minimize' in the launcher.
    * Allows you to disable those annoying 'apport' crash dialogs.
    * Rips out the Unity "shopping" lens package or shopping Scopes.
    * Fixes a minor misconfiguration issue with the GNOME resource file.
    * Allows you to change the scrollbars to the normal non-hiding type.
    * Offers to restore displaying the user name in the notification area.
    * Allows you to turn the icons in the Nautilus menus on/off easily.

bash ./install-hosts-files.sh  (and the 'hosts-fix.sh' script)
    * Installs a custom '/etc/hosts' file (for static IP numbering, 
      plus adds a "block list" of malware/adware/tracking sites. 
    * Can be told to distinguish between multiple base hosts files.
    * The 'hosts-fix.sh' script is for updating an installed hosts file 
      with a newer "block list" Zip file (without a full re-install).
    * NOTE: Both of these are being revised to simplify & clean up.
    * Next rev will include a 'VM' option for Windows co-installation.


INSTALL SCRIPTS
--------------------------------------------------------------------------------
Each of these will explain itself if you you run it without arguments.

Install strategy:  The install scripts that add PPA repositories require a 
repo 'update' before their packages can be installed.  Since updates are time-
consuming, and often redundant, they can be consolidated into a single update 
by first installing all the PPA-type packages in '-p' mode (the '-p' switch 
means "only add the PPA repository; don't install").  By installing the last
PPA package in '-u' mode, it will trigger a full repo update that applies 
to all of them; then this last PPA package, and all other packages (PPA or 
not), can be installed in '-n' mode (the '-n' switch means "no update before 
installing the packages").  This speeds up package installation considerably by 
performing only one 'update' (or whenever it's actually necessary).  If you 
want to 'force' a repo update prior to installing a package set, then run the 
install script with the '-u' switch (which means "do a repo update before 
installing the packages").

Note that 'core-install.bash' is the common "include" script that all the 
install scripts source for common variable and function definitions.  (You 
would never run it directly.)


Script List
--------------------------------------------------------------------------------

(PPA setup)     add-ppa-list.sh                 Batch install of PPA repos
(backport)      install-apache.sh               Backports v2.2.22-6 to Precise
(pkg set)       install-apt-cacher.sh           Installs from repo
(pkg set)       install-base.sh                 Installs from repo
(add'l pkgs)    install-clementine              Installs from repo
(add'l pkgs)    install-crossover-deb.sh        Installs from cached '.deb'
(add'l pkgs)    install-crossover-bin.sh        Installs from cached '.bin'
(pkg set)       install-fonts.sh                Installs from repo & cache
(web only)      install-fwknop.sh               Installs from author's source
(backport)      install-gawk.sh                 Backports v4.0.1 to Precise
(plugins)       install-gedit-plugins.sh        Version-dependent plugin inst.
(add'l pkgs)    install-gnome3.sh               Installs from repo
(web only)      install-hp15c.sh                Simulates the classic in Tcl/Tk
(add'l pkgs)    install-java.sh                 Installs version 6 or 7
(web only)      install-jbidwatcher.sh          Java app; requires Java install
(pkg set)       install-kvm-qemu.sh             Installs from repo
(web only)      install-mawk.sh                 Updates v1.3.3 from source
(pkg set)       install-multimedia.sh           Installs from repo & cache
(web only)      install-noip-duc.sh             Installs dynamic updater fr src
(pkg set)       install-perf-test.sh            Installs from repo
(add'l pkgs)    install-postgres.sh             Installs from repo
(PPA only)      install-ppa-audio-recorder      Records audio streams
(PPA update)    install-ppa-banshee.sh          Latest version from team PPA
(PPA only)      install-ppa-calendar.sh         Google Calendar in your toolbar
(ext repo)      install-ppa-chrome.sh           Installs from repo
(PPA update)    install-ppa-diodon.sh           Latest version from team PPA
(ext repo)      install-ppa-dropbox.sh          Installs from repo
(PPA update)    install-ppa-gnome3.sh           Latest version from team PPA
(PPA only)      install-ppa-googledrive.sh      Mount GoogleDrive folders in FS
(ext repo)      install-ppa-googletalk.sh       Installs from repo
(PPA only)      install-ppa-grub-customizer     GUI for customizing GRUB menu
(backport)      install-ppa-linux-kernel.sh     Backports a newer 3.x kernel
(PPA only)      install-ppa-manager.sh          GUI for managing PPAs & pkgs
(pkg set)       install-ppa-multimedia.sh       PPA version needed for Trusty
(PPA only)      install-ppa-pidgin.sh           Adds Pidgin + an indicator
(PPA only)      install-ppa-pipelight.sh        Adds Silverlight to Firefox
(PPA update)    install-ppa-rabbitvcs.sh        Latest version from team PPA
(add'l repo)    install-ppa-skype.sh            Installs from 'partner' repo
(PPA only)      install-ppa-ubuntu-tweak.sh     Enhanced control panel
(PPA only)      install-ppa-variety.sh          Downloads & changes wallpapers
(ext repo)      install-ppa-virtualbox.sh       Latest Sun/Oracle version
(PPA only)      install-ppa-weather.sh          Weather indicator
(PPA update)    install-ppa-wine.sh             Latest version from team PPA
(PPA only)      install-ppa-xorg-edgers.sh      Bleeding-edge video drivers PPA
(PPA only)      install-ppa-x-updates.sh        Latest stable video drivers PPA
(add'l pkgs)    install-refind.sh               UEFI boot manager
(web only)      install-remotebox.sh            App to remote-control Vbox
(add'l pkgs)    install-skype.sh                Installs '.deb' from MS site
(backport)      install-subversion.sh           Backports v1.7.x to Precise
(configure)     install-vbox-autostart.sh       Configures for autostarting VMs
(configure)     install-vbox-dmi-data.sh        Configures DMI data for WinXP
(configure)     install-vbox-webservice.sh      Configures & starts Webservices
(add'l pkgs)    install-vim.sh                  Installs vim, gvim, + scripts
(add'l pkgs)    install-virtualbox.sh           Older, stable "OSE" version
(add'l pkgs)    install-wine.sh                 Older, stable repo version

--------------------------------------------------------------------------------

