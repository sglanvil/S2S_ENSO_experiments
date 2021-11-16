#!/bin/bash

module load nco

# ------------- edit this if you need to restart the script (see latest 'rest' file created)
restartCommenced='no'
dateToRestartOn='0251-09-20-00000'

# -------------- INFO ABOUT PACEMAKER MASK (note, renaming of dimensions)
# maskFil=/glade/u/home/islas/CVCWG/CESM2_PACEMAKER/SSTINPUT_wedge/ModifiedSST_ERSST_gx1v7.nc
# 0 over ocean, -1 over land, and 1 over pacemaker region
# cp $maskFil /glade/work/sglanvil/CCR/S2S/ENSO_experiments/
# ncrename -d nlon,i -d nlat,j ModifiedSST_ERSST_gx1v7.nc 

maskFil=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/pacemakerOCEANIC/ModifiedSST_ERSST_gx1v7.nc
tmpDir=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/pacemakerOCEANIC/tmp/
finalDir=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/pacemakerOCEANIC/final/
restDir=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/pacemakerOCEANIC/rest/
climoDirBase=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/CLIMOCEANIC/

for climoDir in $climoDirBase/*-00000; do
	rm $tmpDir/*.nc
	date=$(sed -e 's/.*\///' <<< $climoDir)
	realDir=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/OCEANIC/$date/

	# -------------- if the job gets interrupted, this allows you to restart (set dateToRestartOn) while still looping through all the files like normal
        if [[ "$date" != "$dateToRestartOn" ]]; then
                if [[ "$restartCommenced" == 'no' ]]; then
                        continue
                fi
        fi
        restartCommenced='yes'
        echo 'running this date'

	# -------------- note, hopefully there is only ONE pop.r. file in these directories (need to check)
	realFil=`cd $realDir; ls *.pop.r.*`
	climoFil=`cd $climoDir; ls *.pop.r.*`

        echo '------------------------------------------------------------'
	echo $date
	echo $climoDir
	echo $realDir
	echo $climoFil
	echo $realFil
	echo '------------------------------------------------------------'

	# -------------- applying the mask to the real ocean temperatures
	cp $realDir/$realFil $tmpDir/realIn.nc
	ncks -A -v SHF_MASK $maskFil $tmpDir/realIn.nc
	ncap2 -O -s 'TEMP_CUR_MASKED_REAL=TEMP_CUR*SHF_MASK' -s 'TEMP_OLD_MASKED_REAL=TEMP_OLD*SHF_MASK' $tmpDir/realIn.nc $tmpDir/realMasked.nc 

	# -------------- applying the mask to the climo ocean temperatures
	cp $climoDir/$climoFil $tmpDir/climoIn.nc
	ncrename -d i,i0 -d j,j0 $tmpDir/climoIn.nc # correcting dimension issue in Julie Caron's files
	ncrename -d i0,j -d j0,i $tmpDir/climoIn.nc # correcting dimension issue in Julie Caron's files
	ncks -A -v SHF_MASK $maskFil $tmpDir/climoIn.nc
	ncap2 -O -s 'TEMP_CUR_MASKED_CLIMO=TEMP_CUR*(1-SHF_MASK)' -s 'TEMP_OLD_MASKED_CLIMO=TEMP_OLD*(1-SHF_MASK)' $tmpDir/climoIn.nc $tmpDir/climoMasked.nc

	# -------------- adding the climo mask + real mask
	ncks -A -v TEMP_CUR_MASKED_REAL $tmpDir/realMasked.nc $tmpDir/climoMasked.nc
	ncks -A -v TEMP_OLD_MASKED_REAL $tmpDir/realMasked.nc $tmpDir/climoMasked.nc
	ncap2 -O -s 'TEMP_CUR_FINAL=TEMP_CUR_MASKED_CLIMO+TEMP_CUR_MASKED_REAL' -s 'TEMP_OLD_FINAL=TEMP_OLD_MASKED_CLIMO+TEMP_OLD_MASKED_REAL' $tmpDir/climoMasked.nc $finalDir/allvars_g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc

	# -------------- remove and rename variables
	ncks -O -x -v TEMP_CUR,TEMP_OLD,TEMP_CUR_MASKED_CLIMO,TEMP_OLD_MASKED_CLIMO,TEMP_CUR_MASKED_REAL,TEMP_OLD_MASKED_REAL,SHF_MASK $finalDir/allvars_g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc $finalDir/g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc
	ncrename -v TEMP_CUR_FINAL,TEMP_CUR $finalDir/g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc 
	ncrename -v TEMP_OLD_FINAL,TEMP_OLD $finalDir/g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc

	# --------------  move to posledniy directory
	mkdir -p $restDir/${date}/
	cp $finalDir/g210.G_JRA.v14.gx1v7.01.dr.pop.r.${date}.nc $restDir/${date}/
done

