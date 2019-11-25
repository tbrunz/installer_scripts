
Winetricks
===============================================================================

https://wiki.winehq.org/Winetricks

    Winetricks is a helper script to download & install various redistributable 
    runtime libraries needed to run some programs in Wine. These may include 
    replacements for components of Wine using closed source libraries. 
    The script is maintained by Austin English at http://winetricks.org. 
    

Obtaining winetricks

    The latest release of winetricks is available at:

https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks

    Right-click on that link and use 'Save As' to save a fresh copy. 
    

    Or you can get it from the commandline with the command: 

$ wget  https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
$ chmod +x winetricks


Installing winetricks

    It's not necessary to install winetricks to use it. However, you may choose 
    to install winetricks in a global location so you can just type 'winetricks' 
    on the command line. Some Linux distributions include winetricks in their 
    Wine packages, so you don't have to download it separately. (Nevertheless, 
    you might still want to use the above URL if their repo version is old.)

    If you've downloaded your own copy of winetricks, you can install it 
    manually like this:

$ chmod +x winetricks
$ sudo cp winetricks /usr/local/bin/


Using winetricks

    Once you've obtained winetricks you can run it simply by typing 
    "$ sh winetricks" at the console. You can also use "$ ./winetricks" if 
    you "$ chmod +x winetricks" first.

    
    As with all Wine commands, winetricks knows about the 'WINEPREFIX' 
    environment variable. This is useful for using winetricks with different 
    Wine prefix locations. For example,

$ env WINEPREFIX=~/.winetest sh winetricks mfc40 

    installs the mfc40 package in the `~/.winetest` prefix. 

    
    If run without parameters, winetricks displays a GUI with a list of 
    available packages. If you know the names of the package(s) you wish to 
    install, you can append them to the winetricks command and it will 
    immediately start the installation process. For example,

$ sh winetricks corefonts vcrun6 

    will install both the 'corefonts' and 'vcrun6' packages. 


    Users with more than one version of Wine on their system (for example, 
    an installed package and an uninstalled Wine built from git) can specify 
    which version winetricks should use. For example,

$ env WINE=~/wine-git/wine sh winetricks mfc40 

    installs the mfc40 package using the Wine in the ~/wine-git directory. 


Note: Although using winetricks may be very useful for getting some programs 
    working in Wine, doing so may limit your ability to get support though 
    WineHQ. In particular, reporting bugs may not be possible if you've replaced 
    parts of Wine with it.
    

