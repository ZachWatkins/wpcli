# WP Engine Install Name
install=install
# WP Engine User's Email Address
email=email@domain.com
# WordPress User Name
username=organizationauthor
# Define the command to assign the user to each site
wpcli_command="wp user set-role $username editor --url="
# For each site in the install, delete the users in the file and reassign their posts
for url in $( wp site list --field="url" --ssh=$email+$install@$install.ssh.wpengine.net );
do
    sshoutput=$( ssh $email+$install@$install.ssh.wpengine.net $wpcli_command$url )
done
