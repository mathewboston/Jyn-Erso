#!/bin/bash

cd $1

#build new index.html
echo -e "Script Output" #> $curdir/out.txt

#only run .sh and ignore self
for script in $(ls | grep -E "*.sh"); do
	if [[ $script != "Watchdog.sh" ]]; then
		echo -e "\n\n----------$script----------\n\n"
		./$script
	fi
done
