#!/bin/bash
# Created And Scripted by Zongou & RC Chuah-(RaynerSec)
# https://wiki.termux.com/wiki/Backing_up_Termux

# Define Presets
backupDir="/storage/emulated/0/termux/backups"
termuxRoot="/data/data/com.termux"

# Check Session Mode
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

# Check Storage Permission
function CheckStoragePermission() {
    if [[ ! -w /storage/emulated/0 ]]; then
        echo "Setting Up Termux Storage..."
        termux-setup-storage
        sleep 5
        echo "Setting Up Termux Storage Completed..."
        sleep 5
    fi
}

# Check If Backup Directory Exists
function CheckBackupDir() {
    if [[ ! -d $backupDir ]]; then
        echo "Backup Directory: "
        echo $backupDir
        echo "Backup Directory Does Not Exists"
        # Ask If To Create Backup Directory
        echo ""
        echo -n "Create Backup Directory? [y/n] "
        read answer
        if [[ "$answer"x = "y"x ]]; then
            echo "Creating Backup Directory..."
            mkdir -p $backupDir
            sleep 5
            echo "Creating Backup Directory Completed..."
            sleep 5
            if [[ $? -ne 0 ]]; then
                echo "Create Backup Directory Failed!"
                exit 1
            fi
        else
            echo "Exiting..." && exit 1
        fi
    fi
}

# Backup Function
function backup() {
    # Check If In NORMAL SESSION
    # Backup Will Fail When Other Linux System Is Installed, Force Running In NORMAL SESSION
    if [[ "$session"x = "NORMAL"x ]]; then
        echo "Type The File Name For Backup"
        echo "If Empty Will Use termux.tar.gz"
        echo ""
        echo -n "Enter File Name For Backup: "
        read name
        if [[ -z $name ]]; then
            name="termux.tar.gz"
        fi
        echo "Will Create "$name
        CleanHistory
        echo "Backing System Up..."
        sleep 5
        cd $termuxRoot/files
        tar -czvf $backupDir/$name ./home ./usr
        if [[ $? -ne 0 ]]; then
            echo "Make Sure Running In Termux Default Environment."
            exit 1
        fi
        echo -e "\033[0;32m Backing Up Finished! \033[0m"
    else
        echo "Backup Is Not Supported In [FAILSAFE SESSION], Exiting..."
    fi
}

# Restore Function
function restore() {
    # Check If Backup Directory Is Empty
    if [[ $(ls -l $backupDir | grep "^-" | wc -l) -eq 0 ]]; then
        # Empty
        echo "Backup Directory Is Empty! Exiting..." && exit 1
    else
        echo "Note: Make Sure No Background Program Running."
        echo "Listing Backup File..."
        echo ""
        ls $backupDir
    fi
    echo ""
    echo -n "Choose A Backup File: "
    read file
    while [[ ! -f $backupDir/$file ]]
    do
        clear
        echo "No Match, Try Again!"
        sleep 5
        clear
        echo "Note: Make Sure No Background Program Running."
        echo "Listing Backup File..."
        echo ""
        ls $backupDir
        echo ""
        echo -n "Choose A Backup File: "
        read file
    done
    echo "Start Restoring!"
    sleep 5
    # Use Seperated Steps Is More Compatible For Lower Version Of Toolbox
    if [[ "$session"x = "FAILSAFE"x ]]; then
        rm -rf $termuxRoot/files/*
        gzip -d -c $backupDir/$file | tar -xvf - -C $termuxRoot/files
    fi
    if [[ "$session"x = "NORMAL"x ]]; then
        CleanAllButKeepCoreFunctions
        tar -xzvf $backupDir/$file -C $termuxRoot/files --recursive-unlink --preserve-permissions
    fi
    echo -e "\033[0;32m Restoring Finished! \033[0m"
}

# Clean History Function
function CleanHistory() {
    echo "Start Cleaning"
    termuxBashHistory=$termuxRoot"/files/home/.bash_history"
    if [[ -f $termuxBashHistory ]]; then
        echo "Clean Termux Bash History"
        rm $termuxBashHistory
    fi
    debianBashHistory=$termuxRoot"/files/home/debian-fs/root/.bash_history"
    if [[ -f $debianBashHistory ]]; then
        echo "Clean Debian Bash History"
        rm $debianBashHistory
    fi
}

# Clean All But Keep Core Functions, Get 'rm' Alike Effect
function CleanAllButKeepCoreFunctions() {
    # Clean Files Directory
    cd $termuxRoot/files
    find * -maxdepth 0 | grep -vw 'usr' | xargs rm -rf
    # Clean $PREFIX Directory
    cd $termuxRoot/files/usr
    find * -maxdepth 0 | grep -vw '\(bin\|lib\)' | xargs rm -rf
    # Clean Bin Directory
    cd $termuxRoot/files/usr/bin
    find * -maxdepth 0 | grep -vw '\(coreutils\|rm\|xargs\|find\|grep\|tar\|gzip\)' | xargs rm -rf
    # Clean Lib Directory
    cd $termuxRoot/files/usr/lib
    find * -maxdepth 0 | grep -vw '\(libandroid-glob.so\|libtermux-exec.so\|libiconv.so\|libandroid-support.so\|libgmp.so\)' | xargs rm -rf
    # Clean None Exact Utils, Aggressively
    cd $termuxRoot/files/usr/bin
    rm coreutils grep xargs find rm ../lib/libgmp.so ../lib/libandroid-support.so

    # Dependencies:
    # ls libandroid-support.so libgmp.so
    # rm libgmp.so
    # tar libandroid-glob libtermux-exec.so libiconv.so
}

# Press Enter To Continue Function
function press_enter() {
    echo ""
    echo -n "Press Enter To Continue..."
    read
    clear
}

# Incorrect Selection Function
function incorrect_selection() {
    echo "Incorrect Selection! Try Again."
}

# Start
until [[ "$option" = "3" ]]; do
     clear
     CheckStoragePermission
     clear
     CheckBackupDir
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
