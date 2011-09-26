#!/bin/bash

WebKitDir=$(pwd)
ip=127.0.0.1
port=1080

function usage()
{
    cat<<EOF
Usage: 
  webkit-httpd [-p <NUM>] [-W <DIR>] [-g] [-h] start|restart|stop

  Starts/stops a unique instance of httpd for WebKit http debugging.

  -D <DIR>   Top-level WebKit directory.  Defaults to current working directory.

  -p <NUM>   Base port number.  Defaults to 1080. httpd will listen on the
              base port, the base port+1, and the base port-80+443 (for SSL).

  -g         Allow "global" access, listen on all IP addresses.  Defaults to
              listening on localhost only.

  -h:        Prints this message and exits.

EOF
}

while getopts "hp:D:go" opt
do
   case "$opt" in
   p) port="$OPTARG";;
   g) ip='*';;
   h) usage ; exit 0;;
   D) WebKitDir="$OPTARG";;
   [?]) echo "Unknown option"; show_usage; bail 1;;
   esac
done

shift $(expr $OPTIND - 1)

if [ $# -ne 1 ]
then
    echo "Error: please offer a command"
    usage
    exit 1
fi

case $1 in
    start|stop|restart) ;;
    -*) echo unknown option \"$1\"; usage; exit 1;;
    *) echo unknown command \"$1\"; usage; exit 1;;
esac

if [ ! -d "${WebKitDir}" ]
then
    Error: webkit-httpd.sh: can not find WebKit directory \"${WebKitDir}\".
    exit 1
else
    WebKitDir="$(cd "${WebKitDir}" && pwd)"
fi

let port1=${port}+1
let sslport=${port}-80+443

RunName=webkit-httpd-${port}
RunDir="$(cd ${TMPDIR} && pwd)/${RunName}"

if [ "$1" == "start" ] || [ "$1" == "restart" ]
then

  mkdir -p "${RunDir}"

  # initialize with the end of me
  tail -555 ${0} > ${RunDir}/httpd.conf

  cat <<EOF_httpd_conf>>${RunDir}/httpd.conf
# httpd instance specific

DocumentRoot "${WebKitDir}/LayoutTests/http/tests"
Listen ${ip}:${port}
Listen ${ip}:${port1}
Listen ${ip}:${sslport}

ServerRoot     "${RunDir}"
LockFile       "${RunDir}/httpd.lock"
ScoreBoardFile "${RunDir}/httpd.scoreboard"
CustomLog      "${RunDir}/access_log.txt" common
ErrorLog       "${RunDir}/error_log.txt"
Alias           /rundir "${RunDir}"

Alias /js-test-resources "${WebKitDir}/LayoutTests/fast/js/resources"
Alias /media-resources   "${WebKitDir}/LayoutTests/media"
TypesConfig              "${WebKitDir}/LayoutTests/http/conf/mime.types"
SSLCertificateFile       "${WebKitDir}/LayoutTests/http/conf/webkit-httpd.pem"

<VirtualHost *:${sslport}>
  SSLEngine On
</VirtualHost>

EOF_httpd_conf

fi

/usr/sbin/httpd \
 -C "PidFile \"${RunDir}/httpd.pid\""\
 -f "${RunDir}/httpd.conf"\
 -k "$1"

exit $?

555 lines follow, if you change the length of httpd.conf below,
 change the "tail -555 $0" command above...

##
##
## httpd.conf -- Apache HTTP server configuration file
##

#
# Based upon the NCSA server configuration files originally by Rob McCool.
#
# This is the main Apache server configuration file.  It contains the
# configuration directives that give the server its instructions.
# See <URL:http://httpd.apache.org/docs/> for detailed information about
# the directives.
#
# Do NOT simply read the instructions in here without understanding
# what they do.  They're here only as hints or reminders.  If you are unsure
# consult the online docs. You have been warned.  
#
# After this file is processed, the server will look for and process
# /private/etc/apache2/srm.conf and then /private/etc/apache2/access.conf
# unless you have overridden these with ResourceConfig and/or
# AccessConfig directives here.
#
# The configuration directives are grouped into three basic sections:
#  1. Directives that control the operation of the Apache server process as a
#     whole (the 'global environment').
#  2. Directives that define the parameters of the 'main' or 'default' server,
#     which responds to requests that aren't handled by a virtual host.
#     These directives also provide default values for the settings
#     of all virtual hosts.
#  3. Settings for virtual hosts, which allow Web requests to be sent to
#     different IP addresses or hostnames and have them handled by the
#     same Apache server process.
#
# Configuration and logfile names: If the filenames you specify for many
# of the server's control files begin with "/" (or "drive:/" for Win32), the
# server will use that explicit path.  If the filenames do *not* begin
# with "/", the value of ServerRoot is prepended -- so "logs/foo.log"
# with ServerRoot set to "/usr/local/apache" will be interpreted by the
# server as "/usr/local/apache/logs/foo.log".
#

