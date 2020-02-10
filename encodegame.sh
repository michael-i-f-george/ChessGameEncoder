#!/bin/bash


# TOURNAMENT TEMPLATE SPECIFIED?
if [ $# -eq 0 ]; then
   echo "./encode.sh <tournament_template.pgn>"
   exit 1
fi
if [ ! -n "$1" ]; then
   echo "A tournament template is required: script halted."
   exit 2
fi 
if [ ! -f "$1" ]; then
   echo "${1} not found: script halted"
   exit 3
fi  


# SWITCH TO WORKING DIRECTORY.
if [ ! -d "/home/michael/mg.pgn/" ]; then
   echo "Working directory not found: script halted"
   exit 4
fi  
cd /home/michael/mg.pgn/


# NO REMAINING FILE FROM PREVIOUS RUN?
if [ -f "input.pgn" ]; then
   echo "input.pgn detected: script halted."
   exit 5
fi  
if [ -f "temp.pgn" ]; then
   echo "temp.pgn detected: script halted."
   exit 6
fi  
if [ -f "output.pgn" ]; then
   echo "output.pgn detected: script halted."
   exit 7
fi
if [ -f "MG_analyses_OLD.sg4" ]; then
   echo "MG_analyses_OLD.sg4: script halted."
   exit 8
fi
if [ -f "MG_analyses_OLD.si4" ]; then
   echo "MG_analyses_OLD.si4: script halted."
   exit 9
fi
if [ -f "MG_analyses_OLD.sn4" ]; then
   echo "MG_analyses_OLD.sn4: script halted."
   exit 10
fi
# Only one MG_20*.pgn?
nCount=`ls -1 MG_20*.pgn 2>/dev/null | wc -l`
if [ $nCount != 1 ]; then
   echo "There must exactly one 'MG_20....pgn': script halted."
   exit 11
else
   sPreviousMGPGN="$(ls -1 MG_20*.pgn 2> /dev/null)"
fi


# MERGE NEW GAME WITH TOURNAMENT TEMPLATE.
datCurrentDate=$(date +%Y.%m.%d)
if [ -f "fromdroidfish.pgn" ]; then
   # Keep the 7st lines of droidfish.pgn, skip the 7st lines of template and add the move section from droidfish.pgn
   head -7 fromdroidfish.pgn > temp.pgn && tail -n +8 ${1} | grep "^\[" >> temp.pgn && grep -v "^\[" fromdroidfish.pgn >> temp.pgn
else
   touch input.pgn
   scid input.pgn
   # Check if game has really been entered with Scid.
   actualsize=$(wc -c < "input.pgn")
   if [ $actualsize -eq 0 ]; then
      echo "input.pgn, normaly produced by Scid, is empty: script halted."
      trash input.pgn
      exit 12
   fi   
   # Merge metadata from template and moves from Scid
   grep "^\[" ${1} | sed 's/Date \"????\.??\.??\"\]/Date \"'"$datCurrentDate"'\"\]/' > temp.pgn
   echo "" >> temp.pgn
   grep -v "^\[\|^$" input.pgn >> temp.pgn
fi  
echo "   input file and template merged"


# ADD ECO, OPENING NAME TO NEW GAME AND FORMAT IT.
pgn-extract -e/usr/share/pgn-extract/eco.pgn -Rtagorder.txt temp.pgn -ooutput.pgn && cp output.pgn /home/michael/nicbase3/input.pgn 2> /dev/null
echo "   processed by PGN-Extract"


# OPEN NEW GAME IN NICBASE 3 TO GET NIC KEY.
dosbox -exit -c 'keyb be' -c 'mount d /home/michael/' -c 'd:' -c 'cd d:\nicbase3' -c 'pgn2nic.exe input.pgn input' -c 'nicbase3' 2> /dev/null
echo "   processed by NICBase 3"


# LET USER FILL NEW GAME METADATA.
if [ -f "fromdroidfish.pgn" ]; then
   meld fromdroidfish.pgn output.pgn
else
   meld input.pgn output.pgn
fi  


# APPEND NEW GAME TO PGN COLLECTION FLAT FILE.
read -p "Append it to PGN collection flat file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo  "   Appending it to PGN game file"
    datNow=`date '+MG_%Y-%m-%dT%H:%M:%S.pgn'`
    cat MG_20*.pgn output.pgn > $datNow
    echo "   Launching comparison for validation"
    meld MG_20*.pgn
    echo "   Compressing new PGN collection"
    gzip -k9 $datNow 
fi


# APPEND NEW GAME TO SCID DATABASE
read -p "Append new game to Scid database? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "   Convert new game to Scid format."
	pgnscid output.pgn output
	echo "   Renaming to avoid collisions."
	mv MG_analyses.sg4 MG_analyses_OLD.sg4
	mv MG_analyses.si4 MG_analyses_OLD.si4
	mv MG_analyses.sn4 MG_analyses_OLD.sn4
	echo "   Merge new game and Scid database."
	scmerge MG_analyses MG_analyses_OLD output
fi


# DELETE WORK FILES
echo  "Deleting work files"
if [ -f "input.pgn" ]; then
   trash input.pgn
fi
if [ -f "temp.pgn" ]; then
   trash temp.pgn
fi
if [ -f "output.pgn" ]; then
   trash output.pgn
fi
if [ -f "fromdroidfish.pgn" ]; then
   trash fromdroidfish.pgn
fi
if [ -f "output.sg4" ]; then
   trash output.sg4
fi
if [ -f "output.si4" ]; then
   trash output.si4
fi
if [ -f "output.sn4" ]; then
   trash output.sn4
fi
if [ -f "MG_analyses_OLD.sg4" ]; then
   trash MG_analyses_OLD.sg4
fi
if [ -f "MG_analyses_OLD.si4" ]; then
   trash MG_analyses_OLD.si4
fi
if [ -f "MG_analyses_OLD.sn4" ]; then
   trash MG_analyses_OLD.sn4
fi
trash "${sPreviousMGPGN}"
trash ${sPreviousMGPGN}.gz


# LAUNCH SCID TO ALLOW USER TO ANALYSE GAME.
echo  "Launching Scid for game analysis."
scid MG_analyses.si4


# GET OUT
exit 0



# OLD CODE THAT CAN BE USEFUL LATER

# echo Script name: $0

# scid output.pgn MG_analyses.si4

# grep -v "^\[\|^$" input.pgn >> input_.pgn

# head -31 ${1} > input.pgn && tail -n +10 fromdroidfish.pgn >> input.pgn # Keep the 31st lines of the template and skip the 10st lines of droidfish.pgn

# grep -v "^\[TimeControl\ \"" fromdroidfish.pgn > input.pgn

# head -7 fromdroidfish.pgn | sed 's/Date \"????\.??\.??\"\]/Date \"$datCurrentDate\"\]/' > temp.pgn && tail -n +8 ${1} | grep "^\[" | sed 's/Date \"????\.??\.??\"\]/Date \"'"$datCurrentDate"'\"\]/' >> temp.pgn && grep -v "^\[" fromdroidfish.pgn >> temp.pgn

#datCurrentDate='date +%Y.%m.%d'

