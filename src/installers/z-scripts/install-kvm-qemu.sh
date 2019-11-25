#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install KVM / QEMU virtualization packages
# ----------------------------------------------------------------------------
#

INCLUDES="core-install.bash"

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}"
else
    echo -n "$( basename "${0}" ): error: "
    echo    "Could not source the '${INCLUDES}' file ! "
    exit
fi

GetScriptName "${0}"

SET_NAME="KVM-QEMU"

PACKAGE_SET="
qemu  aqemu  qemu-kvm  libvirt-bin  virt-manager  virt-viewer
libguestfs-tools  bridge-utils  debootstrap  lvm2  samba  sgabios
augeas-doc  augeas-tools  radvd  qemu-user-static  vde2
bsd-mailx  python-guestfs  python-spice-client-gtk  "

: <<'__COMMENT'
openbsd-inetd  inet-superserver  smbldap-tools  ldb-tools  vde2-cryptcab
xfsdump  attr  quota  nfs-kernel-server  kpartx

aptitude-doc-en  attr  augeas-doc  augeas-tools  binutils-multiarch
bsd-mailx  cgroup-lite  cpu-checker  devhelp  devscripts-el  dnsmasq-base
ebtables  equivs  g++-4.6-multilib  gamin  gawk  gcc-4.6-doc
g++-multilib  gnome-mime-data  gnuplot  hal  mini-dinstall  msr-tools
mutt  nfs-kernel-server  openssh-server  python-gdbm-dbg
python-gnome2-doc  python-gtk2-doc  python-guestfs
python-markdown  python-memcache  python-pygments  python-pyorbit-dbg
python-spice-client-gtk  python-tk-dbg  qemu-keymaps  quota  radvd
seabios  ssh-import-id  tasksel  tcpd  ubuntu-virt-server  ubuntu-vm-builder
uml-utilities  user-mode-linux  vgabios  virt-viewer  w3m

libaio1  libapparmor1  libasound2  libasyncns0  libauthen-ntlm-perl
libauthen-sasl-perl  libavahi-client3  libavahi-common3
libavahi-common-data  libbonobo2-bin  libcaca0  libcrypt-ssleay-perl
libcwidget-dev  libdata-dump-perl  libflac8  libgnomevfs2-bin
libgnomevfs2-extra  libhtml-template-perl  libjson0  libnetfilter-conntrack3
libnet-smtp-ssl-perl  libnl-3-200  libnspr4  libnss3  libnuma1  libogg0
libpulse0  librados2  librbd1  libsdl1.2debian  libsigsegv2  libsndfile1
libsoap-lite-perl  libstdc++6-4.6-dbg  libstdc++6-4.6-doc  libterm-size-perl
libtext-template-perl  libvirt0  libvorbis0a  libvorbisenc2  libwrap0
libxenstore3.0  libxml2-utils  libxml-simple-perl
libyaml-syck-perl

fam  mailx
libyajl1  python-magic-dbg
__COMMENT

#
# Test to see if this platform has hardware virtualization extensions:
#
VTX_SVM="*does*"
egrep '(vmx|svm)' /proc/cpuinfo >/dev/null
(( $? > 0 )) && VTX_SVM="does *NOT*"

#
# Create a 'usage' prompt:
#
USAGE="
Kernel-based Virtual Machine (KVM) is a virtualization infrastructure for
the Linux kernel.  A wide variety of guest operating systems work with KVM,
including many flavors of Linux, BSD, Solaris, Windows, Haiku, ReactOS, and
Plan 9.  With a modified version of QEMU, KVM can run Mac OS X as well.
KVM elements are licensed under various GNU licenses.

Paravirtualization (PV) support, which significantly speeds up guest access
of certain devices (PCI & VGA), is available for Linux, FreeBSD, Plan 9, and
Windows using the VirtIO framework.  VirtIO supports a PV Ethernet card, a
PV disk I/O controller, a 'balloon' device for adjusting guest memory usage,
and a VGA graphics interface using SPICE or VMware drivers.

KVM implements an Intel i440FX/PIIX3 chipset, and uses SeaBIOS for the guest
VM's BIOS.  A processor that supports hardware virtualization extensions is
required, either VT-f (Vanderpool) or AMD-V (Pacifica).  To verify, execute
    egrep '(vmx|svm)' /proc/cpuinfo
on your system; if there are any matches, then the platform supports KVM.

NOTE: This machine ${VTX_SVM} support hardware virtualization extensions.

This 'meta-package' installs the KVM+QEMU set of packages from the Ubuntu
repositories, including all the 'suggested' packages & libguestfs.

http://www.linux-kvm.org
"

PerformAppInstallation "-r" "$@"

QualifySudo
sudo chmod 644 /boot/vmlinuz*

InstallComplete
