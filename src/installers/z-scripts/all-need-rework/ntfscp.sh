#
#        Recursive copy of a directory tree along with NTFS attributes
#
#        Copyright (c) 2010 Jean-Pierre Andre
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (in the main directory of the NTFS-3G
# distribution in the file COPYING); if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
if [ $# -eq 2 ]
then
   if [ -d "$1" ] && ! [ -h "$1" ]
   then
#
#                                   copy directory
#
#                                   create target directory
#
      if ! [ -e "$2" ]
      then
         echo "Creating $2"
         mkdir "$2"
      fi
      if [ -d "$2" ]
      then
#
#                                   copy the attrib, useful for compression
#
         setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_attrib "$1" | \
                      grep '=' | sed -e 's/^.*=//'` -n system.ntfs_attrib "$2"
#
#                                   list source directory
#
         /bin/ls "$1" | while read f
         do
#
#                                   recurse copy of inner objects
#
            $0 "$1/$f" "$2/$f"
         done
#
#                                   copy user extended attributes
#
         for a in `getfattr -d -h --absolute-names -e hex "$1" | tail -n +2`
         do
            setfattr -n `echo $a | sed -e 's/=.*$//'` -v `echo $a | sed -e 's/^.*=//'` "$2"
         done
#
#                                   copy system extended attributes
#
         if getfattr -h --absolute-names -e hex -n system.ntfs_object_id "$1" 2> /dev/null | grep -q '='
         then
#
#                                   duplicated object_id not allowed on same volume
#
            setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_object_id "$1" | \
                         grep '=' | sed -e 's/^.*=//'` -n system.ntfs_object_id "$2"
         fi
         if getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" 2> /dev/null | grep -q '='
         then
            setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" | \
                         grep '=' | sed -e 's/^.*=//'` -n system.ntfs_dos_name "$2"
         fi
         setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_attrib "$1" | \
                      grep '=' | sed -e 's/^.*=//'` -n system.ntfs_attrib "$2"
#
#                                   ACL copied last, could prevent from copying
#
         setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_acl "$1" | \
                      grep '=' | sed -e 's/^.*=//'` -n system.ntfs_acl "$2"
      else
         echo "$1 is a directory, but $2 is not"
      fi
   else
      if [ -f "$1" ]
      then
#
#                                   copy a single file
#
         echo "Copying $1 to $2"
         cp -p "$1" "$2"
#
#                                   copy user extended attributes
#
         for a in `getfattr -d -h --absolute-names -e hex "$1" | tail -n +2`
         do
            setfattr -n `echo $a | sed -e 's/=.*$//'` -v `echo $a | sed -e 's/^.*=//'` "$2"
         done
#
#                                   copy system extended attributes
#
         if getfattr -h --absolute-names -e hex -n system.ntfs_object_id "$1" 2> /dev/null | grep -q '='
         then
#
#                                   duplicated object_id not allowed on same volume
#
            setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_object_id "$1" | \
                         grep '=' | sed -e 's/^.*=//'` -n system.ntfs_object_id "$2"
         fi
         if getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" 2> /dev/null | grep -q '='
         then
            setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" | \
                         grep '=' | sed -e 's/^.*=//'` -n system.ntfs_dos_name "$2"
         fi
         setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_attrib "$1" | \
                      grep '=' | sed -e 's/^.*=//'` -n system.ntfs_attrib "$2"
#
#                                   ACL copied last, could prevent from copying
#
         setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_acl "$1" | \
                      grep '=' | sed -e 's/^.*=//'` -n system.ntfs_acl "$2"
      else
         if [ -h "$1" ]
         then
#
#                                   copy junction or symbolic link (any type)
#
#        Note : the following is more complicated than needed
#        because of bugs in getfattr. 
#        Details in https://bugzilla.redhat.com/show_bug.cgi?id=660613
#               and https://bugzilla.redhat.com/show_bug.cgi?id=660619
#
            if getfattr -h --absolute-names -e hex -n system.ntfs_reparse_data "$1" 2> /dev/null | head -n 1 | grep -q "$1\$"
            then
               if ! [ -e "$2" ] && ! [ -h "$2" ]
               then
                  mkdir "$2"
               fi
# TODO Vista symlink to a file
# the following does only a minimal copy because of bugs mentionned above
# TODO copy the attrib, the ACL, etc.
               if getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" 2> /dev/null | head -n 1 | grep -q "$1\$"
               then
                  setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" | \
                            head -n 2 | grep '=' | sed -e 's/^.*=//'` -n system.ntfs_dos_name "$2"
               fi
               setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_reparse_data "$1" | \
                            head -n 2 | grep '=' | sed -e 's/^.*=//'` -n system.ntfs_reparse_data "$2"
            else
#
#                                           Unix-type symlink
#
               rm -f "$2"
               ln -s `/bin/ls -l "$1" | sed -e 's/^.* -> //'` "$2"
               if getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" 2> /dev/null | head -n 1 | grep -q "$1\$"
               then
                  setfattr -h -v `getfattr -h --absolute-names -e hex -n system.ntfs_dos_name "$1" | \
                            head -n 2 | grep '=' | sed -e 's/^.*=//'` -n system.ntfs_dos_name "$2"
               fi
            fi
         else
            echo "$1 : unsupported type"
         fi
      fi
   fi
else
   echo "Usage : ntfscp.sh source target"
fi
