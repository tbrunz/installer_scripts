
phpVirtualBox
====================================================

http://sourceforge.net/p/phpvirtualbox/wiki/Home/
http://sourceforge.net/projects/phpvirtualbox/


What is phpVirtualBox?

phpVirtualBox is a web-based front-end to VirtualBox that allows you to control 
your VirtualBox environment.


Getting started

phpVirtualBox is a PHP application, so like all PHP applications, it needs to be 
run under a PHP-capable web server. It manages your VirtualBox installation by 
communicating with VirtualBox's API server (vboxwebsrv, which is distributed 
with VirtualBox) over a network connection.

 -----------------------------------------------------
 | Web Server                                        |
 |    phpVirtualBox (config.php contains VirtualBox  |
 |     |              access information)            |
 ------|----------------------------------------------
       |
   Authentication and VirtualBox communication
       |
       |  -----------------------------------------------
       |  | VirtualBox Installation                     |
       |  |                                             |
       '---- vboxwebsrv (running as user X)             |
          |    |                                        |
          |    '--- User X's VirtualBox configuration   |
          |         and virtual machines                |
          |                                             |
          -----------------------------------------------

Since communication is performed over the network, phpVirtualBox and VirtualBox 
do not HAVE to reside on the same physical machine. Though, in most cases, they 
do. phpVirtualBox can even control multiple VirtualBox installations running on 
multiple hosts.


Installing VirtualBox

First you will need to install VirtualBox from http://www.virtualbox.org. Any 
questions regarding VirtualBox or its installation should be raised at the 
support forums on the VirtualBox web site.

VirtualBox >= 4.0 - Remote Console Access Note

In order to access a VM's console over RDP (via phpVirtualBox's console tab, or 
other RDP client) you must install the Oracle VM VirtualBox Extension Pack from 
http://www.virtualbox.org/wiki/Downloads

Please refer to VirtualBox's documentation for instructions on installing 
extension packs.


Setting up VirtualBox

phpVirtualBox requires that 'vboxwebsrv' (a program distributed with VirtualBox) 
is running on your VirtualBox host.  On *nix hosts, this application is 
typically found in '/usr/bin'.  On Windows, it is typically found in 
'C:\Program Files\Oracle\VirtualBox'.  This program MUST be run as the same user 
that administers your VirtualBox virtual machines.  On Windows and OS X, this 
simply means the same user that you log into your machine as when you run 
VirtualBox.  (I.e., you cannot log in as one user and control another user's 
virtual machines.)

NOTE: If your web server and your VirtualBox installation are on 2 different 
hosts, you may need to add:

    -H <IP.ADDRESS.OF.HOST>

to the command line of vboxwebsrv, where <IP.ADDRESS.OF.HOST> is the IP address 
of your VirtualBox host, accessible by your web server.  If this is not 
specified, vboxwebsrv will listen on <localhost>, which is not accessible 
outside of the machine itself.


Linux

Linux users should use the instructions for vboxweb-service found at 
https://sourceforge.net/p/phpvirtualbox/wiki/vboxweb-service%20Configuration%20in%20Linux/


Windows

On Windows (assuming your VirtualBox installation is located in 
'C:\Program Files\Oracle\VirtualBox'), the following command will start 
'vboxwebsrv':

   "%ProgramFiles%\Oracle\VirtualBox\vboxwebsrv.exe" -H 127.0.0.1 >nul

Note that ">nul" is needed so that 'vboxwebsrv' does not send its output to the 
command prompt window.  Without it, performance will be severely degraded.

User-contributed documentation on setting up 'vboxwebsrv.exe' to start when your 
computer boots can be found here:
https://sourceforge.net/p/phpvirtualbox/wiki/Windows%207%20-%202008%20%2B%20Service/


Upgrading phpVirtualBox

phpVirtualBox can be "upgraded" by copying the downloaded files over your 
existing phpVirtualBox installation.  Choose to overwrite existing files if 
prompted.

You may wish to create an entirely new folder for a new version of phpVirtualBox 
and that is fine too.

It is always a good idea to clear your web browser's cache after upgrading.

After upgrading, it is a good idea to stop 'vboxwebsrv' for the time being.  If 
you are using the startup script distributed on this site, you may run the 
following command:

    /etc/init.d/vboxwebsrv stop

If your VirtualBox host is running Linux, please see 
http://sourceforge.net/p/phpvirtualbox/wiki/vboxweb-service%20Configuration%20in%20Linux/ 

for a new-and-improved startup script configuration.

Then (re)start 'vboxwebsrv'.  If you are now using the "vboxweb-service" script 
described in the above link, you may run:

    /etc/init.d/vboxweb-service start

If you are not, you may start 'vboxwebsrv' using the same method you had been 
using for older versions of VirtualBox (e.g., 3.x).


Installing phpVirtualBox

