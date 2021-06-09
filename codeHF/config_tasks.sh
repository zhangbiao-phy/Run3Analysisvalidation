#!/bin/bash
# shellcheck disable=SC2034 # Ignore unused parameters.

# Configuration of tasks for runtest.sh
# (Cleans directory, modifies step activation, modifies JSON, generates step scripts.)

# Mandatory functions:
#   Clean                  Performs cleanup before (argument=1) and after (argument=2) running.
#   AdjustJson             Modifies the JSON file.
#   MakeScriptAli          Generates the AliPhysics script.
#   MakeScriptO2           Generates the O2 script.
#   MakeScriptPostprocess  Generates the postprocessing script.

####################################################################################################

# Steps
DOCLEAN=1           # Delete created files (before and after running tasks).
DOCONVERT=1         # Convert AliESDs.root to AO2D.root.
DOALI=1             # Run AliPhysics tasks.
DOO2=1              # Run O2 tasks.
DOPOSTPROCESS=1     # Run output postprocessing. (Compare AliPhysics and O2 output.)

# Disable incompatible steps.
[ "$ISINPUTO2" -eq 1 ] && { DOCONVERT=0; DOALI=0; }

# O2 database
DATABASE_O2="workflows.yml"
MAKE_GRAPH=0        # Make topology graph.

# Activation of O2 workflows
# QA
DOO2_QA_EFF=0       # qa-efficiency
DOO2_QA_SIM=0       # qa-simple
DOO2_MC_VALID=0     # hf-mc-validation
# PID
DOO2_PID_TPC=0      # pid-tpc-full
DOO2_PID_TOF=0      # pid-tof-full
DOO2_PID_TOF_QA=0   # pid-tof-qa-mc
# Vertexing
DOO2_SKIM=0         # hf-track-index-skims-creator
DOO2_CAND_2PRONG=0  # hf-candidate-creator-2prong
DOO2_CAND_3PRONG=0  # hf-candidate-creator-3prong
DOO2_CAND_X=0       # hf-candidate-creator-x
# Selectors
DOO2_SEL_D0=0       # hf-d0-candidate-selector
DOO2_SEL_DPLUS=0    # hf-dplus-topikpi-candidate-selector
DOO2_SEL_LC=0       # hf-lc-candidate-selector
DOO2_SEL_XIC=0      # hf-xic-topkpi-candidate-selector
DOO2_SEL_JPSI=0     # hf-jpsi-candidate-selector
DOO2_SEL_X=0        # hf-xic-topkpi-candidate-selector
# User tasks
DOO2_TASK_D0=1      # hf-task-d0
DOO2_TASK_DPLUS=0   # hf-task-dplus
DOO2_TASK_LC=0      # hf-task-lc
DOO2_TASK_XIC=0     # hf-task-xic
DOO2_TASK_JPSI=1    # hf-task-jpsi
DOO2_TASK_BPLUS=0   # hf-task-bplus
DOO2_TASK_X=1       # hf-task-x
# Tree creators
DOO2_TREE_D0=0      # hf-tree-creator-d0-tokpi
DOO2_TREE_LC=0      # hf-tree-creator-lc-topkpi

# Selection cuts
APPLYCUTS_D0=0      # Apply D0 selection cuts.
APPLYCUTS_DPLUS=0   # Apply D+ selection cuts.
APPLYCUTS_LC=0      # Apply Λc selection cuts.
APPLYCUTS_XIC=0     # Apply Ξc selection cuts.
APPLYCUTS_JPSI=1    # Apply J/ψ selection cuts.
APPLYCUTS_X=1       # Apply X selection cuts.

SAVETREES=0         # Save O2 tables to trees.
USEO2VERTEXER=0     # Use the O2 vertexer in AliPhysics.
DORATIO=0           # Plot histogram ratios in comparison.

####################################################################################################

# Clean before (argument=1) and after (argument=2) running.
function Clean {
  # Cleanup before running
  [ "$1" -eq 1 ] && { bash "$DIR_TASKS/clean.sh" || ErrExit; }

  # Cleanup after running
  [ "$1" -eq 2 ] && {
    rm -f "$LISTFILES_ALI" "$LISTFILES_O2" "$SCRIPT_ALI" "$SCRIPT_O2" "$SCRIPT_POSTPROCESS" || ErrExit "Failed to rm created files."
    [ "$JSON_EDIT" ] && { rm "$JSON_EDIT" || ErrExit "Failed to rm $JSON_EDIT."; }
  }

  return 0
}