### Section 1: Global Environment
#
# The directives in this section affect the overall operation of Apache,
# such as the number of concurrent requests it can handle or where it
# can find its configuration files.
#

#
# The LockFile directive sets the path to the lockfile used when Apache
# is compiled with either USE_FCNTL_SERIALIZED_ACCEPT or
# USE_FLOCK_SERIALIZED_ACCEPT. This directive should normally be left at
# its default value. The main reason for changing it is if the logs
# directory is NFS mounted, since the lockfile MUST BE STORED ON A LOCAL
# DISK. The PID of the main server process is automatically appended to
# the filename. 
#

#
# Timeout: The number of seconds before receives and sends time out.
#
Timeout 300

#
# KeepAlive: Whether or not to allow persistent connections (more than
# one request per connection). Set to "Off" to deactivate.
#
KeepAlive On

#
# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
# We recommend you leave this number high, for maximum performance.
#
MaxKeepAliveRequests 100

#
# KeepAliveTimeout: Number of seconds to wait for the next request from the
# same client on the same connection.
#
KeepAliveTimeout 15

#
# Server-pool size regulation.  Rather than making you guess how many
# server processes you need, Apache dynamically adapts to the load it
# sees --- that is, it tries to maintain enough server processes to
# handle the current load, plus a few spare servers to handle transient
# load spikes (e.g., multiple simultaneous requests from a single
# Netscape browser).
#
# It does this by periodically checking how many servers are waiting
# for a request.  If there are fewer than MinSpareServers, it creates
# a new spare.  If there are more than MaxSpareServers, some of the
# spares die off.  The default values are probably OK for most sites.
#
MinSpareServers 1
MaxSpareServers 5

#
# Number of servers to start initially --- should be a reasonable ballpark
# figure.
#
StartServers 1

#
# Limit on total number of servers running, i.e., limit on the number
# of clients who can simultaneously connect --- if this limit is ever
# reached, clients will be LOCKED OUT, so it should NOT BE SET TOO LOW.
# It is intended mainly as a brake to keep a runaway server from taking
# the system with it as it spirals down...
#
MaxClients 150

#
# MaxRequestsPerChild: the number of requests each child process is
# allowed to process before the child dies.  The child will exit so
# as to avoid problems after prolonged use when Apache (and maybe the
# libraries it uses) leak memory or other resources.  On most systems, this
# isn't really needed, but a few (such as Solaris) do have notable leaks
# in the libraries. For these platforms, set to something like 10000
# or so; a setting of 0 means unlimited.
#
# NOTE: This value does not include keepalive requests after the initial
#       request per connection. For example, if a child process handles
#       an initial request and 10 subsequent "keptalive" requests, it
#       would only count as 1 request towards this limit.
#
MaxRequestsPerChild 100000


