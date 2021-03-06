#!/bin/bash
# shellcheck disable=SC2034 # Ignore unused parameters.

# Input specification for runtest.sh
# (Modifies input parameters.)

INPUT_CASE=2            # Input case

NFILESMAX=1             # Maximum number of processed input files. (Set to -0 to process all; to -N to process all but the last N files.)

# Number of input files per job (Automatic optimisation on if < 1.)
NFILESPERJOB_CONVERT=0  # Conversion
NFILESPERJOB_ALI=0      # AliPhysics
NFILESPERJOB_O2=1       # O2

# Maximum number of simultaneously running O2 jobs
NJOBSPARALLEL_O2=$(python3 -c "print(min(10, round($(nproc) / 2)))")

JSONRUN3="dpl-config_run3.json"  # Run 3 tasks parameters
JSONRUN5="dpl-config_run5.json"  # Run 5 tasks parameters
JSON="$JSONRUN3"

INPUT_FILES="AliESDs.root"  # Input file pattern

case $INPUT_CASE in
  1)
    INPUT_LABEL="Run 2, p-p real LHC17p"
    INPUT_DIR="/mnt/data/Run2/LHC17p_pass1_CENT_woSDD/282341";;
  2)
    INPUT_LABEL="Run 2, p-p MC LHC17p"
    INPUT_DIR="/mnt/data/Run2/LHC18a4a2_cent/282099"
    ISMC=1;;
  3)
    INPUT_LABEL="Run 2, p-p MC LHC17p"
    INPUT_DIR="/mnt/data/Run2/LHC18a4a2_cent/282341"
    ISMC=1;;
  4)
    INPUT_LABEL="Run 2, Pb-Pb real LHC15o"
    INPUT_DIR="/mnt/data/Run2/LHC15o/246751/pass1"
    TRIGGERSTRINGRUN2="CV0L7-B-NOPF-CENT"
    TRIGGERBITRUN3=5;; #FIXME
  5)
    INPUT_LABEL="Run 2, Pb-Pb MC LHC15o"
    INPUT_DIR="/mnt/data/Run2/LHC15k1a3/246391"
    ISMC=1;;
  6)
    INPUT_LABEL="Run 2, p-p MC LHC16p, dedicated Ξc"
    INPUT_DIR="/mnt/data/Run2/LHC19g6f3/264347"
    ISMC=1;;
  7)
    INPUT_LABEL="Run 5, p-p MC 14 TeV MB, Scenario 3"
    INPUT_DIR="/data/Run5/MC/pp_14TeV/MB_S3_latest"
    INPUT_FILES="AODRun5.*.root"
    JSON="$JSONRUN5"
    ISINPUTO2=1
    ISMC=1;;
esac
