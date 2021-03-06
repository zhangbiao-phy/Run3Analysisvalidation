#!/bin/bash

# Script to run O2 tasks in jobs

LISTINPUT="$1"
JSON="$2"
SCRIPT="$3"
DEBUG=$4
NFILESPERJOB=$5
FILEOUT_TREE="$6"
FILEOUT="AnalysisResults.root"
NJOBSPARALLEL=$7

[ "$DEBUG" -eq 1 ] && echo "Running $0"

# This directory
DIR_THIS="$(dirname "$(realpath "$0")")"

# Load utilities.
# shellcheck disable=SC1091 # Ignore not following.
source "$DIR_THIS/utilities.sh" || { echo "Error: Failed to load utilities."; exit 1; }

CheckFile "$SCRIPT"
CheckFile "$JSON"
SCRIPT="$(realpath "$SCRIPT")"
JSON="$(realpath "$JSON")"

LogFile="log_o2.log"
ListIn="list_o2.txt"
FilesToMerge="ListOutToMergeO2.txt"
FilesToMergeTree="ListOutToMergeO2Tree.txt"
DirBase="$PWD"
IndexFile=0
ListRunScripts="$DirBase/ListRunScriptsO2.txt"
DirOutMain="output_o2"

# Clean before running.
rm -rf "$ListRunScripts" "$FilesToMerge" "$FilesToMergeTree" "$FILEOUT" "$FILEOUT_TREE" "$DirOutMain" || ErrExit "Failed to delete output files."

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
    echo "$FileOut" >> "$DirBase/$FilesToMerge" || ErrExit "Failed to echo to $DirBase/$FilesToMerge."
    [ "$FILEOUT_TREE" ] && {
      FileOutTree="$DirOut/$FILEOUT_TREE"
      echo "$FileOutTree" >> "$DirBase/$FilesToMergeTree" || ErrExit "Failed to echo to $DirBase/$FilesToMergeTree."
    }
    # Add this job in the list of commands.
    echo "cd \"$DirOut\" && bash \"$DIR_THIS/run_o2.sh\" \"$SCRIPT\" \"$ListIn\" \"$JSON\" \"$LogFile\"" >> "$ListRunScripts" || ErrExit "Failed to echo to $ListRunScripts."
  fi
  echo "$FileIn" >> "$DirOut/$ListIn" || ErrExit "Failed to echo to $DirOut/$ListIn."
  [ "$DEBUG" -eq 1 ] && echo "Input file ($IndexFile, job $IndexJob): $FileIn"
  ((IndexFile+=1))
done < "$LISTINPUT"

CheckFile "$ListRunScripts"
echo "Running O2 jobs... ($(wc -l < "$ListRunScripts") jobs, $NJOBSPARALLEL parallel, $NFILESPERJOB files/job)"
OPT_PARALLEL="--halt soon,fail=100% --jobs $NJOBSPARALLEL"
if [ "$DEBUG" -eq 0 ]; then
  # shellcheck disable=SC2086 # Ignore unquoted options.
  parallel $OPT_PARALLEL < "$ListRunScripts" > $LogFile 2>&1
else
  # shellcheck disable=SC2086 # Ignore unquoted options.
  parallel $OPT_PARALLEL --will-cite --progress < "$ListRunScripts" > $LogFile
fi || ErrExit "\nCheck $(realpath $LogFile)"
grep -q "\\[WARN\\]" "$LogFile" && MsgWarn "There were warnings!\nCheck $(realpath $LogFile)"
grep -q -e "\\[ERROR\\]" -e "segmentation" "$LogFile" && MsgErr "There were errors!\nCheck $(realpath $LogFile)"
rm -f "$ListRunScripts" || ErrExit "Failed to rm $ListRunScripts."

echo "Merging output files... (output file: $FILEOUT, logfile: $LogFile)"
hadd $FILEOUT @"$FilesToMerge" >> $LogFile 2>&1 || \
{ MsgErr "Error\nCheck $(realpath $LogFile)"; tail -n 2 "$LogFile"; exit 1; }
rm -f "$FilesToMerge" || ErrExit "Failed to rm $FilesToMerge."

[ "$FILEOUT_TREE" ] && {
  echo "Merging output trees... (output file: $FILEOUT_TREE, logfile: $LogFile)"
  hadd "$FILEOUT_TREE" @"$FilesToMergeTree" >> $LogFile 2>&1 || \
  { MsgErr "Error\nCheck $(realpath $LogFile)"; tail -n 2 "$LogFile"; exit 1; }
  rm -f "$FilesToMergeTree" || ErrExit "Failed to rm $FilesToMergeTree."
}

exit 0
