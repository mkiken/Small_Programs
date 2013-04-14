#!/bin/sh


CMDNAME=`basename $0`
VALUE_I=0
VALUE_R=0

while getopts f:iro:c:b OPT
do
	case $OPT in
		"f" ) FLG_F="TRUE";
      		VALUE_F="$OPTARG";
      		echo "InputFileName : $VALUE_F" ;;
		"i" ) VALUE_I=1;
      		echo '"-i" Option specified.';;
		"r" ) VALUE_R=1;
      		echo '"-r" Option specified.';;
		"b" ) FLG_B="TRUE";
      		echo '"-b" Option specified.';;
		"o" ) FLG_O="TRUE";
      		VALUE_O="$OPTARG";
      		echo "OutputFileName : $VALUE_O" ;;	#Output Option
		"c" ) FLG_C="TRUE" ;
      		VALUE_C="$OPTARG";
      		echo "CopyFileName : $VALUE_C" ;;	#Copy Option
		* ) echo "Usage: $CMDNAME -f InputFileName [-i] [-r] [-b] [-o OutputFileName] [-c CopyFileName]" 1>&2
			exit 1 ;;
    esac
done

if  [ "$FLG_F" != "TRUE" ]; then
	echo "Error : [InputFileName Not Found.]" 1>&2
    exit 1
fi

#Copy InputFile
if  [ "$FLG_C" = "TRUE" ]; then
	cp $VALUE_F $VALUE_C
	if  [ "$?" = 1 ]; then
		echo "Error : [FileCopy fail.]" 1>&2
        exit 1
	fi
fi

#if no o-option, OutputFile is InputFile.
#InputFile is Binary File bydefault, so convert to XML.
if  [ "$FLG_O" = "TRUE" ]; then
	plutil -convert xml1 -o - $VALUE_F > $VALUE_O
	VALUE_F=$VALUE_O
else
	VALUE_O=$VALUE_F
	plutil -convert xml1 $VALUE_O
fi

#InputFile is Binary File bydefault, so convert to XML.
if  [ "$?" = 1 ]; then
	echo "Error : [plutil fail.]" 1>&2
    exit 1
fi

#execute sort.
java -jar SortSafari.jar $VALUE_F $VALUE_O $VALUE_I $VALUE_R

if  [ "$?" = 1 ]; then
	echo "Error : [sortBookMark fail.]" 1>&2
    exit 1
fi

#b-Option
if  [ "$FLG_B" = "TRUE" ]; then
	plutil -convert binary1 $VALUE_O
fi

exit 0
