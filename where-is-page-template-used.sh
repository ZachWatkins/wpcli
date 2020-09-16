# Find where a page template is used that is provided by a theme.
template_owner_theme="agriflex4"
page_template_slug="service-landing-page"

# Non-subjective variables.
email=zachary.watkins@ag.tamu.edu
page_template_filename="$page_template_slug.php"
post_edit_screen_url="wp-admin/post.php?action=edit&post="
single_site_installs=(single_1 single_2)
multisite_installs=(multisite_1 multisite_2)
log_filename="urls-for-template-$page_template_slug.csv"

# Create log file or empty existing one.
if [ -f $log_filename ]
then
	> $log_filename
else
	touch $log_filename
fi

# Single Site Installs.
echo "Checking single site installs"
for install in ${single_site_installs[@]}; do
	echo "Checking $install"
	site_url=$(wp option get siteurl --ssh=$email+$install@$install.ssh.domain.com --skip-plugins --skip-themes)
	active_theme=$(wp theme list --status=active --field=name --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins)
	if [ "$active_theme" == "$template_owner_theme" ]
	then
		echo "$site_url uses $template_owner_theme theme"
		# Get posts using this page template.
		posts=$(wp post list --post_type=page --meta_key="_wp_page_template" --meta_value=$page_template_filename --field=ID --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins=cas-maestro,cets_theme_info,simple-sitemaps,network-username-restrictions-override,multisite-maintenance-mode --skip-themes)
		# Output page edit URLs to text file.
		for postid in $posts
		do
			echo "$site_url$post_edit_screen_url$postid"
			echo "$site_url$post_edit_screen_url$postid" >> $log_filename
		done
	else
		echo "$site_url does not use $template_owner_theme theme"
	fi
done

# Multisite Installs.
for install in ${multisite_installs[@]}; do
	echo "Checking $install"
	for site_url in $(wp site list --field=url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins --skip-themes)
	do
		active_theme=$(wp theme list --status=active --field=name --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins)
		if [ "$active_theme" == "$template_owner_theme" ]
		then
			echo "$site_url uses $template_owner_theme theme"
			posts=$(wp post list --post_type=page --meta_key="_wp_page_template" --meta_value=$page_template_filename --field=ID --url=$site_url --ssh=$email+$install@$install.ssh.domain.com --skip-plugins=cas-maestro,cets_theme_info,simple-sitemaps,network-username-restrictions-override,multisite-maintenance-mode --skip-themes)
			for postid in $posts
			do
				echo "$site_url$post_edit_screen_url$postid"
				echo "$site_url$post_edit_screen_url$postid" >> $log_filename
			done
		else
			echo "$site_url does not use $template_owner_theme theme"
		fi
	done
done