#
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding `LoadModule' lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Please read the file http://httpd.apache.org/docs/dso.html for more
# details about the DSO mechanism and run `httpd -l' for the list of already
# built-in (statically linked and thus always available) modules in your httpd
# binary.
#
# Note: The order in which modules are loaded is important.  Don't change
# the order below without expert advice.
#
# Example:
# LoadModule foo_module libexec/mod_foo.so
#LoadModule authn_file_module libexec/apache2/mod_authn_file.so
#LoadModule authn_dbm_module libexec/apache2/mod_authn_dbm.so
#LoadModule authn_anon_module libexec/apache2/mod_authn_anon.so
#LoadModule authn_dbd_module libexec/apache2/mod_authn_dbd.so
#LoadModule authn_default_module libexec/apache2/mod_authn_default.so
LoadModule authz_host_module libexec/apache2/mod_authz_host.so
#LoadModule authz_groupfile_module libexec/apache2/mod_authz_groupfile.so
#LoadModule authz_user_module libexec/apache2/mod_authz_user.so
#LoadModule authz_dbm_module libexec/apache2/mod_authz_dbm.so
#LoadModule authz_owner_module libexec/apache2/mod_authz_owner.so
#LoadModule authz_default_module libexec/apache2/mod_authz_default.so
#LoadModule auth_basic_module libexec/apache2/mod_auth_basic.so
#LoadModule auth_digest_module libexec/apache2/mod_auth_digest.so
#LoadModule cache_module libexec/apache2/mod_cache.so
#LoadModule disk_cache_module libexec/apache2/mod_disk_cache.so
#LoadModule mem_cache_module libexec/apache2/mod_mem_cache.so
#LoadModule dbd_module libexec/apache2/mod_dbd.so
#LoadModule dumpio_module libexec/apache2/mod_dumpio.so
#LoadModule ext_filter_module libexec/apache2/mod_ext_filter.so
LoadModule include_module libexec/apache2/mod_include.so
#LoadModule filter_module libexec/apache2/mod_filter.so
#LoadModule substitute_module libexec/apache2/mod_substitute.so
#LoadModule deflate_module libexec/apache2/mod_deflate.so
LoadModule log_config_module libexec/apache2/mod_log_config.so
#LoadModule log_forensic_module libexec/apache2/mod_log_forensic.so
#LoadModule logio_module libexec/apache2/mod_logio.so
#LoadModule env_module libexec/apache2/mod_env.so
#LoadModule mime_magic_module libexec/apache2/mod_mime_magic.so
#LoadModule cern_meta_module libexec/apache2/mod_cern_meta.so
#LoadModule expires_module libexec/apache2/mod_expires.so
LoadModule headers_module libexec/apache2/mod_headers.so
#LoadModule ident_module libexec/apache2/mod_ident.so
#LoadModule usertrack_module libexec/apache2/mod_usertrack.so
#LoadModule unique_id_module libexec/apache2/mod_unique_id.so
#LoadModule setenvif_module libexec/apache2/mod_setenvif.so
#LoadModule version_module libexec/apache2/mod_version.so
#LoadModule proxy_module libexec/apache2/mod_proxy.so
#LoadModule proxy_connect_module libexec/apache2/mod_proxy_connect.so
#LoadModule proxy_ftp_module libexec/apache2/mod_proxy_ftp.so
#LoadModule proxy_http_module libexec/apache2/mod_proxy_http.so
#LoadModule proxy_ajp_module libexec/apache2/mod_proxy_ajp.so
#LoadModule proxy_balancer_module libexec/apache2/mod_proxy_balancer.so
LoadModule ssl_module libexec/apache2/mod_ssl.so
LoadModule mime_module libexec/apache2/mod_mime.so
#LoadModule dav_module libexec/apache2/mod_dav.so
#LoadModule status_module libexec/apache2/mod_status.so
#LoadModule autoindex_module libexec/apache2/mod_autoindex.so
LoadModule asis_module libexec/apache2/mod_asis.so
#LoadModule info_module libexec/apache2/mod_info.so
LoadModule cgi_module libexec/apache2/mod_cgi.so
#LoadModule dav_fs_module libexec/apache2/mod_dav_fs.so
#LoadModule vhost_alias_module libexec/apache2/mod_vhost_alias.so
LoadModule negotiation_module libexec/apache2/mod_negotiation.so
#LoadModule dir_module libexec/apache2/mod_dir.so
LoadModule imagemap_module libexec/apache2/mod_imagemap.so
LoadModule actions_module libexec/apache2/mod_actions.so
#LoadModule speling_module libexec/apache2/mod_speling.so
#LoadModule userdir_module libexec/apache2/mod_userdir.so
LoadModule alias_module libexec/apache2/mod_alias.so
LoadModule rewrite_module libexec/apache2/mod_rewrite.so
#LoadModule bonjour_module     libexec/apache2/mod_bonjour.so
LoadModule php5_module        libexec/apache2/libphp5.so
#LoadModule fastcgi_module     libexec/apache2/mod_fastcgi.so

### Section 2: 'Main' server configuration
#
# The directives in this section set up the values used by the 'main'
# server, which responds to any requests that aren't handled by a
# <VirtualHost> definition.  These values also provide defaults for
# any <VirtualHost> containers you may define later in the file.
#
# All of these directives may appear inside <VirtualHost> containers,
# in which case these default settings will be overridden for the
# virtual host being defined.
#

#
# ServerName allows you to set a host name which is sent back to clients for
# your server if it's different than the one the program would get (i.e., use
# "www" instead of the host's real name).
#
# Note: You cannot just invent host names and hope they work. The name you 
# define here must be a valid DNS name for your host. If you don't understand
# this, ask your network administrator.
# If your host doesn't have a registered DNS name, enter its IP address here.
# You will have to access it by its address (e.g., http://123.45.67.89/)
# anyway, and this will make redirections work in a sensible way.
#
# 127.0.0.1 is the TCP/IP local loop-back address, often named localhost. Your 
# machine always knows itself by this address. If you use Apache strictly for 
# local testing and development, you may use 127.0.0.1 as the server name.
#
ServerName 127.0.0.1

