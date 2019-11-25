#
#        Recursive copy of a directory tree along with NTFS attributes
#
#        Copyright (c) 2010 Jean-Pierre Andre
#        Redesigned by "Biriukov" and posted to the ntfs-3g mailing list
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

# =========== Parametrs ===============
#
#  $1  - source folder WHITHOUT "/" IN END (example /mnt/windows) 
#  $2  - destinathion folder  WHITHOUT "/" IN END (example /mnt/new_windows)
#  $3  - output setfattr file (example /tmp/setfattr.sh)
# [$4] - remote host with port for destinathion rsync [Optionaly] (example root@server.com:2200)
# 
#  Example: 
#
#	Local rsync:
#	./ntfscp2.sh /mnt/windows /mnt/new_windows /tmp/setfattr.sh
#
#	Remote rsync:
#	./ntfscp2.sh /mnt/windows /mnt/new_windows /tmp/setfattr.sh root@server.com:2200
#

# ===================== Functions ==============================

function usage {
	cat <<EOF

  \$1  - source folder WHITHOUT "/" IN END (example /mnt/windows) 
  \$2  - destinathion folder  WHITHOUT "/" IN END (example /mnt/new_windows)
  \$3  - output setfattr file (example /tmp/setfattr.sh)
 [\$4] - remote host with port for remote rsync [Optionaly] (example root@server.com:2200)
 
  Example: 

	Local rsync:
	./ntfscp2.sh /mnt/windows /mnt/new_windows /tmp/setfattr.sh

	Remote rsync:
	./ntfscp2.sh /mnt/windows /mnt/new_windows /tmp/setfattr.sh root@server.com:2200

EOF
	exit
} 


function apply_dir {
	#Apply directory Extended Attributes
	#
	# $1 source 
	# $2 destinathion 
	# $3 output command file
	#
		
	#copy the attrib, useful for compression
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_attrib "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_attrib" \'"$2"\' >> "$3"

	#copy user extended attributes
	for a in `getfattr --absolute-names  -d -e hex "$1" | tail -n +2`
	do
	RECV=`echo $a | sed -e 's/=.*$//'` -v `echo $a | sed -e 's/^.*=//'`
	echo "setfattr -n $RECV" \'"$2"\' >> "$3"
	done

	#copy system extended attributes
	if getfattr --absolute-names  -h -e hex -n system.ntfs_object_id "$1" 2> err | grep -q '='
	then
	#duplicated object_id not allowed on same volume
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_object_id "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_object_id " \'"$2"\' >> "$3"
	fi

	if getfattr --absolute-names  -h -e hex -n system.ntfs_dos_name "$1" 2> err | grep -q '='
	then
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_dos_name "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_dos_name" \'"$2"\' >> "$3"
	fi
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_attrib "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_attrib" \'"$2"\' >> "$3"

	#ACL copied last, could prevent from copying
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_acl "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_acl" \'"$2"\' >> "$3"
}  


function apply_file {
	#Apply regular file Extended Attributes
	#
	# $1 source 
	# $2 destinathion 
	# $3 output command file
	#
	
	#copy user extended attributes
	for a in `getfattr --absolute-names  -d -e hex "$1" | tail -n +2`
	do
	RECV=`echo $a | sed -e 's/=.*$//'` -v `echo $a | sed -e 's/^.*=//'`
	echo "setfattr -n $RECV" \'"$2"\' >> "$3"
	done

	#copy system extended attributes
	if getfattr --absolute-names  -h -e hex -n system.ntfs_object_id "$1" 2> err | grep -q '='
	then
	#duplicated object_id not allowed on same volume
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_object_id "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_object_id " \'"$2"\' >> "$3"
	fi

	if getfattr --absolute-names  -h -e hex -n system.ntfs_dos_name "$1" 2> err | grep -q '='
	then
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_dos_name "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_dos_name " \'"$2"\' >> "$3"
	fi

	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_attrib "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_attrib " \'"$2"\' >> "$3"

	#ACL copied last, could prevent from copying
	RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_acl "$1" | grep '=' | sed -e 's/^.*=//'`
	echo "setfattr -h -v $RECV -n system.ntfs_acl " \'"$2"\' >> "$3" 

}


function apply_link {
	#Apply link NTFS Extended Attributes
	#
	# $1 source 
	# $2 destinathion 
	# $3 output command file
	#
	
	#copy junction of Vista symbolic link
	# getfattr  tends to follow the link !
	if getfattr --absolute-names  -h -e hex -n system.ntfs_reparse_data "$1" 2> err | head -n 1 | grep -q ":"
	then
		echo "rm -rf " \'"$2"\' >> "$3"
		
		#Get what is it file or dir
		RECV=`ls -la "$1" | awk -F " -> " '{ print $2 }'`
		
		if [ -f "$RECV" ] 
		then
			echo  "touch " \'"$2"\' >> "$3"
			apply_file "$1" "$2" "$3"
			
			RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_reparse_data "$1" | head -n 2 | grep '=' | sed -e 's/^.*=//'`
			echo "setfattr -h -v $RECV -n system.ntfs_reparse_data " \'"$2"\' >> "$3"
			
		elif [ -d "$RECV" ]
		then
			echo  "! [ -e" \'"$2"\' "] && ! [ -h" \'"$2"\' "] | mkdir " \'"$2"\' >> "$3"
			#Do the same as whith Directories
			apply_dir "$1" "$2" "$3"
			
			RECV=`getfattr --absolute-names  -h -e hex -n system.ntfs_reparse_data "$1" | head -n 2 | grep '=' | sed -e 's/^.*=//'`
			echo "setfattr -h -v $RECV -n system.ntfs_reparse_data " \'"$2/"\' >> "$3"
		
		else
			echo "Unsupported Link"
		fi
			
	fi
	
	

}

# ====================== Main ==================================

if [ -z $3 ] || [ -z $2 ] || [ -z $1 ]
then
	usage
fi


SOURCE="$1"
DESTINATION="$2"
SETFATR_FILE="$3"

#makeup parametrs for rsync
if [ -n "$4" ]
then
	SSH_PORT=`echo "$4" | awk -F ":" '{ print $2 }'`
	RS_SERVER=`echo "$4" | awk -F ":" '{ print $1 }'`":"
	RS_SSH="ssh -p $SSH_PORT"
else
	RS_SSH=""
	RS_SERVER=""
fi 


#RS_EXCLUDE='--exclude "hiberfil.sys" --exclude "pagefile.sys"'

#Do rsync
RS=`rsync  -lrptgoDx --delete --numeric-ids  --out-format='%n'  $RS_SSH $RS_EXCLUDE $SOURCE/ $RS_SERVER$DESTINATION/ | egrep -v "^\./" | egrep -v "^deleting "`

#clear output file
echo '#!/bin/bash' > "$SETFATR_FILE"


#find $1 | while read f; do
echo "$RS" | while read i; do
	
	f=$SOURCE/$i
	t=$DESTINATION`echo "$f" | awk -F "$SOURCE" '{ print $2 }'`
	
	if [ -d "$f" ] && ! [ -h "$f" ]
	#Directory and not symlink
	then
		 apply_dir "$f" "$t" "$SETFATR_FILE"
	elif [ -f "$f" ] && ! [ -h "$f" ]
	#Single file
	then
		apply_file "$f" "$t" "$SETFATR_FILE"
	elif [ -h "$f" ]
	#Link!
	then
		apply_link "$f" "$t" "$SETFATR_FILE"
	else
		echo "$f : unsupported type"
	fi
done
