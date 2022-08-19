#!/bin/bash

# Copyright (c) 2020 Manuel Pitz
#
# Licensed under the Apache License, Version 2.0, <LICENSE-APACHE or
# http://apache.org/licenses/LICENSE-2.0> or the MIT license <LICENSE-MIT or
# http://opensource.org/licenses/MIT>, at your option. This file may not be
# copied, modified, or distributed except according to those terms.

DEBUG=0


handle_Type () {
	local vendor=$1
	local attrName=$2
	local data=$3[@]
	temp=`grep "$attrName" <<< "$data" | sed "s/^[ \t]*//" | tr -s ' ' | cut -d" " -f10 | sed "s/^[ \t]*//"`
	echo $temp
}

handle_singleCol () {
	local vendor=$1
	local attrName=$2
	local data=$3[@]
	temp=`grep "$attrName" <<< "$data" | sed "s/^[ \t]*//" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	echo $temp
}

handle_SATA_HDD () {
	local vendor=$1
	local driveData=$2[@]

	temp=$(handle_Type $vendor "Temperature_Celsius" "$driveData")
	seek_err=$(handle_Type $vendor "Seek_Error_Rate" "$driveData")
	read_err=$(handle_Type $vendor "Raw_Read_Error_Rate" "$driveData")
	power_on=$(handle_Type $vendor "Power_On_Hours" "$driveData")
	status=$(handle_singleCol $vendor "SMART overall-health self-assessment test result:" "$driveData")
	printf "%10s %10s %20s %20s %10s %10s %10s %10s %10s\n" $path "$vendor" "$driveModel" "$driveSerial" "$temp" "$seek_err" "$read_err" "$power_on" "$status"
}

handle_SAS_HDD () {
	local vendor=$1
	local driveData=$2[@]

	if [ $DEBUG == 1 ]; then
		echo "SAS handle"
	fi

	temp=`grep "Drive Temperature:" <<< "$driveData" | tr -s ' ' | cut -d" " -f4 | sed "s/^[ \t]*//"`

	readCorrected=`grep "read:" <<< "$driveData" | tr -s ' ' | cut -d" " -f5 | sed "s/^[ \t]*//"`
	readunCorrected=`grep "read:" <<< "$driveData" | tr -s ' ' | cut -d" " -f8 | sed "s/^[ \t]*//"`
	writeCorrected=`grep "write:" <<< "$driveData" | tr -s ' ' | cut -d" " -f5 | sed "s/^[ \t]*//"`
	writeunCorrected=`grep "write:" <<< "$driveData" | tr -s ' ' | cut -d" " -f8 | sed "s/^[ \t]*//"`

	seek_err=$(handle_Type $vendor "Seek_Error_Rate" "$driveData")
	read_err=$(($readCorrected + $readunCorrected + $writeCorrected + $writeunCorrected))
	power_on=$(handle_Type $vendor "Power_On_Hours" "$driveData")
	status=$(handle_singleCol $vendor "Status:" "$driveData")
	printf "%10s %10s %20s %20s %10s %10s %10s %10s %10s\n" $path "$vendor" "$driveModel" "$driveSerial" "$temp" "$seek_err" "$read_err" "$power_on" "$status"
}



echo "readSmartData"

mapfile -t DRIVES < <(smartctl --scan)

printf "%10s %10s %20s %20s %10s %10s %10s %10s %10s\n" "Path" "Vendor" "Model" "Serial" "Temp" "Seek_err" "Read_err" "Power_on" "Status"
for drive in "${DRIVES[@]}"
do
	path=`cut -d" " -f1 <<< "$drive"`
	devType=`cut -d" " -f6 <<< "$drive"`

	if [ $path == "/dev/bus/0" ]; then continue; fi

	driveData=`smartctl -a $path`
	driveFamily=`grep "Model Family:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	driveVendor=`grep "Vendor:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	driveModel=`grep "Device Model:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`

	driveSerial=`grep "Serial Number:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`

	if [ -z "$driveSerial" ]; then
		driveSerial=`grep "Serial number:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	fi

	if [ -z "$driveModel" ]; then
		driveModel=`grep "Product:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	fi

	#echo $driveName
	if [ -n "$driveVendor" ]; then
		vendor=$driveVendor
	elif [ -z "$driveFamily" ]; then
		vendor=`cut -d" " -f1 <<< "$driveModel"`
	else
		vendor=`cut -d" " -f1 <<< "$driveFamily"`
	fi

	tmpModel=`cut -d" " -f2 <<< "$driveModel"`
	if [ -n "$tmpModel" ]; then
		driveModel=$tmpModel
	fi

	if [[ $vendor == *"Seagate"* ]]; then
		#echo "rerun smartctl for Seagate drives"
		driveData=`smartctl -a -v 7,raw48:54 -v 1,raw48:54 $path`
	fi


	sasFlag=`grep "Transport protocol:" <<< "$driveData" | tr -s ' ' | cut -d":" -f2 | sed "s/^[ \t]*//"`
	if [[ $sasFlag == *"SAS"* ]]; then
		handle_SAS_HDD $vendor "$driveData"
	else
		handle_SATA_HDD $vendor "$driveData"
	fi
done