#
# Each directory to which Apache has access, can be configured with respect
# to which services and features are allowed and/or disabled in that
# directory (and its subdirectories). 
#
<Directory />
#
# This may also be "None", "All", or any combination of "Indexes",
# "Includes", "FollowSymLinks", "ExecCGI", or "MultiViews".
#
# Note that "MultiViews" must be named *explicitly* --- "Options All"
# doesn't give it to you.
#
    Options Indexes FollowSymLinks MultiViews ExecCGI Includes

#
# This controls which options the .htaccess files in directories can
# override. Can also be "All", or any combination of "Options", "FileInfo", 
# "AuthConfig", and "Limit"
#
    AllowOverride All

#
# Controls who can get stuff from this server.
#
    Order allow,deny
    Allow from all
</Directory>

#
# AccessFileName: The name of the file to look for in each directory
# for access control information.
#
AccessFileName .htaccess

#
# The following lines prevent .htaccess files from being viewed by
# Web clients.  Since .htaccess files often contain authorization
# information, access is disallowed for security reasons.  Comment
# these lines out if you want Web visitors to see the contents of
# .htaccess files.  If you change the AccessFileName directive above,
# be sure to make the corresponding changes here.
#
# Also, folks tend to use names such as .htpasswd for password
# files, so this will protect those as well.
#
<Files ~ "^\.([Hh][Tt]|[Dd][Ss]_[Ss])">
    Order allow,deny
    Deny from all
    Satisfy All
</Files>

#
# Apple specific filesystem protection.
# 

<Files "rsrc">
    Order allow,deny
    Deny from all
    Satisfy All
</Files>

<Directory  ~ ".*\.\.namedfork">
    Order allow,deny
    Deny from all
    Satisfy All
</Directory>

#
# CacheNegotiatedDocs: By default, Apache sends "Pragma: no-cache" with each
# document that was negotiated on the basis of content. This asks proxy
# servers not to cache the document. Uncommenting the following line disables
# this behavior, and proxies will be allowed to cache the documents.
#
#CacheNegotiatedDocs

#
# UseCanonicalName:  (new for 1.3)  With this setting turned on, whenever
# Apache needs to construct a self-referencing URL (a URL that refers back
# to the server the response is coming from) it will use ServerName and
# Port to form a "canonical" name.  With this setting off, Apache will
# use the hostname:port that the client supplied, when possible.  This
# also affects SERVER_NAME and SERVER_PORT in CGI scripts.
#
UseCanonicalName On

#
# TypesConfig describes where the mime.types file (or equivalent) is
# to be found.
#
# Configured from the httpd command line for WebKit layout tests.
#
#<IfModule mod_mime.c>
#    TypesConfig /private/etc/apache2/mime.types
#</IfModule>

#
# DefaultType is the default MIME type the server will use for a document
# if it cannot otherwise determine one, such as from filename extensions.
# If your server contains mostly text or HTML documents, "text/plain" is
# a good value.  If most of your content is binary, such as applications
# or images, you may want to use "application/octet-stream" instead to
# keep browsers from trying to display binary files as though they are
# text.
#
DefaultType text/plain

#
# HostnameLookups: Log the names of clients or just their IP addresses
# e.g., www.apache.org (on) or 204.62.129.132 (off).
# The default is off because it'd be overall better for the net if people
# had to knowingly turn this feature on, since enabling it means that
# each client request will result in AT LEAST one lookup request to the
# nameserver.
#
HostnameLookups Off

#
# LogLevel: Control the number of messages logged to the error_log.
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
#
LogLevel warn

#
# The following directives define some format nicknames for use with
# a CustomLog directive (see below).
#
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

#
# Optionally add a line containing the server version and virtual host
# name to server-generated pages (error documents, FTP directory listings,
# mod_status and mod_info output etc., but not CGI generated documents).
# Set to "EMail" to also include a mailto: link to the ServerAdmin.
# Set to one of:  On | Off | EMail
#
ServerSignature On

#
# Aliases: Add here as many aliases as you need (with no limit). The format is 
# Alias fakename realname
#
<IfModule mod_alias.c>
</IfModule>
# End of aliases.

#
# Redirect allows you to tell clients about documents which used to exist in
# your server's namespace, but do not anymore. This allows you to tell the
# clients where to look for the relocated document.
# Format: Redirect old-URI new-URL
#

