#!/bin/bash

# Directory where the service files are located
#DIR="./"
DIR="/lib/systemd/system/"

# Define your new paths. Make sure to use single quotes to prevent unwanted variable expansion.
bin_path='/home/wnc/Downloads/open5gs-2.7.6/install/bin'
#bin_path='/usr/bin'
config_path='/home/wnc/Downloads/open5gs-2.7.6/install/etc/open5gs'
#config_path='/etc/open5gs'


# Sometimes using “open5gs” as user|group cause trouble to restart service
NEW_USER="root"
NEW_GROUP="root"


# Use find to get all open5gs-XXX.service files excluding open5gs-webui.service
find "$DIR" -type f -name "open5gs-*.service" ! -name "open5gs-webui.service" | while read -r file; do
    # Replace the specific part of the ExecStart line using sed.
    sed -i "s|ExecStart=.*\(open5gs-.*\) -c .*/|ExecStart=$bin_path/\1 -c $config_path/|g" "$file"
    sed -i "s/^User=.*/User=$NEW_USER/" "$file"
    sed -i "s/^Group=.*/Group=$NEW_GROUP/" "$file"
    echo "Processed $file"
done
