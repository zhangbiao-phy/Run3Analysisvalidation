#!/bin/bash

# Script to run Run 2 to Run 3 conversion in jobs

LISTINPUT="$1"
LISTOUTPUT="$2"
ISMC=$3
DEBUG=$4
NFILESPERJOB=$5
FILEOUT="AO2D.root"

[ "$DEBUG" -eq 1 ] && echo "Running $0"

# This directory
DIR_THIS="$(dirname "$(realpath "$0")")"

# Load utilities.
# shellcheck disable=SC1091 # Ignore not following.
source "$DIR_THIS/utilities.sh" || { echo "Error: Failed to load utilities."; exit 1; }


LogFile="log_convert.log"
ListIn="list_convert.txt"
DirBase="$PWD"
IndexFile=0
ListRunScripts="$DirBase/ListRunScriptsConversion.txt"
DirOutMain="output_conversion"

# Clean before running.
rm -rf "$ListRunScripts" "$LISTOUTPUT" "$DirOutMain" || ErrExit "Failed to delete output files."

CheckFile "$LISTINPUT"
echo "Output directory: $DirOutMain (logfiles: $LogFile)"
# Loop over input files
while read -r FileIn; do
  CheckFile "$FileIn"
  FileIn="$(realpath "$FileIn")"
  IndexJob=$((IndexFile / NFILESPERJOB))
  DirOut="$DirOutMain/$IndexJob"
  # New job
  if [ $((IndexFile % NFILESPERJOB)) -eq 0 ]; then
    mkdir -p $DirOut || ErrExit "Failed to mkdir $DirOut."
    FileOut="$DirOut/$FILEOUT"
    echo "$DirBase/$FileOut" >> "$DirBase/$LISTOUTPUT" || ErrExit "Failed to echo to $DirBase/$LISTOUTPUT."
    # Add this job in the list of commands.
    echo "cd \"$DirOut\" && bash \"$DIR_THIS/run_convert.sh\" \"$ListIn\" $ISMC \"$LogFile\"" >> "$ListRunScripts" || ErrExit "Failed to echo to $ListRunScripts."
  fi
  echo "$FileIn" >> "$DirOut/$ListIn" || ErrExit "Failed to echo to $DirOut/$ListIn."
  [ "$DEBUG" -eq 1 ] && echo "Input file ($IndexFile, job $IndexJob): $FileIn"
  ((IndexFile+=1))
done < "$LISTINPUT"

CheckFile "$ListRunScripts"
echo "Running conversion jobs... ($(wc -l < "$ListRunScripts") jobs, $NFILESPERJOB files/job)"
OPT_PARALLEL="--halt soon,fail=100%"
if [ "$DEBUG" -eq 0 ]; then
  # shellcheck disable=SC2086 # Ignore unquoted options.
  parallel $OPT_PARALLEL < "$ListRunScripts" > $LogFile 2>&1
else
  # shellcheck disable=SC2086 # Ignore unquoted options.
  parallel $OPT_PARALLEL --will-cite --progress < "$ListRunScripts" > $LogFile
fi || ErrExit "\nCheck $(realpath $LogFile)"
grep -q -e '^'"W-" -e '^'"Warning" "$LogFile" && MsgWarn "There were warnings!\nCheck $(realpath $LogFile)"
grep -q -e '^'"E-" -e '^'"Error" "$LogFile" && MsgErr "There were errors!\nCheck $(realpath $LogFile)"
grep -q -e '^'"F-" -e '^'"Fatal" -e "segmentation" "$LogFile" && ErrExit "There were fatal errors!\nCheck $(realpath $LogFile)"
rm -f "$ListRunScripts" || ErrExit "Failed to rm $ListRunScripts."

exit 0
