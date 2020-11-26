
Notes on VirtualBox Virtual Machines
===============================================================================

Updated 2020-1126

I recommend saving a copy of the VMs as templates or "master" copies.  Copy 
them before using them (or better, use VBox to 'clone' them, which results 
in new resource IDs that will not cause conflicts later).  This way you'll 
have backup copies to restore in case of corruption/infection/etc.

The VMs expect the latest version of VirtualBox, with the 'Extensions Pack' 
installed.  The MULTIBOOT_64 image includes installers for VirtualBox, as 
well as the Extensions Packs.

The VMs are set up to use 4GB of (host) RAM and 4 CPUs.  Depending on the 
host you install them on, you may want to open "Settings" and adjust these 
values *before* you launch any of them.

Every account on every VM uses '1234' as a password (they depend on the VM 
host for access security).  The Linux machines have only a "user" account 
(with 'sudo' privileges), while the Windows VMs use "EGSE_USER" as the 
working (Std) account and "Maintenance" as the administrator account.

Every keyboard for every account should be set to "en-us"; if you get strange 
results while trying to type something, trying changing the keyboard layout.

It's strongly recommended to use Shared Folders in the VM and store all 
files that need persistence on the VM host, never in the VM itself.  In this 
way, if the VM is lost (or reverted to a snapshot), your files won't be 
lost.

If you use Shared Folders for the Linux VMs, there's a bug in VBox (since 
5.2.18 or so) that will cause it to not re-mount the SF's between reboots of 
the VM.  The workaround was to re-install the Guest Additions, then they show 
up.  (A small percentage of the time I've had to re-install more than once 
in a row to recover my SF's.)  Even this doesn't seem to work any longer.  
Therefore I added two functions, 'fixv' to repair the SF mounting, to be 
followed by 'dlymnt' to mount the shared folders (which cannot be mounted 
until 'fixv' is run to make them visible).  To prevent any attempts to mount 
these 'missing' SF directories, I comment them out in '/etc/fstab' using 
"### " as a prefix; the 'dlymnt' shell function mounts these.

One strategy to avoid tracking and malware when using a VM is to snapshot 
the state of the VM, then begin using the VM.  To reduce the effect of web 
trackers, periodically revert to the snapshot.  (See the warning in one of 
the above paragraphs about keeping personal files in the host file system.)  
This also protects against corruption (of the VM's files/file system); 
reverting to a snapshot fully restores everything to working order.

===============================================================================