phpVirtualBox requires a web server with PHP >= 5.1.0 installed in order to run. 
If you do not already have a PHP-capable web server running, this may help you 
get started:
https://sourceforge.net/p/phpvirtualbox/wiki/Web%20server%20and%20PHP%20installation/

Unzip the downloaded file and copy the resulting files/folders to a folder 
accessible by your web server.


SELinux Considerations

If SELinux is installed and you would like to keep it enabled, you may have to 
add a rule for 'vboxwebsrv'.

Install 'semanage' (yum install policycoreutils-python) and run the command 
below:

    semanage port -a -t http_port_t -p tcp 18083

This will add the VirtualBox's web service port (18083) to be accessible by a 
service running in an http context (eg. 'apache').


Basic configuration

'config.php' in phpVirtualBox's folder on your web server tells phpVirtualBox 
how to communicate with your VirtualBox installation. To get started, rename 
'config.php-example' to 'config.php' and then edit it to reflect your settings. 
The minimal amount of configuration you will need is to specify the username 
and password needed, as well as the location of 'vboxwebsrv'.

    /* Username / Password for system user that runs VirtualBox */
    var $username = 'vbox';
    var $password = 'pass';

    /* SOAP URL of vboxwebsrv (not phpVirtualBox's URL) */
    var $location = 'http://127.0.0.1:18083/';

The username and password must be the username and password of the user that 
'vboxwebsrv' is running as.  If VirtualBox and phpVirtualBox are on the same 
physical host, you may leave the '$location' setting alone. Once this is 
configured,

* Navigate to the resulting folder in your web browser.  Typically,
    http://your.web.server.ip/phpvirtualbox
    
* Default login is "admin"/"admin".  See "Authentication in phpVirtualBox"
https://sourceforge.net/p/phpvirtualbox/wiki/Authentication%20in%20phpVirtualBox/
  for more information on controlling users and passwords within phpVirtualBox.
  
  
Advanced configuration

Other configuration options and settings are well documented in config.php 
itself. More help can be found at:

* Using External Authentication
https://sourceforge.net/p/phpvirtualbox/wiki/Authentication%20Modules/

* Enabling Custom VM Icons
https://sourceforge.net/p/phpvirtualbox/wiki/Custom%20VM%20Icons/

* Enabling Advanced Settings in phpVirtualBox
https://sourceforge.net/p/phpvirtualbox/wiki/Advanced%20Settings/

* Multiple Server Configuration
http://sourceforge.net/p/phpvirtualbox/wiki/Multiple%20Server%20Configuration/

Getting Help

Please see the Common Errors and Issues wiki page first!
https://sourceforge.net/p/phpvirtualbox/wiki/Common%20phpVirtualBox%20Errors%20and%20Issues/

If your error or issue is not listed, please use the Forums.
https://sourceforge.net/p/phpvirtualbox/discussion/


================================= Versioning =================================

Match the major.minor number of 'phpVirtualBox' to the major.minor version of 
'VirtualBox':
 
phpVirtualBox versioning is aligned with VirtualBox versioning in that the major 
and minor release numbers will maintain compatibility. phpVirtualBox 4.0-x will 
always be compatible with VirtualBox 4.0.x, regardless of what the latest 'x' 
revision is. (phpVirtualBox 4.2-x will always be compatible with VirtualBox 
4.2.x, etc.. 

*) for VirtualBox 5.0 - phpvirtualbox-5.0-x.zip 
*) for VirtualBox 4.3 - phpvirtualbox-4.3-x.zip 
*) for VirtualBox 4.2 - phpvirtualbox-4.2-x.zip 
*) for VirtualBox 4.1 - phpvirtualbox-4.1-x.zip 
*) for VirtualBox 4.0 - phpvirtualbox-4.0-x.zip 
*) for VirtualBox 3.2 - phpvirtualbox-3.2-x.zip 

================================== LATEST ================================== 

To automatically download the latest version of phpVirtualBox, you may use: 

wget 'http://sourceforge.net/projects/phpvirtualbox/files/latest/download'


-----

How to install phpVirtualBox

Arch Linux wiki

https://wiki.archlinux.org/index.php/PhpVirtualBox

-----

How to install phpVirtualBox

http://linuxhomeserverguide.com/server-config/phpVirtualBox.php

-----

Managing A Headless VirtualBox Installation With phpvirtualbox (Ubuntu 12.04) 
Falko Timme

http://www.howtoforge.com/managing-a-headless-virtualbox-installation-with-phpvirtualbox-ubuntu-12.04

phpvirtualbox - Running Virtual Machines With VirtualBox 4.2 and phpvirtualbox 
on A Headless Ubuntu 12.04 Server
Luis Rodriguez

http://www.howtoforge.com/phpvirtualbox-running-virtual-machines-with-virtualbox-4.2-and-phpvirtualbox-on-a-headless-ubuntu-12.04-server

-----



