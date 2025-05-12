#!/usr/bin/bash

BASE_DIRECTORY=`dirname $0`
BASE_DIRECTORY=`realpath $BASE_DIRECTORY/..`
BACKUP_DIRECTORY="$BASE_DIRECTORY/LocalSettings"
LOCAL_FILES=(
  'configuration.bash'
  'Management/localSettings.bash'
  'CamillaDSP/Configuration/camillaconfig.yaml'
)
INDENT='  '
                                                                  # check action
action=$1
if [ -z "$action" ] ; then
  echo "Use \"localSettings.bash backup\" or \"localSettings.bash restore\""
  exit 1
fi
                                                                  # backup files
if [ "$action" = 'backup' ]; then
  echo "Backing-up local settings to \"$BACKUP_DIRECTORY\""
  mkdir -p $BACKUP_DIRECTORY
  for localFile in "${LOCAL_FILES[@]}" ; do
     echo "$INDENT$localFile"
     pathlessFile=`basename $localFile`
     cp $BASE_DIRECTORY/$localFile $BACKUP_DIRECTORY/$pathlessFile
  done
elif [ "$action" = 'restore' ]; then
  echo "Restoring local settings from \"$BACKUP_DIRECTORY\""
  for localFile in "${LOCAL_FILES[@]}" ; do
     echo "$INDENT$localFile"
     pathlessFile=`basename $localFile`
     cp $BACKUP_DIRECTORY/$pathlessFile $BASE_DIRECTORY/$localFile
  done
else
  exit 2
fi
