#!/bin/bash

if [ "$GFXR_LAYER_PATH" != "" ];
then
	GFXR_REPLAYER="$GFXR_LAYER_PATH/gfxrecon-replay"
fi
if [ "$VKTRACE_LAYER_PATH" != "" ];
then
	VKTRACE_REPLAYER="$VKTRACE_LAYER_PATH/vkreplay"
fi
if [ "$LAVATUBE_LAYER_PATH" != "" ];
then
	LAVATUBE_REPLAYER="$LAVATUBE_LAYER_PATH/lava-replay"
fi

REPORTDIR=reports/perf/demos${TAG}
CSV=$REPORTDIR/report.csv
DEMO_PARAMS="--benchmark -bfs 100 -bw 0"
TIMER="perf stat -r 3 -o $(pwd)/time.txt"
TRACEDIR=traces${TAG}
GFXR_REPLAYER=${GFXR_REPLAYER:-"$(which gfxrecon-replay)"}
VKTRACE_REPLAYER=${VKTRACE_REPLAYER:-"$(which vkreplay)"}
LAVATUBE_REPLAYER=${LAVATUBE_REPLAYER:-"$(which lava-replay)"}
REGEX='s/\s*\([0-9\.,]*\).*/\1/'

mkdir -p $REPORTDIR

echo "Test,Native clock,Gfx clock,Vktrace clock,Lava clock,Native cycles,Gfx cycles,Vktrace cycles,Lava cycles,Native instr,Gfxr instr,Vktrace instr,Lava instr" > $CSV

function demo
{
	NAME="demo_$1"
	echo
	echo "** $1 **"
	echo

	# Native timing run
	( cd external/vulkan-demos ; $TIMER build/bin/$1 $DEMO_PARAMS )
	NATIVE_CLOCK=$(cat time.txt | grep 'msec task-clock' | sed $REGEX | sed 's/,//g' )
	NATIVE_CYCLES=$(cat time.txt | grep cycles | head -1 | sed $REGEX | sed 's/,//g' )
	NATIVE_INSTR=$(cat time.txt | grep instru | head -1 | sed $REGEX | sed 's/,//g' )

	# Gfxr timing run
	$TIMER $GFXR_REPLAYER -m rebind --vssb $TRACEDIR/${NAME}_default.gfxr
	GFXR_CLOCK=$(cat time.txt | grep 'msec task-clock' | sed $REGEX | sed 's/,//g' )
	GFXR_CYCLES=$(cat time.txt | grep cycles | head -1 | sed $REGEX | sed 's/,//g' )
	GFXR_INSTR=$(cat time.txt | grep instru | head -1 | sed $REGEX | sed 's/,//g' )
	cat time.txt

	# Vktrace timing run
	$TIMER $VKTRACE_REPLAYER -evsc TRUE -vscpm TRUE -o $TRACEDIR/${NAME}.vktrace
	VKTRACE_CLOCK=$(cat time.txt | grep 'msec task-clock' | sed $REGEX | sed 's/,//g' )
	VKTRACE_CYCLES=$(cat time.txt | grep cycles | head -1 | sed $REGEX | sed 's/,//g' )
	VKTRACE_INSTR=$(cat time.txt | grep instru | head -1 | sed $REGEX | sed 's/,//g' )
	cat time.txt

	# Lavatube timing run
	$TIMER $LAVATUBE_REPLAYER -v -vp $TRACEDIR/${NAME}.vk
	LAVA_CLOCK=$(cat time.txt | grep 'msec task-clock' | sed $REGEX | sed 's/,//g' )
	LAVA_CYCLES=$(cat time.txt | grep cycles | head -1 | sed $REGEX | sed 's/,//g' )
	LAVA_INSTR=$(cat time.txt | grep instru | head -1 | sed $REGEX | sed 's/,//g' )
	cat time.txt

	echo "$1,$NATIVE_CLOCK,$GFXR_CLOCK,$VKTRACE_CLOCK,$LAVA_CLOCK,$NATIVE_CYCLES,$GFXR_CYCLES,$VKTRACE_CYCLES,$LAVA_CYCLES,$NATIVE_INSTR,$GFXR_INSTR,$VKTRACE_INSTR,$LAVA_INSTR" >> $CSV
}

source scripts/demo_list.sh

echo "</table></body></html>" >> $REPORT
