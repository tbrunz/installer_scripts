
Installing VirtualBox Extension Packs
============================================================================

Starting with version 4.0, VirtualBox is split into several components.

1.) The base package consists of all open-source components and is licensed under 
the GNU General Public License V2.

2.) Additional extension packs can be downloaded which extend the functionality 
of the VirtualBox base package. 

Currently, Oracle provides the one extension pack, which can be found at 
http://www.virtualbox.org and provides the following added functionality:

  a.) The virtual USB 2.0 (EHCI) device; see the section called "USB settings".

  b.) VirtualBox Remote Desktop Protocol (VRDP) support; see the section called 
      "Remote display (VRDP support)".

  c.) Intel PXE boot ROM with support for the E1000 network card.

VirtualBox extension packages have a '.vbox-extpack' file name extension. 

To install an extension, simply double-click on the package file, and the 
VirtualBox Manager will guide you through the required steps.

To view the extension packs that are currently installed, please start the 
VirtualBox Manager (i.e., start VirtualBox). 

From the "File" menu, please select "Preferences". In the window that shows up, 
go to the "Extensions" category which shows you the extensions which are currently 
installed and allows you to remove a package or add a new one.


VBoxManage extpack
------------------------------------------------------------------------

Alternatively you can use VBoxManage on the command line:

The "extpack" command allows you to add or remove VirtualBox extension packs, as 
described in the section above.

To add a new extension pack, use the command 'VBoxManage extpack install <tarball>'.

To remove a previously installed extension pack, use the command 'VBoxManage extpack 
uninstall <name>'. 

You can use 'VBoxManage list extpacks' to show the names of the extension packs which 
are currently installed; please see the section in the manual called “VBoxManage list” 
also. 

The optional '--force' parameter can be used to override the refusal of an extension 
pack to be uninstalled.

The 'VBoxManage extpack cleanup' command can be used to remove temporary files and 
directories that may have been left behind if a previous install or uninstall 
command failed.




