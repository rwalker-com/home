#!/bin/sh

if [ $# -lt 2 ]
then
cat<<EOF
Usage:

update_p4.sh <FROMDIR> <DIR> [DIR ...]

Update_p4 overwrites the contents of each DIR in the current working directory
with matching subdirectories from FROMDIR.  This can be useful when updating a
toolchain or checking in a new release of software from a built directory.

For example, to update build/tools/rvds40/RVCT/... with a patch from ARM that
contains only the include, lib, and windows binaries, you'd do:

unzip RVCT40_693_patch.zip # yields c:/RVCT_693_patch/win_32-pentium
                           #        c:/RVCT_693_patch/include
                           #        c:/RVCT_693_patch/lib

cd build/tools/rvds40/RVCT/Programs/4.0/400
update_p4.sh C:/RVCT_693_patch win_32-pentium # updates win_32-pentium/...

cd build/tools/rvds40/RVCT/Data/4.0/400
update_p4.sh C:/RVCT_693_patch lib include    # updates both lib/... and 
                                              #  include/...

This script should be run on an otherwise clean, up to date client workspace
to prevent spurious additions.

EOF
exit 1
fi

from=${1}

shift

# Step #1:
# Open all files for delete, whacks all files on disk.  This step in 
# combination with step #3 covers files that should be removed from perforce.
p4 delete "${@/%//...}"

# Step #2:
# Force-copy from the source
cp -af "${@/#/${from}/}" .

# Step #3:
# Undo delete for everything now present in the subdirectories.  Everything
# else (stuff opened in Step #1) stays open for delete.
find "${@}" -type f -print0 | xargs -0 -s 16384 p4 revert -k

# Step #4:
# Open for add all files present.  This covers new files.
# Perforce ignores adds of files already known to version control.
find "${@}" -type f -print0 | xargs -0 -s 16384 p4 add

# Step #5:
# Open for edit everything in the subtrees.  Perforce ignores anything 
# already open for delete or add.  This covers changes to pre-existing files.
p4 edit "${@/%//...}"

# Step #6:
# Revert anything unchanged.  This covers files that are the same in 
# perforce as in the update source directories.
p4 revert -a "${@/%//...}"

