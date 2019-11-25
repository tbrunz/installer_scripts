
wine-launcher-creator
===============================================================================

Create Wine desktop launchers with ease

About

WLCreator is a Python program (script) that creates Linux desktop launchers for 
Windows programs (that run under WINE). The program does the following tasks:

    1. Finds/extracts '.ico' files (using 'icoutils'), 
    2. Converts ICO files to PNG files (using 'icoutils'), 
    3. Presents a GUI where one can choose an icon for the launcher, 
    4. Creates a desktop launcher
    
    
Installation

On Debian-based distros you should install the '.deb' package.

For distros that use RPM (Fedora, OpenSUSE), there is a RPM package.  However,  
the RPM package is derived from the '.deb' package using 'alien'; in RPM 
distros you need to install 'icotools' by yourself (I don't know why it isn't 
installed automatically).  As needed, you'll have to manually install Python, 
PyQt4 (or 'python-qt4') and 'xdg-tools'.

For other distros there is a source package provided.  You can install the 
script by unpacking and running "sudo make install".  To uninstall, you can run 
"sudo make uninstall". 


Usage

WLCreator will try to extract icons from '.exe' files, and will search for all 
'.ico' files in the EXE's directory and its subdirectories and to convert them 
to PNG files.  It will also search for PNG files in the application's main 
directory.  After that, the user is presented with a graphical interface that 
allows one to choose the icon and the launcher's name. 

A few options are also available:

* Top-level application path = The path to search for the program's icon.  
    Windows games often have their executable in some subdirectory under the 
    main game directory.  Usually you should choose the main game directory 
    for the icon search.

* Destination path for the created launcher.  The default is "~/Desktop/".  
    A copy is also placed in "~/.local/share/applications/wlcreator/".

* Path for the launcher icon.  The default is "~/.local/share/icons/wlcreator/".

* Wine command for launching the app.  The default is "wine".

* Path for the WINE configuration directory.  The default is "~/.wine".

WLCreator options are saved in the "~/.config/wlcreator/" directory.

WLCreator uses 'wrestool' (in 'icoutils') to extract icons from EXE files, and 
uses 'icotool' (in 'icoutils') to convert ICO files to PNG files.  It uses the 
Qt framework and PyQt bindings for Python, and also uses some bash commands.

Sometimes 'wrestool' cannot extract icons.  This is the situation where icon 
extraction/finding must be done manually by the user.  When an ICO/PNG file is 
obtained, put it alongside the EXE file and then start 'wlcreator'.

In addition, 'icotool' sometimes cannot extract a PNG from an ICO.  In this 
situation the easiest solution is to open the ICO file with GIMP, then save it 
as a PNG.  (To aid in this, 'wlcreator' will save all extracted ICO files in 
the EXE's directory.)


Command line

You can optionally run 'wlcreator' from the command line using 
"wlcreator.py <path_to_exe_file> [<path_to_application_top-level_directory>]"


Browser Integration

File browser integration testing has been performed on Ubuntu 12.04 (Unity), 
OpenSUSE 12.3 (KDE 4), and Fedora 17 (Gnome 3).

To use 'wlcreator' as a Nautilus action, you will need to install the package 
'nautilus-actions'.  After that you can use the appropriate option in 
the Settings section to install 'wlcreator' as a Nautilus action: 
    * for Gnome 2, select "Gnome 2".  (This maybe works in MATE.) 
    * for Gnome 3/Unity, select "Gnome 3".  (This maybe works in Cinnamon.)
      or, alternatively, you can use 'System > Preferences > Nautilus Actions' 
      configuration to import '/usr/local/share/wlcreator/wlcaction.xml'.

To use 'wlcreator' as a Nautilus script, you will need to install the package 
'nautilus-scripts-manager'.  You can enable the script using appropriate option 
in the Settings section.  Alternatively, you can enable it using 'System > 
Preferences > Nautilus scripts manager'.

To use 'wlcreator' as a KDE 4 Dolphin Service, select the appropriate option in 
its Settings section.

IMPORTANT: Gnome 3 users need to logout/login in order to activate the new 
launcher.  Alternatively, press <Alt><F2> and enter "r" to restart the shell.


Disabling network access

Additional information about restricting internet access to (untrusted) 
(Windows) applications can be found in the file "NoInternet.txt" (installed  
in '/usr/local/share/wlcreator/NoInternet.txt').

