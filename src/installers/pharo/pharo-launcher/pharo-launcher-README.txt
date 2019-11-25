
Pharo Launcher

The fastest way to get a working Pharo environment (image + virtual machine) 
is to use Pharo Launcher.  Pharo Launcher is a tool allowing you to easily 
download Pharo core images (stable image, development image, old stable images, 
mooc image) and automatically get the appropriate virtual machine to run these 
images.


Installation

MacOS: 
Double-click on the '.dmg' file and drop the "Pharo Launcher" app in your 
Applications folder.  To be able to run Pharo Launcher, you may need to 
temporarily update your security settings: If you have MacOS 10.8 or higher, 
then you might get a message saying Pharo "can’t be opened because it is from 
an unidentified developer".  This is due to the MacOS Gatekeeper feature that 
is designed to discourage users from downloading from random locations and 
possibly installing malware.  Assuming you've downloaded "Pharo Launcher" from 
the Pharo web site, you have nothing to worry about; you just need to bypass 
this warning.  Do one of the following:

    Recommended - Right click (or command+click) the application icon and 
        select "open".
    Advanced - Enable all application downloads:
        * In MacOS, go to Apple Menu -> System Preferences -> Security & 
            Privacy -> General. 
        * Unlock the padlock at the bottom of the window, which will require a 
            computer admin password.
        * Where it says "Allow applications downloaded from:" select "Anywhere".
        * MacOS will give you a scary warning that is a bit exaggerated.  If 
            you're not comfortable with this, use the "right click" method 
            mentioned above.  In all cases MacOS will still ask you if you want 
            to open an "unsigned" application the first time it is opened, so 
            new applications that are downloaded can't just start by themselves.

Windows: 
Run the installer and follow instructions. Be sure to install Pharo Launcher 
in a place where you have write privileges.

GNU/Linux: 
Unzip the archive in a place where you have write privileges.


Usage

Run Pharo Launcher.  If Pharo was never installed on the computer, the right 
side, showing local images, will be empty.  On the left side are template 
images that are available on the web.  Select the template image you prefer 
and download it.  For instance, you can download "Official distributions" -> 
"Pharo 6.1 (stable)", which is the latest stable image.  

The launcher will download the image to a specific directory somewhere in your 
home directory (you can configure where by clicking the "Settings" button at 
the bottom of the window).  Each image gets its own folder.  Use the "Show in 
folder" menu item if you want to open this location.

After downloading, you can "Launch" the image from the context menu in the 
right-side list.  This will open the new image and close the launcher (which 
is a Pharo image).  You are ready to start working...

More documentation is available at 
https://github.com/pharo-project/pharo-launcher/

You can use Pharo development image "Pharo 7" if you want to contribute to 
Pharo, or if you can’t wait to discover/use new Pharo features.

-------------------------------------------------------------------------------

