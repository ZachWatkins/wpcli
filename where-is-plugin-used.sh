# Find where a plugin is active.
plugin_slug="af4-agrilife-unit"

# Non-subjective variables.
email=zachary.watkins@ag.tamu.edu
single_site_installs=(single_1 single_2)
multisite_installs=(multisite_1 multisite_2)
log_filename="urls-for-plugin-$plugin_slug.csv"

# Create log file or empty existing one.
if [ -f $log_filename ]
then
	> $log_filename
else
	touch $log_filename
fi

echo $'Search for $plugin_slug\n' >> $log_filename
echo "install,url,status" >> $log_filename

# Single Site Installs
for install in ${single_site_installs[@]}; do
	echo "Checking $install"
	site_url=$(wp option get siteurl --ssh=$email+$install@$install.ssh.domain.com --skip-plugins --skip-themes)
	return=$(wp plugin is-active $plugin_slug --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins=cas-maestro,gravityformszapier,cets_theme_info,simple-sitemaps,network-username-restrictions-override,multisite-maintenance-mode --skip-themes && echo $?)
	if [ "$return" == "0" ]
	then
		echo "$install,$site_url,active" >> $log_filename
	else
		echo "$install,$site_url,inactive" >> $log_filename
	fi
done

# Multisite Installs
for install in ${multisite_installs[@]}; do
	echo "Checking $install"
	for site_url in $(wp site list --field=url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins --skip-themes)
		echo "Checking $site_url"
		return=$(wp plugin is-active $plugin_slug --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins=cas-maestro,gravityformszapier,cets_theme_info,simple-sitemaps,network-username-restrictions-override,multisite-maintenance-mode --skip-themes && echo $?)
		if [ "$return" == "0" ]
		then
			echo "$install,$site_url,active" >> $log_filename
		else
			echo "$install,$site_url,inactive" >> $log_filename
		fi
	done
done
