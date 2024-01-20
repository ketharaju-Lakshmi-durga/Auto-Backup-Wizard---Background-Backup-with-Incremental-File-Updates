#!/bin/bash

mkdir_backup() {

    local directory_var="$1"
 
    if [ ! -d "$directory_var" ]; then

        mkdir -p "$directory_var"
    fi
}

# The purpose of this function is to get the most recent backup number for a specific backup type. It searches for files with names that begin with the designated backup type and finish with ".tar" and only accepts one argument, the backup type. The most recent backup number is then represented by the numeric portion that is extracted from the file name.

fetch_updated_backup_no() {
    local typeof_backup_var="$1"

    local newest_backup_var=$(find "$backup_directory_var/$typeof_backup_var" -type f -name "${typeof_backup_var}*.tar" | sort -n | tail -n 1)
   
    if [ -n "$newest_backup_var" ]; then

        newest_backup_var=$(basename "$newest_backup_var" | grep -oE '[0-9]+')


        echo "$newest_backup_var"
    else
 
        echo "0"
    fi
}

#This function makes sure that every ".txt" file in the /home/durga(home directory) is completely backed up. 

build_complete_backup_func() {

    local ts_var="$(date +"%a %d %b %Y %r %Z")"

    local typeof_backup_var="cb"
  # Obtain the most recent backup number for the "cb" backup type.The most recent backup number is obtained by calling the "fetch_updated_backup_no" function.

    local latest_backupnum_cbtype=$(fetch_updated_backup_no "$typeof_backup_var")

    mkdir_backup "$backup_directory_var/$typeof_backup_var"

    path_textfile_var=$(find "/home/durga" -type f -name "*.txt" 2>/dev/null)
    # Verify whether any.txt files were located.

    if [ -n "$path_textfile_var" ]; then
   

        local cd_num_var=$((latest_backupnum_cbtype + 1))
  
        tar -cf "$backup_directory_var/$typeof_backup_var/${typeof_backup_var}$(printf '%03d' "$cd_num_var").tar" $path_textfile_var 2>/dev/null

        echo "$ts_var ${typeof_backup_var}$(printf '%03d' "$cd_num_var").tar was created" >> "$backupLog_path"
    fi
}

#This feature makes sure that any ".txt" files that have been edited in the last two minutes in the /home/durga (home directory) are incrementally backed up. It generates backup filenames using the convention "ibXXX.tar," where "XXX" is the backup number, maintains track of the backup number for incremental backups, and creates the backup directory if necessary. The function then adds log entries based on the existence of modified ".txt" files, indicating whether or not an incremental backup was created.

build_incremental_bakup_func() {
#Make a timestamp with the following format: "Day dd Month YYYY Time Zone"

    local ts_var="$(date +"%a %d %b %Y %r %Z")"
 
    local typeof_backup_var="ib"
    local latest_ib_number_re=$(fetch_updated_backup_no "$typeof_backup_var")
    mkdir_backup "$backup_directory_var/$typeof_backup_var"

    path_textfile_var=$(find "/home/durga" -type f -name "*.txt" -mmin -2 2>/dev/null)
    #Verify whether any.txt files were located.

    if [ -n "$path_textfile_var" ]; then

        local backupnum_ibtype_var=$((latest_backupnum_ibtype_var + 1))
.

        tar -cf "$backup_directory_var/$typeof_backup_var/${typeof_backup_var}$(printf '%03d' "$backupnum_ibtype_var").tar" $path_textfile_var 2>/dev/null
   # In the backup log file, note the creation of the backup. The name of the backup file that was created and the timestamp are included in the log entry.

        echo "$ts_var ${typeof_backup_var}$(printf '%03d' "$backupnum_ibtype_var").tar was created" >> "$backupLog_path"
    else
 # Add a log entry saying that no changes have been made if there haven't been any.txt files altered in the previous two minutes.

        echo "$ts_var No changes-Incremental backup was not created" >> "$backupLog_path"
    fi
}


sleepTime() {

    sleep 2m
}


backup_directory_var="/home/durga/home/backup"
backupLog_path="$backup_directory_var/backup.log"


mkdir_backup "$backup_directory_var"


mkdir_backup "$backup_directory_var/cb"
# Within the main backup directory, create a new subdirectory called "ib" (incremental backup).

mkdir_backup "$backup_directory_var/ib"



build_complete_backup_func

while true; do

    # Hold off for two minutes.

    sleepTime

    # Verify whether anything has changed in the last eight minutes.

    changesFlag=0
    for i_re in {1..3}; do
        build_incremental_bakup_func
        if [ $? -eq 0 ]; then
            changesFlag=1
        fi
        sleepTime
    done

    # Print "No changes statement for every 2 minutes time interval" if there are no changes within the allotted 8 minutes.

    if [ "$changesFlag" -eq 0 ]; then
        ts_no_changes="$(date +"%a %d %b %Y %r %Z")"
        echo "$ts_no_changes No changes-Incremental backup was not created" >> "$backupLog_path"
    fi

    # After eight minutes, execute the entire backup.

    build_complete_backup_func
done &
