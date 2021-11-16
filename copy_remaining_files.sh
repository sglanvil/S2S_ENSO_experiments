#!/bin/bash

restDir=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/pacemakerOCEANIC/rest/
climoDirBase=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/CLIMOCEANIC/

for climoDir in $climoDirBase/*-00000; do
        date=$(sed -e 's/.*\///' <<< $climoDir)
        climoFil=`cd $climoDir; ls *.pop.r.*`

	echo $date

        # --------------  move to posledniy directory
        mkdir -p $restDir/${date}/
	rsync -av $climoDir/* $restDir/${date}/ --exclude=$climoFil
done


