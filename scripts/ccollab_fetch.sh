#!/bin/bash

# defaults
COOKIES=cookies_$$.txt
PORT=qctcollab:8080
QUIET=--quiet
CLEAN=yes
me=$(basename ${0})

show_usage ()
{
    cat<<EOF
Usage:  ${me} [-U user] [-P password] [-p collabport] ID [ ID ... ]
Retrieve the current set of files for a review on a CodeCollaborator server.

Where:
    -U user:  user ID on server, defaults to USER 

    -P pass:  password for user. if not given, ${me} prompts

    -p port:  hostname and port number of CodeCollaborator server,
               defaults to $PORT

    ID  review id from which to retrieve the files

EOF
}

bail()
{
    if [ -n "$2" ]
    then
        echo "$2"
    fi
    # cleanup
    if [ ${CLEAN} = yes ]
    then
        rm -f ${COOKIES} auth_$$.html init_$$.html
    fi
    exit $1
}

error()
{
    if [ -n "$2" ]
    then
        echo "Error: ${me}: $2"
    fi
    bail $1
}


while getopts "mqhU:P:p:o" opt
do
   case "$opt" in
      h) show_usage; bail 0;;
      U) USER="$OPTARG";;
      P) PASS="$OPTARG" PASSGIVEN=1;;
      p) PORT="$OPTARG";;
      v) QUIET=;;
      m) CLEAN=no;;
      [?]) echo "Unknown option"; show_usage; bail 1;;
   esac
done
shift $(expr $OPTIND - 1)

REVIEW=${1}

if [ -z "${REVIEW}" ]
then
    show_usage
    error 1 "no review IDs given"
fi

# have to retrieve home page to get initial cookie and save it
echo -n "Connecting..."
wget \
  ${QUIET} \
  --keep-session-cookies \
  --save-cookies ${COOKIES} \
  -O init_$$.html \
  "http://${PORT}/index.jsp?page=Home" || bail $? 
echo done

if [ -n "${USER}" ]
then
    if [ -z "${PASSGIVEN}" ]
    then
        echo -n "${USER}@${PORT}'s password: "
        read -s PASS
        echo ""
    fi
    echo -n "Authenticating ${USER}..."
    wget \
      ${QUIET} \
      --keep-session-cookies \
      --load-cookies ${COOKIES} \
      --save-cookies ${COOKIES} \
      --post-data="j_username=${USER}&j_password=${PASS}&buttonSubmit=Log+In" \
      -O auth_$$.html \
      "http://${PORT}/j_security_check" || bail $?
    echo done
fi

while [ -n "${REVIEW}" ]
do
    echo -n "Saving files to review-${REVIEW}-files.zip..."
    wget \
      ${QUIET} \
      --keep-session-cookies \
      --load-cookies ${COOKIES} \
      --save-cookies ${COOKIES} \
      -O "review-${REVIEW}-files.zip" \
      "http://${PORT}/data/server?changelist=latest&reviewid=${REVIEW}" || bail $?
    echo done

    unzip -d review-${REVIEW}-files review-${REVIEW}-files.zip

    shift
    REVIEW=${1}
done



