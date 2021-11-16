#!/bin/bash

climoDirBase=/glade/campaign/cesm/development/cross-wg/S2S/CESM2/CLIMOCEANIC/

restartCommenced='no'
dateToRestartOn='0251-09-20-00000'

for climoDir in $climoDirBase/*-00000; do
        date=$(sed -e 's/.*\///' <<< $climoDir)
	echo $date

	year=${date:0:4}
	month=${date:5:2}
	day=${date:8:2}
	
	if [[ "$date" != "$dateToRestartOn" ]]; then
		if [[ "$restartCommenced" == 'no' ]]; then
			continue
		fi
	fi

	restartCommenced='yes'
	echo 'running'	
done