#
# Document types.
#
<IfModule mod_mime.c>

    #
    # AddLanguage allows you to specify the language of a document. You can
    # then use content negotiation to give a browser a file in a language
    # it can understand.  
    #
    # Note 1: The suffix does not have to be the same as the language 
    # keyword --- those with documents in Polish (whose net-standard 
    # language code is pl) may wish to use "AddLanguage pl .po" to 
    # avoid the ambiguity with the common suffix for perl scripts.
    #
    # Note 2: The example entries below illustrate that in quite
    # some cases the two character 'Language' abbreviation is not
    # identical to the two character 'Country' code for its country,
    # E.g. 'Danmark/dk' versus 'Danish/da'.
    #
    # Note 3: In the case of 'ltz' we violate the RFC by using a three char 
    # specifier. But there is 'work in progress' to fix this and get 
    # the reference data for rfc1766 cleaned up.
    #
    # Danish (da) - Dutch (nl) - English (en) - Estonian (ee)
    # French (fr) - German (de) - Greek-Modern (el)
    # Italian (it) - Korean (kr) - Norwegian (no) - Norwegian Nynorsk (nn)
    # Portugese (pt) - Luxembourgeois* (ltz)
    # Spanish (es) - Swedish (sv) - Catalan (ca) - Czech(cs)
    # Polish (pl) - Brazilian Portuguese (pt-br) - Japanese (ja)
    # Russian (ru)
    #
    AddLanguage da .dk
    AddLanguage nl .nl
    AddLanguage en .en
    AddLanguage et .ee
    AddLanguage fr .fr
    AddLanguage de .de
    AddLanguage el .el
    AddLanguage he .he
    AddCharset ISO-8859-8 .iso8859-8
    AddLanguage it .it
    AddLanguage ja .ja
    AddCharset ISO-2022-JP .jis
    AddLanguage kr .kr
    AddCharset ISO-2022-KR .iso-kr
    AddLanguage nn .nn
    AddLanguage no .no
    AddLanguage pl .po
    AddCharset ISO-8859-2 .iso-pl
    AddLanguage pt .pt
    AddLanguage pt-br .pt-br
    AddLanguage ltz .lu
    AddLanguage ca .ca
    AddLanguage es .es
    AddLanguage sv .sv
    AddLanguage cs .cz .cs
    AddLanguage ru .ru
    AddLanguage zh-TW .zh-tw
    AddCharset Big5         .Big5    .big5
    AddCharset WINDOWS-1251 .cp-1251
    AddCharset CP866        .cp866
    AddCharset ISO-8859-5   .iso-ru
    AddCharset KOI8-R       .koi8-r
    AddCharset UCS-2        .ucs2
    AddCharset UCS-4        .ucs4
    AddCharset UTF-8        .utf8

    # LanguagePriority allows you to give precedence to some languages
    # in case of a tie during content negotiation.
    #
    # Just list the languages in decreasing order of preference. We have
    # more or less alphabetized them here. You probably want to change this.
    #
    <IfModule mod_negotiation.c>
        LanguagePriority en da nl et fr de el it ja kr no pl pt pt-br ru ltz ca es sv tw
    </IfModule>

    #
    # AddType allows you to tweak mime.types without actually editing it, or to
    # make certain files to be certain types.
    #
    AddType application/x-tar .tgz

    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    # Despite the name similarity, the following Add* directives have nothing
    # to do with the FancyIndexing customization directives above.
    #
    AddEncoding x-compress .Z
    AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    #AddType application/x-compress .Z
    #AddType application/x-gzip .gz .tgz

    #
    # AddHandler allows you to map certain file extensions to "handlers",
    # actions unrelated to filetype. These can be either built into the server
    # or added with the Action command (see below)
    #
    # If you want to use server side includes, or CGI outside
    # ScriptAliased directories, uncomment the following lines.
    #
    # To use CGI scripts:
    #
    AddHandler cgi-script .cgi .pl

    #
    # To use server-parsed HTML files
    #
    AddType text/html .shtml
    AddHandler server-parsed .shtml

    #
    # Uncomment the following line to enable Apache's send-asis HTTP file
    # feature
    #
    AddHandler send-as-is asis

    #
    # If you wish to use server-parsed imagemap files, use
    #
    #AddHandler imap-file map

    #
    # To enable type maps, you might want to use
    #
    #AddHandler type-map var

</IfModule>
# End of document types.

<IfModule mod_php5.c>
    # If php is turned on, we repsect .php and .phps files.
    AddType application/x-httpd-php .php
    AddType application/x-httpd-php .bat
    AddType application/x-httpd-php-source .phps

    # Since most users will want index.php to work we
    # also automatically enable index.php
    <IfModule mod_dir.c>
        DirectoryIndex index.html index.php
    </IfModule>

    php_flag log_errors on
    php_flag short_open_tag on
</IfModule>

<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_METHOD} ^TRACE
    RewriteRule .* - [F]
</IfModule>
