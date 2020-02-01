
 Pharo Versions and Nomenclature

     For Squeak/Pharo/Croquet please use the archives whose names begin with
     "Cog" or "cog".  
     
     The archives whose names begin with "nsvm" or "Newspeak" are for Newspeak 
     and are missing plug-ins required by Squeak/Pharo/Croquet.
     
     Virtual Machines with "mt" or "MT" in the name are multi-threaded VMs 
     that support non-blocking FFI (Foreign Function Interface) calls.  
     
     The archives containing "Spur" or "spur" are VMs using the new Spur object 
     representation and garbage collector, and should be used with Spur-format 
     Squeak/Pharo/Croquet (or Newspeak) images.
     
     Squeak V5, Newspeak, and the upcoming Pharo V6 release have moved to Spur.

     Archives whose names include "64" are 64-bit Spur VMs.  They should be
     used with 64-bit Spur images.  Sample 64-bit images can be found at
     
         http://www.mirandabanda.org/files/Cog/SpurImages


Linux
     
     There are two variants of the Linux VMs; those ending in "ht" have a
     heartbeat thread, while those that don't use an interval timer for the
     heartbeat.  (The Windows and Mac VMs have a threaded heartbeat.)
     
     As of 24 JUL 2017, Linux VMs by default now use the threaded heartbeat.
     
     The threaded heartbeat version is better (for example, signals from the 
     interval timer interfere with system calls, etc), but to use it one must 
     have a kernel later than 2.6.12 and configure Linux to allow the VM to 
     use multiple thread priorities.  
     
     To enable this, create a file called "<vm>.conf" where '<vm>' is the name 
     of the VM executable ("squeak" for the Squeak VM, "nsvm" for the Newspeak 
     VM) in '/etc/security/limits.d/' with contents (the '*' is significant):
     
*       hard    rtprio  2
*       soft    rtprio  2

     E.g., you can achieve this with the following two CLI commands:

cat | sudo tee /etc/security/limits.d/squeak.conf << END
*       hard    rtprio  2
*       soft    rtprio  2
END

sudo cp /etc/security/limits.d/squeak.conf /etc/security/limits.d/nsvm.conf

     Note that only new processes will have the new security settings. Users 
     must log out and log back in for the limits to take effect.  
     
     System services must stop and then restart for the changes to take effect.  
     
     To use this VM as a daemon, e.g., under daemontools, you'll need to raise 
     the limit manually.  Make sure you're using bash (as 'ulimit' is a bash 
     command), and, before your launch command, raise the max thread priority 
     limit with the command "ulimit -r 2".  E.g., versions of the following 
     script will work on Ubuntu:
     
        #!/bin/bash
        cd /path/to/squeak/directory
        ulimit -r 2
        exec setuidgid <account> ./coglinuxht/squeak \
                -vm display-null -vm sound-null squeak.image
        

 Windows
     
     The Windows VMs are "dpiAware", which means that by default the display 
     is not scaled and display pixels are mapped 1 to 1 to the screen.  If 
     this behavior is not desired you can enable scaling by either editing 
     the relevant manifest file (e.g. "Squeak.exe.manifest"), changing the 
     "true" in '<dpiAware>true</dpiAware>' to "false", or simply deleting 
     the manifest file.
     
------------------------------------------------------------------------

