# Today's date
today=$(date +"%Y-%m-%d-%I%M%p")
SECONDS=0

# Documentation of required updates.
statuslog="updatesneeded-all-$today.csv"
# Empty file if it exists already.
if [ -f $statuslog ]
then
	> $statuslog
fi

# Documentation of performed updates
updateslog="updatesmade-all-$today.csv"
# Empty file if it exists already.
if [ -f $updateslog ]
then
	> $updateslog
fi

# WP Engine variables
email=zachary.watkins@ag.tamu.edu
priority=(first second third)
staging=(a b c)
installs=( "${priority[@]}" "${staging[@]}" )
for install in ${installs[@]}; do
	echo "$install" >> $statuslog
	echo "Checking $install"

	# Capture SSH output as separate variables
	wpcli_commands="wp option get siteurl; printf \"\&\"; wp db tables wp_site; printf \"\&\"; wp core check-update; printf \"\&\"; wp plugin list --update=available --fields=name,version,update_version --format=csv; printf \"\&\"; wp theme list --update=available --fields=name,version,update_version --format=csv"
	sshoutput=$(ssh $email+$install@$install.ssh.domain.com $wpcli_commands)
	IFS='&'
	array_output=($sshoutput)
	siteurl=${array_output[0]%$'\n'}
	multisite=${array_output[1]%$'\n'}
	core=${array_output[2]%$'\n'}
	plugins=${array_output[3]%$'\n'}
	themes=${array_output[4]%$'\n'}
	header="name,version,update_version"
	printf "multisite: "
	echo $multisite
	printf "core: "
	echo $core
	printf "plugins: "
	echo $plugins
	printf "themes: "
	echo $themes
	unset IFS

	# Return if Up to date needed.
	if [ "$core" = "Success: WordPress is at the latest version." ] && [ "$plugins" = $header ] && [ "$themes" = $header ]; then
		echo ",Up to date" >> $statuslog
		continue
	fi

	# Create the update files if they don't exist.
	if [ ! -f $statuslog ]
	then
    touch $statuslog
    touch $updateslog
	fi

	# Add URLs and bash commands to install entry as instructions for updating it.
	echo ",Make Backup ->,https://domain.com/$install/backup#production" >> $statuslog
	update_commands=",Update Commands ->,echo \"$install updated on \`date +\"%Y-%m-%d-%I%M%p-%Ssec\"\`\" >> $updateslog"
	if [ "$core" != "Success: WordPress is at the latest version." ]; then
		update_commands="$update_commands; wp core update --ssh=$email+$install@$install.ssh.domain.com >> $updateslog"
	fi
	if [ "$plugins" != $header ]; then
		update_commands="${update_commands}; wp plugin update --all --ssh=$email+$install@$install.ssh.domain.com >> $updateslog"
	fi
	if [ "$themes" != $header ]; then
		update_commands="${update_commands}; wp theme update --all --ssh=$email+$install@$install.ssh.domain.com >> $updateslog"
	fi
	# Replace ; at the beginning of update_commands
	update_commands="$update_commands; echo \"\" >> $updateslog"
	update_commands="$update_commands; open $siteurl; open $siteurl/wp-admin/; sleep 10; open https://domain.com/$install/error_logs#production;"
	echo $update_commands >> $statuslog
	# Core
	if [ "$core" != "Success: WordPress is at the latest version." ]
	then
		echo "+ core"
		echo ",Core,$core" >> $statuslog
	else
		echo "- core"
		echo ",Core,Up to date" >> $statuslog
	fi
	echo "" >> $statuslog
	# Plugins
	if [ "$plugins" != $header ]
	then
		echo "+ plugins"
		echo ",Plugin,Version,New Version" >> $statuslog
		for pluginname in $plugins
		do
			if [ "$pluginname" != $header ]
			then
				echo ",$pluginname" >> $statuslog
			fi
		done
	else
		echo "- plugins"
		echo ",Plugins,Up to date" >> $statuslog
	fi
	echo "" >> $statuslog
	# Themes
	if [ "$themes" != $header ]
	then
		echo "+ themes"
		echo ",Theme,Version,New Version" >> $statuslog
		for themename in $themes
		do
			if [ "$themename" != $header ]
			then
				echo ",$themename" >> $statuslog
			fi
		done
	else
		echo "- themes"
		echo ",Themes,Up to date" >> $statuslog
	fi
	echo ""
	echo "" >> $statuslog
done

# Add execution time to beginning of script
duration=$SECONDS
echo ""
echo "Time elapsed: $(($duration / 60)) minutes and $(($duration % 60)) seconds" >> $statuslog
