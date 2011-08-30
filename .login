##############################################################################
#
#	.login file
#
#	Read in after the .cshrc when you log in.
#	Not read in for subsequent shells.  For setting up
#	terminal and global environment characteristics.
#
##############################################################################


##
## environment variables
##

setenv EDITOR emacs
setenv VISUAL $EDITOR
setenv FCEDIT $VISUAL
setenv PRINTER lp

stty erase "^H" kill "^U" intr "^C" eof "^D" susp "^Z" hupcl ixon ixoff tostop tabs 

##
## general terminal characteristics
##




