
Arronax - Create and modify '.desktop' files
=========================================================================

Arronax is a program to create and modify starters (technically: '.desktop' 
files) for applications and locations (URLs).

Arronax can be used as a standalone application or as a plugin for Nautilus, the
default file manager of the Gnome and Unity desktop environments.

Arronax as Nautilus extension
-----------------------------

As Nautilus plugin Arronax adds a menu item "Create starter for this file" or 
"Create a starter for this program" to the context menu (that's the menu you get 
when you right-click a file in the file manager). If the file is a application 
starter you get an item "Modify this starter" instead.

If you have icons on your desktop enabled Arronax adds a menu item "Create 
starter" to your desktop's context menu.

Arronax as standalone application
---------------------------------

Arronax as standalone application can be started just like any other application 
using the application menu or application search function of your desktop 
environment.

Arronax supports Drag&Drop
--------------------------

You can drag an icon for example from the Unity Dash or the Gnome Classic 
application menu and drop it on an open Arronax window. Don't drop it on one of 
the input fields in the Arronax window but on the free space beneath the icon.

You can drag files from the file manager and other applications and drop them 
on the input area in the "MIME types" tab to add the corresponding MIME types 
to the list. This will add every MIME type only once, even if you add multiple 
files with the same MIME type.

You can drag image files from the file manager or other applications and drop 
them on the icon selector at the left of the Arronax window to use that image 
as icon for the starter. It is up to you tom take care that the image has the 
right size.

You can drag a file or folder from the file manager or a URL from your web 
browser and drop it on the "Command", "Start in Folder" or "File or URL" input 
area to use the corresponding file path.

Requirements
------------

Arronax needs:
        Gnome 3.4 or later
        Python 2.7
        PyGObject
        distribute
        Nautilus-Python 1.1 or later

If you install the .deb package this packages will be automatically installed 
if needed.

Packages
--------

Arronax comes as three different Debian packages:

'arronax-nautilus' contains the Nautilus plugin. This package depends on 
'arronax-base'. After installtion you need to log in again so that Nautilus 
loads the plugin.

'arronax-base' contains the basic files along with the standalone version of 
Arronax.  Install this package if you only want to standalone version of 
Arronax but not the Nautilus plugin.

'arronax' is a metapackage.  It doesn't contain any files but just depends on 
the the other two packages.  Install this package if you want a complete 
installation of Arronax.

The tar.gz file contains the files for all the .deb packages.

Arronax is available from the PPA ("Personal Package Archive") 
ppa:diesch/testing for all current versions of Ubuntu. If you add this PPA to 
your software sources Ubuntu's Update manager will automatically install newer
versions of Arronax when they are available.

http://www.florian-diesch.de/software/arronax/


