#!/bin/bash
#
# shell script wrapper for java .jar files
#
# creates a script that extracts jars to a cache directory
# if necessary, then runs them from the cache dir.
#
# jars and other settings are specified in a special
# configuration file that is simply sourced into this
# script.
#
# This program is licensed under the GNU General Public License,
# available at http://www.gnu.org/copyleft/gpl.html
#
# The scripts it produces are not - they are yours and yours alone,
# to use at your own risk.
# IN NO EVENT SHALL MARTIAN SOFTWARE BE LIABLE FOR ANY LOSS OF PROFIT 
# OR ANY OTHER COMMERCIAL DAMAGE, INCLUDING BUT NOT LIMITED TO SPECIAL, 
# INCIDENTAL, CONSEQUENTIAL OR OTHER DAMAGES. MARTIAN SOFTWARE  SPECIFICALLY 
# DISCLAIMS ALL OTHER WARRANTIES, EXPRESSED OR IMPLIED, INCLUDING BUT 
# NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE, RELATED TO DEFECTS IN THE SOFTWARE OR 
# DOCUMENTATION. 
#
# --
# Marty Lamb
# Martian Software, Inc.
# http://martiansoftware.com/lab/jar2sh.html

BANNER="jar2sh v0.1"

PROG=`basename "$0"`
if [ $# -eq 0 -o "$1" == "--help" -o "$1" == "-h" ]; then
  echo $BANNER
  echo "Usage: $PROG NEWSCRIPT EXECUTABLE_JAR [OTHER JARS...]"
  echo "       Creates a wrapper called NEWSCRIPT that wraps the"
  echo "       specified executable jar (i.e., launchable via \"java -jar\")"
  echo "       and optionally other jars as well."
  echo ""
  echo "   or: jar2sh CONFIG_FILE"
  echo "       Reads the specified configuration file, providing more options."
  echo ""
  echo "   or: jar2sh -n|--new"
  echo "       Outputs a blank configuration file to use as a starting"
  echo "       point."
  echo ""
  echo "   or: jar2sh -h|--help"
  echo "       Prints this message."
  exit 0
fi

# output a blank configuration file and exit
if [ "$1" == "-n" -o "$1" == "-new" ]; then
cat <<'EOF'
# jar2sh configuration file
#
# this file is sourced directly into jar2sh at run time.
#
# uncomment and fill in as necessary.

# the script to create (required)
JAR2SH_SCRIPT=""

# the executable jar to wrap, if any.  If specified, java
# will be invoked with the -jar option, using this jar as
# its parameter.  If not specified, you MUST specify a
# main class (below).
#JAR2SH_EXEJAR=""

# other jars to wrap in addition to the optional executable
# jar.  This should be a whitespace-delimited list.  Wildcards OK.
# example:
# JAR2SH_JARS="/path/to/some.jar ~/jars/*.jar"
#JAR2SH_JARS=""

# the main class to launch if an executable jar is not being 
# used.  If not specified, you MUST specify an executable jar.
#JAR2SH_MAINCLASS=""

# if you need to, you can override the default command ("java")
# used to launch the JVM.  The command must be in the user's path.
#JAR2SH_JAVA="java"

# you can also provide additional VM arguments if necessary
#JAR2SH_VMARGS=""

# uncomment this line to run rlwrap (readline wrapper) around
# java if available on the user's computer
#JAR2SH_RLWRAP=y

EOF
  exit 0
fi

echo $BANNER
JAR2SH_SCRIPT=""
JAR2SH_EXEJAR=""
JAR2SH_JARS=""
JAR2SH_MAINCLASS=""
JAR2SH_PREJAVA=""
JAR2SH_POSTJAVA=""
JAR2SH_JAVA="java"
JAR2SH_VMARGS=""
JAR2SH_RLWRAP=""

if [ $# -eq 1 ]; then
  if [ ! -r "$1" ]; then
    echo "Unable to read config file $1" >&2
    exit 1
  fi
  echo "Loading config file $1..."
  . $1
  echo "Finished loading config file $1"
else
  JAR2SH_SCRIPT="$1"
  shift
  JAR2SH_EXEJAR="$1"
  shift
  JAR2SH_JARS="$*"
fi  

[ "${JAR2SH_RLWRAP}" == "y" ] && JAR2SH_RLWRAP=Y

if [ -z "${JAR2SH_EXEJAR}" -a -z "${JAR2SH_MAINCLASS}" ]; then
  echo "You must specify either an executable jar or a main class." >&2
  exit 1
fi

if [ -n "${JAR2SH_EXEJAR}" -a -n "${JAR2SH_MAINCLASS}" ]; then
  echo "You must specify EITHER an executable jar or a main class - not both." >&2
  exit 1
fi

if [ -z "${JAR2SH_EXEJAR}" -a -z "${JAR2SH_JARS}" ]; then
  echo "No jars specified - nothing to do." >&2
  exit 1
fi

if [ -z "${JAR2SH_JAVA}" ]; then
  echo "JAR2SH_JAVA command is empty.  Should it be \"java\"?" >&2
  exit 1
fi

echo "Bundling jars..."
# build a tar file with no leading path info
TMPFILE="jar2sh-$$.tgz"
trap 'rm -f $TMPFILE; exit 1' HUP INT QUIT TERM
TARCMD="tar -czvf $TMPFILE"
PWD=`pwd`
for JAR in ${JAR2SH_EXEJAR} ${JAR2SH_JARS} ; do
  DIR=`dirname $JAR`
  TARCMD="$TARCMD -C $DIR `basename $JAR` -C $PWD"
done
$TARCMD
if [ $? -ne 0 ]; then
  echo "Unable to bundle jar files.  The command I tried was:" >&2
  echo $TARCMD >&2
  exit 1
fi
echo ""

MD5=`md5sum $TMPFILE | sed -e 's/ .*//'`
BUNDLEID="${JAR2SH_SCRIPT}-$MD5-`date +%s`"
echo "Bundle ID: $BUNDLEID"
BUNDLESIZE=`stat -c %s $TMPFILE`
echo "Bundle size: $BUNDLESIZE bytes"


#----------------------------------------------------------------------
echo "Writing script ${JAR2SH_SCRIPT}"...
cat > ${JAR2SH_SCRIPT} <<EOF
#!/bin/bash
# jar wrapper generated by jar2sh
BUNDLEID="${BUNDLEID}"
BUNDLESIZE="${BUNDLESIZE}"
JAVA="${JAR2SH_JAVA}"
VMARGS="${JAR2SH_VMARGS}"
RLWRAP=""
EOF

# now disable substitution in the heredoc
cat >> ${JAR2SH_SCRIPT} <<'EOF'
PROG=`basename $0`
JARDIR="${HOME}/.jar2sh-cache/${PROG}"

# if there's a different version of the same command cached, blow it away
if [ -r "${JARDIR}/bundleid.jar2sh" ]; then
  [ "${BUNDLEID}" == `cat "${JARDIR}/bundleid.jar2sh"` ] || rm -rf "${JARDIR}"
fi

if [ ! -d "${JARDIR}" ]; then
  TMPJARDIR="${JARDIR}.$$-tmp"
  trap 'rm -rf "$TMPJARDIR"; exit 1' HUP INT QUIT TERM
  mkdir -p "${TMPJARDIR}"
  tail -c $BUNDLESIZE $0 | tar -zx -C ${TMPJARDIR}
  if [ $? -ne 0 ]; then
    echo "Unable to unbundle jars." >&2
    exit 1
  fi
  echo ${BUNDLEID} > "${TMPJARDIR}/bundleid.jar2sh"
  mv "${TMPJARDIR}" "${JARDIR}"
  trap "" HUP INT QUIT TERM
fi

for JAR in ${JARDIR}/*; do
  CLASSPATH="${CLASSPATH}:${JAR}"
done

EOF

if [ "${JAR2SH_RLWRAP}" == "Y" ]; then
  echo "which rlwrap && RLWRAP=rlwrap" >> "${JAR2SH_SCRIPT}"
fi

if [ -n "${JAR2SH_EXEJAR}" ]; then
  echo "\$RLWRAP ${JAR2SH_JAVA} ${JAR2SH_VMARGS} -cp \$CLASSPATH -jar \$JARDIR/`basename ${JAR2SH_EXEJAR}` \$*" >> "${JAR2SH_SCRIPT}"
else
  echo "\$RLWRAP ${JAR2SH_JAVA} ${JAR2SH_VMARGS} -cp \$CLASSPATH ${JAR2SH_MAINCLASS} \$*" >> "${JAR2SH_SCRIPT}"
fi

cat >> ${JAR2SH_SCRIPT} <<'EOF'
exit $?
EOF

cat $TMPFILE >> "${JAR2SH_SCRIPT}"
#----------------------------------------------------------------------
chmod +x "${JAR2SH_SCRIPT}"

echo "Cleaning up..."
rm -f $TMPFILE
echo "Done."
