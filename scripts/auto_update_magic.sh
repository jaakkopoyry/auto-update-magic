#!/usr/bin/env bash

###
#
#            Name:  auto_update_magic.sh
#     Description:  A Casper script to assist in automatically updating apps,
#                   meant to be used in conjunction with autopkg, AutoPkgr, and
#                   JSSImporter.
#          Author:  Elliot Jordan <elliot@lindegroup.com>
#         Created:  2013-03-24
#   Last Modified:  2014-12-17
#         Version:  1.3.1
#
###

APPS=(
############################# EDIT BELOW THIS LINE #############################
# Add a line for each auto-updated app. The first part of the line is the name
# of the app itself. The second part of the line is the name of the recipe.
# The first and second parts are separated by a comma. Each line should be
# wrapped in double quotes. Like so:

#          "Firefox, Firefox"
#    "Google Chrome, GoogleChrome"
#            "Skype, Skype"



############################# EDIT ABOVE THIS LINE #############################
    );

# This function checks whether the apps are running, and updates them if not
function fn_AutoUpdateMagic () {
    for APP in "${APPS[@]}"; do
        echo " " # for some visual separation between apps in the log
        PROCESS=$(echo $APP | awk -F',' {'print $1'} | awk '{$1=$1}{ print }')
        RECIPE=$(echo $APP | awk -F',' {'print $2'} | awk '{$1=$1}{ print }')

        if [[ `ps ax | grep -v grep | grep "$PROCESS" | wc -l` -gt 0 ]]; then
            echo "$PROCESS is running. Skipping auto update."
        else
            echo "$PROCESS is not running. Calling policy trigger autoupdate-$RECIPE."
            /usr/sbin/jamf policy -trigger "autoupdate-$RECIPE"
        fi
    done
    /usr/bin/defaults write /Library/"Application Support"/JAMF/com.jamfsoftware.jamfnation LastAutoUpdate $(date +%s)
}

# This function calculates whether it's time to run the auto updates
function fn_AutoUpdateTimeCheck () {
    SECONDS=$((60*60*Hours))
    EPOCH=$(date +%s)
    TIMEDIFF=$((EPOCH-lastAutoUpdateTime))

    if [[ "$TIMEDIFF" -ge "$SECONDS" ]]; then
        fn_AutoUpdateMagic
        exit 0
    else
        if [[ "$TIMEDIFF" -lt "3600" ]]; then
            /bin/echo "Auto updates not needed, last ran $((TIMEDIFF/60)) minutes ago. Will run again in $((Hours*60-TIMEDIFF/60)) minutes."
        else
            /bin/echo "Auto updates not needed, last ran $((TIMEDIFF/60/60)) hours ago. Will run again in $((Hours*60-TIMEDIFF/60)) minutes."
        fi
        exit 0
    fi
}

# Number of hours between auto updates is taken from parameter 4, or defaults to 1
if [[ $4 != "" ]]; then
    Hours=$4
else
    Hours=1
fi
echo "We are checking for auto updates every $Hours hours."

lastAutoUpdateTime=$(/usr/bin/defaults read /Library/"Application Support"/JAMF/com.jamfsoftware.jamfnation LastAutoUpdate 2> /dev/null)
if [[ "$?" -ne "0" ]]; then
    echo "Auto Update Magic has never run before. Checking for updates now..."
    fn_AutoUpdateMagic
    exit 0
else
    fn_AutoUpdateTimeCheck
fi

exit 0