# Modify the JSON file.
function AdjustJson {
  # Make a copy of the default JSON file to modify it.
  JSON_EDIT=""
  if [[ $APPLYCUTS_D0 -eq 1 || $APPLYCUTS_DPLUS -eq 1 || $APPLYCUTS_LC -eq 1 || $APPLYCUTS_XIC -eq 1 || $APPLYCUTS_JPSI -eq 1 || $APPLYCUTS_X -eq 1 ]]; then
    JSON_EDIT="${JSON/.json/_edit.json}"
    cp "$JSON" "$JSON_EDIT" || ErrExit "Failed to cp $JSON $JSON_EDIT."
    JSON="$JSON_EDIT"
  fi

  # Enable D0 selection.
  if [ $APPLYCUTS_D0 -eq 1 ]; then
    MsgWarn "\nUsing D0 selection cuts"
    ReplaceString "\"d_selectionFlagD0\": \"0\"" "\"d_selectionFlagD0\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
    ReplaceString "\"d_selectionFlagD0bar\": \"0\"" "\"d_selectionFlagD0bar\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi

  # Enable D+ selection.
  if [ $APPLYCUTS_DPLUS -eq 1 ]; then
    MsgWarn "\nUsing D+ selection cuts"
    ReplaceString "\"d_selectionFlagDPlus\": \"0\"" "\"d_selectionFlagDPlus\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi

  # Enable Λc selection.
  if [ $APPLYCUTS_LC -eq 1 ]; then
    MsgWarn "\nUsing Λc selection cuts"
    ReplaceString "\"d_selectionFlagLc\": \"0\"" "\"d_selectionFlagLc\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi

  # Enable Ξc selection.
  if [ $APPLYCUTS_XIC -eq 1 ]; then
    MsgWarn "\nUsing Ξc selection cuts"
    ReplaceString "\"d_selectionFlagXic\": \"0\"" "\"d_selectionFlagXic\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi

    # Enable J/ψ selection.
  if [ $APPLYCUTS_JPSI -eq 1 ]; then
    MsgWarn "\nUsing J/ψ selection cuts"
    ReplaceString "\"d_selectionFlagJpsi\": \"0\"" "\"d_selectionFlagJpsi\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi

    # Enable X(3872) selection.
  if [ $APPLYCUTS_X -eq 1 ]; then
    MsgWarn "\nUsing X(3872) selection cuts"
    ReplaceString "\"d_selectionFlagX\": \"0\"" "\"d_selectionFlagX\": \"1\"" "$JSON" || ErrExit "Failed to edit $JSON."
  fi
}

