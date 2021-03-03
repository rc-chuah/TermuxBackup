#!/bin/bash
# Created And Scripted by Zongou & RC Chuah-(RaynerSec)
# https://wiki.termux.com/wiki/Backing_up_Termux

# define presets
backupDir="/storage/emulated/0/termux/backups"
termuxRoot="/data/data/com.termux"

# check session mode
function session_mode() {
    session="NULL"
    if command -v termux-info > /dev/null 2>&1; then
        echo "[NORMAL SESSION]"
        session="NORMAL"
    else
        echo "[FAILSAFE SESSION]"
        session="FAILSAFE"
    fi
}

# check storage permission
function checkStoragePermission() {
    if [[ ! -w /storage/emulated/0 ]]; then
        echo "Setting Up Termux Storage..."
        termux-setup-storage
        sleep 5
        echo "Setting Up Termux Storage Completed..."
    fi
}

# check if BackupDir exists
function checkBackupDir() {
    if [[ ! -d $backupDir ]]; then
        echo "backupDir: "
        echo $backupDir
        echo "backupDir does not exists"
        # ask if to create dir
        echo ""
        echo -n "create backupDir? [y/n] "
        read answer
        if [[ "$answer"x = "y"x ]]; then
            echo "creating backupDir..."
            mkdir -p $backupDir
            sleep 5
            echo "creating backupDir completed..."
            if [[ $? -ne 0 ]]; then
                echo "create dir failed!"
                exit 1
            fi
        else
            echo "exiting..." && exit 1
        fi
    fi
}

# Backup Function
function backup() {
    # check if in NORMAL SESSION
    # backup will fail when other linux system is installed, force running in NORMAL SESSION
    if [[ "$session"x = "NORMAL"x ]]; then
        echo "type the file name for backup"
        echo "if empty will use termux.tar.gz"
        echo ""
        echo -n "Enter File Name For Backup: "
        read name
        if [[ -z $name ]]; then
            name="termux.tar.gz"
        fi
        echo "will create "$name
        cleanHistory
        echo "backing system up..."
        cd $termuxRoot/files
        tar -czvf $backupDir/$name ./home ./usr
        if [[ $? -ne 0 ]]; then
            echo "make sure running in termux default environment."
            exit 1
        fi
        echo -e "\033[0;32m backing up finished! \033[0m"
    else
        echo "backup is not supported in [FAILSAFE SESSION], exiting..."
    fi
}

# Restore Function
function restore() {
    # check if backupDir is empty
    if [[ $(ls -l $backupDir | grep "^-" | wc -l) -eq 0 ]]; then
        # empty
        echo "backupDir is empty! exiting..." && exit 1
    else
        echo "Note: make sure no background program running."
        echo "listing backup file..."
        echo ""
        ls $backupDir
    fi
    echo ""
    echo -n "Choose A Backup File: "
    read file
    while [[ ! -f $backupDir/$file ]]
    do
        clear
        echo "no match, try again!"
        sleep 5
        clear
        echo "Note: make sure no background program running."
        echo "listing backup file..."
        echo ""
        ls $backupDir
        echo ""
        echo -n "Choose A Backup File: "
        read file
    done
    echo "start restoring!"
    # use seperated steps is more compatible for lower version of toolbox
    if [[ "$session"x = "FAILSAFE"x ]]; then
        rm -rf $termuxRoot/files/*
        gzip -d -c $backupDir/$file | tar -xvf - -C $termuxRoot/files
    fi
    if [[ "$session"x = "NORMAL"x ]]; then
        cleanAllButKeepCoreFunctions
        tar -xzvf $backupDir/$file -C $termuxRoot/files --recursive-unlink --preserve-permissions
    fi
    echo -e "\033[0;32m restoring finished! \033[0m"
}

# Clean History Function
function cleanHistory() {
    echo "start cleaning"
    termuxBashHistory=$termuxRoot"/files/home/.bash_history"
    if [[ -f $termuxBashHistory ]]; then
        echo "clean termuxBashHistory"
        rm $termuxBashHistory
    fi
    debianBashHistory=$termuxRoot"/files/home/debian-fs/root/.bash_history"
    if [[ -f $debianBashHistory ]]; then
        echo "clean debianBashHistory"
        rm $debianBashHistory
    fi
}

# clean all but keep core functions, get 'rm' alike effect
function cleanAllButKeepCoreFunctions() {
    # clean files dir
    cd $termuxRoot/files
    find * -maxdepth 0 | grep -vw 'usr' | xargs rm -rf
    # clean $PREFIX dir
    cd $termuxRoot/files/usr
    find * -maxdepth 0 | grep -vw '\(bin\|lib\)' | xargs rm -rf
    # clean bin dir
    cd $termuxRoot/files/usr/bin
    find * -maxdepth 0 | grep -vw '\(coreutils\|rm\|xargs\|find\|grep\|tar\|gzip\)' | xargs rm -rf
    # clean lib dir
    cd $termuxRoot/files/usr/lib
    find * -maxdepth 0 | grep -vw '\(libandroid-glob.so\|libtermux-exec.so\|libiconv.so\|libandroid-support.so\|libgmp.so\)' | xargs rm -rf
    # clean none exact utils, aggressively
    cd $termuxRoot/files/usr/bin
    rm coreutils grep xargs find rm ../lib/libgmp.so ../lib/libandroid-support.so

    # dependencies:
    # ls libandroid-support.so libgmp.so
    # rm libgmp.so
    # tar libandroid-glob libtermux-exec.so libiconv.so
}

# Press Enter To Continue Function
function press_enter() {
    echo ""
    echo -n "Press Enter to continue..."
    read
    clear
}

# Incorrect Selection Function
function incorrect_selection() {
    echo "Incorrect selection! Try again."
}

# start
until [[ "$option" = "3" ]]; do
     clear
     checkStoragePermission
     clear
     checkBackupDir
     clear
     session_mode
     echo "This Script Will Backup/Restore Termux"
     echo "Choose To Backup, Restore Or Exit Menu"
     echo "1 To Backup, 2 To Restore, 3 To Exit Menu"
     echo ""
     echo -n "Enter Option: "
     read option
     case $option in
          1 ) clear ; backup ; press_enter ;;
          2 ) clear ; restore ; press_enter ;;
          3 ) clear ; exit ;;
          * ) clear ; incorrect_selection ; press_enter ;;
     esac
done