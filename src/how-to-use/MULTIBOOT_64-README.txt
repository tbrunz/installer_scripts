
README for MULTIBOOT_64
===============================================================================

Updated 2018-1210


1. Bash files

   The 'bash_aliases' file provides useful bash functions (including shell 
   functions for sync'ing a local MULTIBOOT repo to thumb drives and remote 
   repos).  The 'bash_hosts' file provides a means to expand a frequently-
   referenced host nickname into its URL and associated port numbers for 
   router NAT traversal.
   
   The '.bashrc' file should already have commands to source ".bash_aliases", 
   which should also be uncommented in this file.
   
   To use:
   "bash_aliases" should be moved to "~/.bash_aliases". 
   "bash_hosts" should be moved to "~/.bash_hosts".
   Log out & log back in, open a new shell, or enter ". ~/.bash_aliases" to 
   enable the functions.
   
   Enter 'alist' to get a synopsis of the most frequently used functions. 
   (Browse the file to see everything & read code comments.)
   
   
2. '/etc/fstab' file

   This is NOT a replacement for your "/etc/fstab" file; it is a line that 
   needs to be added to your "/etc/fstab" file to auto-mount the MULTIBOOT 
   disk image file automatically at boot-up.
   
   For this to work correctly, you will need to create the directory 
   "/srv/Mounts" and copy the "MULTIBOOT_64.img" file to this location. 
   Then create the directory "/srv/MULTIBOOT_64" to serve as a mount point. 

   Once you've made the modification to your "/etc/fstab" file (and note that 
   you need to change "user", in two places, to match your username), either 
   reboot or enter "sudo mount -a" to mount the 'drive'.
   
   (Why use a file and not a folder of files?  Because the file system within 
   the '.img' file is 'vfat', rather than a Linux file system type, which is 
   not compatible with thumb drive use.)

   Create a softlink in "/home/<user>" to point to the mounted drive.  Note 
   that the 'sync' scripts all assume "ln -s /srv/MULTIBOOT_64 ~/a64".  To 
   use a different directory name, edit ".bash_aliases" and change the 
   target directory name for the variable DIRNAME_MB_LOCAL.
   
   For added convenience, I set multiple soft links like so:
      cd
      ln -s /srv asrv
      ln -s asrv/MULTIBOOT_64 a64
      ln -s a64/installers ainst
      ln -s ainst/windows awin
      ln -s ainst/linux alin
      ln -s alin/z-scripts ascr
   
   
3. Synchronizing the repo & copying files to/from remote hosts

   There are multiple ways to sync the repo with thumb drives, other disks, 
   etc.  A synopsis of the commands can be listed using "alist":
   
      ptusb  <psync options> = Psync  to  USB thumbdrive 
      pfusb  <psync options> = Psync from USB thumbdrive 

      sthost <user> <host> <remote path> <[list of] local files> 
      sfhost <user> <host> <remote path> <local path> 

      rthost <user> <host> <remote path> <local path> <rsync options> 
      rfhost <user> <host> <remote path> <local path> <rsync options> 

      pthost <user> <host> <psync options> 
      pfhost <user> <host> <psync options> 
   
   Each method has two forms, depending on the direction of synchronization. 
   The main script for performing the sync is "psync.sh", which is in the 
   root of the "MULTIBOOT_64.img" file (or "~/a64/psync.sh", using the soft 
   links).  "psync" can be used directly, but the above wrappers are likely 
   more convenient.
   
   "p?usb" is for sync'ing to/from an inserted thumb drive. 
   "s?host" is for SCP transfers using NAT traversal through a router.  
   "r?host" is for 'rsync' transfers using NAT traversal through a router.  
   "p?host" is for using 'psync' using NAT traversal through a router. 
   
   All of the above "??host" functions use "~/.bash_hosts" to facilitate 
   NAT traversal, allowing use of a nickname for a known, trusted remote 
   host.
   
   Entering just the function name, with no parameters, provides a 'usage' 
   prompt (and no action is taken).  It is recommended to use the "-n" 
   switch with the 'rsync' and 'usb' functions to preview the changes that 
   will take place without the "-n" switch.  (SCP does not provide this 
   feature.)
   
   
