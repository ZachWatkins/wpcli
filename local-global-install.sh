#!/bin/bash

composer global require wp-cli/wp-cli-bundle
echo 'export PATH="~/.composer/vendor/bin:$PATH" >> .bash_profile
echo "Finished. Please close your terminal and reopen it to use the `wp` command globally."