# Generate the O2 script containing the full workflow specification.
function MakeScriptO2 {
  WORKFLOWS=""
  [ $DOO2_QA_EFF -eq 1 ] && WORKFLOWS+=" o2-analysis-qa-efficiency"
  [ $DOO2_QA_SIM -eq 1 ] && WORKFLOWS+=" o2-analysis-qa-simple"
  [ $DOO2_SKIM -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-track-index-skims-creator"
  [ $DOO2_CAND_2PRONG -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-candidate-creator-2prong"
  [ $DOO2_CAND_3PRONG -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-candidate-creator-3prong"
  [ $DOO2_CAND_X -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-candidate-creator-x"
  [ $DOO2_PID_TPC -eq 1 ] && WORKFLOWS+=" o2-analysis-pid-tpc-full"
  [ $DOO2_PID_TOF -eq 1 ] && WORKFLOWS+=" o2-analysis-pid-tof-full"
  [ $DOO2_PID_TOF_QA -eq 1 ] && WORKFLOWS+=" o2-analysis-pid-tof-qa-mc"
  [ $DOO2_SEL_D0 -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-d0-candidate-selector"
  [ $DOO2_SEL_JPSI -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-jpsi-candidate-selector"
  [ $DOO2_SEL_DPLUS -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-dplus-topikpi-candidate-selector"
  [ $DOO2_SEL_LC -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-lc-candidate-selector"
  [ $DOO2_SEL_XIC -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-xic-topkpi-candidate-selector"
  [ $DOO2_SEL_X -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-x-tojpsipipi-candidate-selector"
  [ $DOO2_TASK_D0 -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-d0"
  [ $DOO2_TASK_JPSI -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-jpsi"
  [ $DOO2_TASK_DPLUS -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-dplus"
  [ $DOO2_TASK_LC -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-lc"
  [ $DOO2_TASK_XIC -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-xic"
  [ $DOO2_TASK_BPLUS -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-bplus"
  [ $DOO2_TASK_X -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-task-x"
  [ $DOO2_TREE_D0 -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-tree-creator-d0-tokpi"
  [ $DOO2_TREE_LC -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-tree-creator-lc-topkpi"
  [ $DOO2_MC_VALID -eq 1 ] && WORKFLOWS+=" o2-analysis-hf-mc-validation"

  # Translate options into arguments of the generating script.
  OPT_MAKECMD=""
  [ "$ISMC" -eq 1 ] && OPT_MAKECMD+=" --mc"
  [ "$DEBUG" -eq 1 ] && OPT_MAKECMD+=" -d"
  [ $SAVETREES -eq 1 ] && OPT_MAKECMD+=" -t"
  [ $MAKE_GRAPH -eq 1 ] && OPT_MAKECMD+=" -g"

  # Generate the O2 command.
  MAKECMD="python3 $DIR_EXEC/make_command_o2.py $DATABASE_O2 $OPT_MAKECMD"
  O2EXEC=$($MAKECMD -w "$WORKFLOWS")
  $MAKECMD -w "$WORKFLOWS" 1> /dev/null 2> /dev/null || ErrExit "Generating of O2 command failed."
  [ "$O2EXEC" ] || ErrExit "Nothing to do!"

  # Create the script with the full O2 command.
  cat << EOF > "$SCRIPT_O2"
#!/bin/bash
FileIn="\$1"
JSON="\$2"
mkdir sockets && \
$O2EXEC && \
rm -r sockets
EOF
}

function MakeScriptAli {
  ALIEXEC="root -b -q -l \"$DIR_TASKS/RunHFTaskLocal.C(\\\"\$FileIn\\\", \\\"\$JSON\\\", $ISMC, $USEO2VERTEXER)\""
  cat << EOF > "$SCRIPT_ALI"
#!/bin/bash
FileIn="\$1"
JSON="\$2"
$ALIEXEC
EOF
}

function MakeScriptPostprocess {
  POSTEXEC="echo Postprocessing"
  # Compare AliPhysics and O2 histograms.
  [[ $DOALI -eq 1 && $DOO2 -eq 1 ]] && {
    OPT_COMPARE=""
    [ $DOO2_SKIM -eq 1 ] && OPT_COMPARE+="-tracks-skim"
    [ $DOO2_CAND_2PRONG -eq 1 ] && OPT_COMPARE+="-cand2"
    [ $DOO2_CAND_3PRONG -eq 1 ] && OPT_COMPARE+="-cand3"
    [ $DOO2_TASK_D0 -eq 1 ] && OPT_COMPARE+="-d0"
    [ $DOO2_TASK_DPLUS -eq 1 ] && OPT_COMPARE+="-dplus"
    [ $DOO2_TASK_LC -eq 1 ] && OPT_COMPARE+="-lc"
    [ $DOO2_TASK_XIC -eq 1 ] && OPT_COMPARE+="-xic"
    [ $DOO2_TASK_JPSI -eq 1 ] && OPT_COMPARE+="-jpsi"
    [ "$OPT_COMPARE" ] && POSTEXEC+=" && root -b -q -l \"$DIR_TASKS/Compare.C(\\\"\$FileO2\\\", \\\"\$FileAli\\\", \\\"$OPT_COMPARE\\\", $DORATIO)\""
  }
  # Plot particle reconstruction efficiencies.
  [[ $DOO2 -eq 1 && $ISMC -eq 1 ]] && {
    PARTICLES=""
    [ $DOO2_TASK_D0 -eq 1 ] && PARTICLES+="-d0"
    [ $DOO2_TASK_DPLUS -eq 1 ] && PARTICLES+="-dplus"
    [ $DOO2_TASK_LC -eq 1 ] && PARTICLES+="-lc"
    [ $DOO2_TASK_XIC -eq 1 ] && PARTICLES+="-xic"
    [ $DOO2_TASK_JPSI -eq 1 ] && PARTICLES+="-jpsi"
    [ $DOO2_TASK_X -eq 1 ] && PARTICLES+="-x"
    [ "$PARTICLES" ] && POSTEXEC+=" && root -b -q -l \"$DIR_TASKS/PlotEfficiency.C(\\\"\$FileO2\\\", \\\"$PARTICLES\\\")\""
  }
  cat << EOF > "$SCRIPT_POSTPROCESS"
#!/bin/bash
FileO2="\$1"
FileAli="\$2"
$POSTEXEC
EOF
}
