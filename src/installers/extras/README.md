
Create directories here, one per Ubuntu distro you install and/or maintain...

in each directory, use 'apt-get download <pkg>' to cache '.deb' packages 
that you find essential when installing or rescuing a borked system.

For example, to rescue a system using md-raid when there is no network 
connection, you will need the 'mdadm' package -- which is not installed 
using the Desktop image.  You need to download it and cache it here.

To install these cached packages, run

    dpkg -i *.deb

from the distro's cached package directory.