4. Installing packages

   Entering "cds" will 'cd' to the installer scripts directory and list the 
   scripts.  Each script starting with "install-" can be safely run without 
   any parameters; in this case, a full explanation of what the script does 
   and why it's useful will be displayed, but no action will be taken. 
   
   These scripts install repo packages, '.deb' files, PPA packages, and/or 
   compile source code and install the resulting binaries, depending on the 
   form of the package provided by the developer.  Regardless of the type 
   of installation, the scripts normalize and standardize the installation 
   so that the same command format is used to install the target.
   
   The install scripts require either "-u" or "-n" as the final parameter 
   in order to actually install packages.  "-u" means "update the repository 
   package list before installing"; "-n" means "do not update the repository 
   package list before installing".  
   
   Typically (and certainly before Ubuntu 16.04), "apt-get update" would 
   update dozens of repository manifests, and could take several seconds to 
   complete.  When installing a large set of packages, repeating this update 
   for each installation is both useless and can turn a few minute's task 
   into a half hour+.
   
   Therefore, typically the first package is installed with "-u", with 
   subsequent installations using "-n" to speed things up.  One exception 
   is installing from PPA (Personal Package Archives), which require three 
   steps (automated by the script): Adding the PPA as a known repository, 
   updating the manifest lists to become aware of the packages in the PPA, 
   and then performing the package installation.  For this reason, PPA 
   package installations usually use the "-u" switch, as the PPA is usually 
   unknown prior to installation.
   
   Some packages require addition manual steps after package installation, 
   or the user needs to be reminded of additional steps, conditions, or 
   usage notes.  These will be shown post-installation.  However, they can 
   be "previewed" by adding the "-i" switch to the command (in lieu of the 
   "-u" or "-n" switches).  In this case, the script will output the 
   description followed by the post-install instructions, and no installation 
   will be performed.
   
   Note that some scripts require a version number (or a selection string) 
   to entered as a parameter; these are noted in the usage prompt and 
   script description.  If these parameters are missing, the packages will 
   not be installed.
   
   Each script is designed to be installable "standalone"; i.e., any 
   package dependencies should be installed as part of the application's 
   package.  (If this is not the case, this is a bug and should be reported 
   to me to be fixed.)  There are a few exceptions, such as applications 
   that require Git or Java to already be installed.  In these cases, if 
   the dependencies are not already installed, they will be noted and the 
   script will abort, rather than install them automatically.  This is 
   usually because there are multiple versions or sources for the missing 
   dependencies, and an installer script for the dependencies.  Simply 
   run the installer script for the dependencies first, then try again.
   
   A few of the scripts are "fixup" scripts, intended to be used after 
   installing the OS or after installing certain scripts that behave badly. 
   (The Chrome & Wine installers are examples of these.)  These scripts 
   start with "fix-", must be run using "sudo bash <script>", and *will* 
   run when entered without parameters (as most of them do not require 
   parameters).  The exception is "fix-bash.sh", which requires "-f" to 
   actually make modifications.
   
   All scripts are designed to be "re-runnable", in that they can be 
   executed multiple times in a row without side effects.
   
   For specific details on what a script does, and 'how', browse the script 
   code.  All are well-documented.  (If any need improvement, let me know!)
   
   The philosophy is: "No surprises, changes only with informed consent, 
   everything consistent, and everything documented.
   
   
5. Booting thumb drives

   By making a bootable copy of the MULTIBOOT_64 image, you can boot the 
   thumb drive and install Windows 7 (any edition) and/or one of several 
   Linux distros.  You can also run most of the Linux distros via their 
   "Live CD" features this way.  This makes a bootable thumb drive a handy 
   repair/recovery tool for any installed OS.
   
   There are many tools for making bootable thumb drives; I use YUMI, which 
   is available at 'pendrivelinux.com'.  (There's also a copies of two YUMI 
   installers in the '.img' root in a folder named "YUMI".)
   
   To make a bootable MULTIBOOT_64 thumb drive, first make a bootable thumb 
   drive using YUMI.  This will necessitate a Windows system, as YUMI is a 
   Windows app.  This will properly format the drive and install a bootloader.  
   (You can install just one tool, if it requires an installation; you'll 
   overwrite it later.)
   
   Once the thumb drive is built, you can copy the entire contents of the 
   MULTIBOOT_64 repo image into the thumb drive.  I suggest starting with 
   the Windows files & folders first, then the ISO files, then the remaining 
   files.  Note that many bootable ISO files require a contiguous image on 
   disk in order to boot; if you make a copy such that it fragments on the 
   thumb drive, it may refuse to boot.  The only solution in this case is 
   to delete it and copy it back as a single file, but defragging thumb 
   drives is iffy, and it's usually best to just rebuild the entire drive 
   from scratch.
   
   Once built, you may occasionally discover that the bootloader on the 
   thumb drive has become corrupted, and the drive will no longer boot.  
   (The files in the partition may be fine, but the bootloader no longer 
   works.)  This does not necessitate a rebuild of the drive; YUMI can 
   be made to re-install the bootloader, but this requires running YUMI 
   on a Windows system, and also requires deleting a "hidden" system file 
   from the drive (all of which is inconvenient).
   
   A better strategy is to make a copy of the bootloader sectors on the 
   thumb drive, and using 'dd' to restore the bootloader.  This is simple 
   and quick (and does not require Windows).  After the bootable thumb 
   drive has been created and tested, use 'dd' (in Linux, using 'sudo') 
   to copy the set of sectors up to the first partition on the thumb 
   drive to a file, which you can keep on the thumb drive.
   
   For example, if you build a thumb drive with the file system partition 
   starting at sector 2048, this leaves the first MB for the bootloader. 
   (SSDs usually have to align their partitions on MB boundaries, so this 
   is quite common.)  In this case, you would save the bootloader for the 
   thumb drive using 
   
      sudo dd if=/dev/sdX of=mybootloader_2048.img bs=512 count=2048
      
   where "sdX" is the device name for the mounted thumb drive (such as 
   "sdb", "sdc", etc; use "df" to discover which device).  When done, copy 
   "mybootloader_2048.img" to a folder on the thumb drive.  I use a subfolder 
   in "Z-FILES" on the thumb drive for this purpose, storing bootloader 
   images of all the thumb drives I use.  The "2048" in the filename tells 
   me the argument for "count" to use when restoring the bootloader.  
   
   Restoration is just the reverse of the above, with the drive unmounted:
   
      sudo umount /dev/sdX1
      sudo dd if=<path to>/mybootloader_2048.img of=/dev/sdX bs=512 count=2048
      
   When done, remove the drive, then re-insert it; it should mount.  Reboot 
   and the drive should be available to boot from and should present the 
   YUMI menu once again.
     
   
6. There is much, much more

   The MULTIBOOT_64 repo / thumb drive is a Swiss Army Knife of functionality, 
   and the above presents only the most typical uses.  Browse the contents 
   to find more, and suggest tools and documents to add to it if you find 
   them useful.
   
   
===============================================================================
   
   
