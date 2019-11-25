
SSDcronTRIM README
==================================================================

http://chmatse.github.io/SSDcronTRIM/


SSDcronTRIM
Intelligent cron job script which automatically decides how often to trim 
one or more SSD partitions

What is SSDcronTRIM ?

SSDcronTRIM is an intelligent cronjob which, depending on the usage of your 
Solid State Disk(s), automatically decides how often the SSD(s) should be 
trimmed. The more data you have on your SSD(s) the more often they will be 
trimmed.

It is intended as a fire and forget app which, once installed, does 
everything fully automated. In fact it is so clever, you should be able to 
install it on any linux system without using the package manager of your 
distribution. Just open this script with your favorite text editor, add the 
partition(s) which should be trimmed (as a space separated list into the 
variable SSD_MOUNT_POINTS) and then execute SSDcronTRIM without any option.

Beside the needed cron job(s) it also creates a man page on the fly. Both, 
the cron job(s) and manual page installation does not interfere with your 
existing distribution. And if you want to get rid of this script just start 
it with the deinstall option and it will remove any cron job(s) and the man 
page.

How to install SSDcronTRIM ?

Just follow these five simple steps:

    Make sure you are working as the root user on your system.

    Download the latest version from github.
        wget https://raw.github.com/chmatse/SSDcronTRIM/master/SSDcronTRIM

    Set the Permissions so that only the root user can execute this script.
        chmod 740 SSDcronTRIM

    Open SSDcronTRIM with your favorite Editor and change the variables in 
    the settings (Don't worry, there are only a hand full of them!) section 
    according to your needs.

    Just execute the script and the magic will start ;-)
        ./SSDcronTRIM

How can i unistall everything?

Just type '/SSDcronTRIM -d' and every cronjob installed by SSDcronTRIM 
together with the manpage will be removed.

