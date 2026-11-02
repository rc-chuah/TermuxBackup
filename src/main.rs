// termux-backup - Rust rewrite
// Original bash script by Zongou
// Rewritten in Rust by RC Chuah-(RaynerSec)
// SPDX-License-Identifier: GPL-3.0-or-later

use std::fs;
use std::io::{self, BufRead, Write};
use std::path::Path;
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use flate2::Compression;
use tar::Archive;
use tar::Builder;

const BACKUP_DIR: &str = "/storage/emulated/0/termux/backups";
const TERMUX_ROOT: &str = "/data/data/com.termux";

#[derive(Debug, Clone, Copy, PartialEq)]
enum SessionMode {
    Normal,
    Failsafe,
}

fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}

fn run() -> io::Result<()> {
    loop {
        clear_screen();
        check_storage_permission();
        clear_screen();
        check_backup_dir();
        clear_screen();
        let session = session_mode();
        println!("This Program Will Backup/Restore Termux");
        println!("Choose To Backup, Restore Or Exit Menu");
        println!("1 To Backup, 2 To Restore, 3 To Exit Menu");
        println!();
        print!("Enter Option: ");
        io::stdout().flush()?;
        let mut input = String::new();
        io::stdin().lock().read_line(&mut input).unwrap();
        let option = input.trim();
        match option {
            "1" => {
                clear_screen();
                backup(session)?;
                press_enter()?;
            }
            "2" => {
                clear_screen();
                restore(session)?;
                press_enter()?;
            }
            "3" => {
                clear_screen();
                break;
            }
            _ => {
                clear_screen();
                incorrect_selection();
                press_enter()?;
            }
        }
    }
    Ok(())
}

fn clear_screen() {
    print!("\x1B[2J\x1B[1;1H");
    let _ = io::stdout().flush();
}

fn sleep_seconds(seconds: u64) {
    thread::sleep(Duration::from_secs(seconds));
}

fn command_exists(cmd: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg(format!("command -v {}", cmd))
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn session_mode() -> SessionMode {
    if command_exists("termux-info") {
        println!("[NORMAL SESSION]");
        SessionMode::Normal
    } else {
        println!("[FAILSAFE SESSION]");
        SessionMode::Failsafe
    }
}

fn storage_writable() -> bool {
    Command::new("sh")
        .arg("-c")
        .arg("[ -w /storage/emulated/0 ]")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn check_storage_permission() {
    if !storage_writable() {
        println!("Setting Up Termux Storage...");
        let _ = Command::new("termux-setup-storage")
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .status();
        sleep_seconds(5);
        println!("Setting Up Termux Storage Completed...");
        sleep_seconds(5);
    }
}

fn check_backup_dir() {
    let backup_dir = Path::new(BACKUP_DIR);
    if backup_dir.exists() {
        return;
    }
    println!("Backup Directory:");
    println!("{}", BACKUP_DIR);
    println!("Backup Directory Does Not Exists");
    println!();
    print!("Create Backup Directory? [y/n] ");
    let _ = io::stdout().flush();
    let mut answer = String::new();
    io::stdin().lock().read_line(&mut answer).unwrap();
    if answer.trim().eq_ignore_ascii_case("y") {
        println!("Creating Backup Directory...");
        if let Err(e) = fs::create_dir_all(backup_dir) {
            println!("Create Backup Directory Failed! {}", e);
            std::process::exit(1);
        }
        sleep_seconds(5);
        println!("Creating Backup Directory Completed...");
        sleep_seconds(5);
    } else {
        println!("Exiting...");
        std::process::exit(1);
    }
}

fn clean_history() {
    println!("Start Cleaning");
    let termux_history = Path::new(TERMUX_ROOT).join("files/home/.bash_history");
    let debian_history = Path::new(TERMUX_ROOT).join("files/home/debian-fs/root/.bash_history");
    if termux_history.is_file() {
        println!("Clean Termux Bash History");
        let _ = fs::remove_file(&termux_history);
    }
    if debian_history.is_file() {
        println!("Clean Debian Bash History");
        let _ = fs::remove_file(&debian_history);
    }
}

fn backup(session: SessionMode) -> io::Result<()> {
    if session != SessionMode::Normal {
        println!("Backup Is Not Supported In [FAILSAFE SESSION], Exiting...");
        return Ok(());
    }
    println!("Type The File Name For Backup");
    println!("If Empty Will Use termux.tar.gz");
    println!();
    print!("Enter File Name For Backup: ");
    io::stdout().flush()?;
    let mut name = String::new();
    io::stdin().lock().read_line(&mut name).unwrap();
    let name = name.trim();
    let name = if name.is_empty() { "termux.tar.gz" } else { name };
    println!("Will Create {}", name);
    clean_history();
    println!("Backing System Up...");
    sleep_seconds(5);

    let backup_path = Path::new(BACKUP_DIR).join(name);
    let files_dir = Path::new(TERMUX_ROOT).join("files");

    let file = fs::File::create(&backup_path)?;
    let enc = GzEncoder::new(file, Compression::default());
    let mut tar = Builder::new(enc);

    let home_dir = files_dir.join("home");
    let usr_dir = files_dir.join("usr");

    if !home_dir.exists() || !usr_dir.exists() {
        println!("Make Sure Running In Termux Default Environment.");
        std::process::exit(1);
    }

    tar.append_dir_all("home", &home_dir)?;
    tar.append_dir_all("usr", &usr_dir)?;

    let enc = tar.into_inner()?;
    enc.finish()?;

    println!("\x1B[0;32m Backing Up Finished! \x1B[0m");
    Ok(())
}

fn list_backup_files(dir: &Path) {
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            if let Ok(meta) = entry.metadata() {
                if meta.is_file() {
                    if let Some(name) = entry.file_name().to_str() {
                        println!("{}", name);
                    }
                }
            }
        }
    }
}

fn restore(session: SessionMode) -> io::Result<()> {
    let backup_dir = Path::new(BACKUP_DIR);

    let has_files = fs::read_dir(backup_dir)
        .map(|entries| {
            entries
                .filter_map(|e| e.ok())
                .any(|e| e.file_type().map(|ft| ft.is_file()).unwrap_or(false))
        })
        .unwrap_or(false);

    if !has_files {
        println!("Backup Directory Is Empty! Exiting...");
        std::process::exit(1);
    }

    println!("Note: Make Sure No Background Program Running.");
    println!("Listing Backup File...");
    println!();
    list_backup_files(backup_dir);
    println!();
    print!("Choose A Backup File: ");
    io::stdout().flush()?;
    let mut file = String::new();
    io::stdin().lock().read_line(&mut file).unwrap();
    let mut file = file.trim().to_string();

    while !backup_dir.join(&file).is_file() {
        clear_screen();
        println!("No Match, Try Again!");
        sleep_seconds(5);
        clear_screen();
        println!("Note: Make Sure No Background Program Running.");
        println!("Listing Backup File...");
        println!();
        list_backup_files(backup_dir);
        println!();
        print!("Choose A Backup File: ");
        io::stdout().flush()?;
        file.clear();
        io::stdin().lock().read_line(&mut file).unwrap();
        file = file.trim().to_string();
    }

    println!("Start Restoring!");
    sleep_seconds(5);

    let backup_path = backup_dir.join(&file);
    let files_dir = Path::new(TERMUX_ROOT).join("files");

    match session {
        SessionMode::Failsafe => {
            remove_dir_contents(&files_dir)?;
            let file = fs::File::open(&backup_path)?;
            let decoder = GzDecoder::new(file);
            let mut archive = Archive::new(decoder);
            archive.unpack(&files_dir)?;
        }
        SessionMode::Normal => {
            clean_all_but_keep_core_functions()?;
            let status = Command::new("tar")
                .arg("-xzvf")
                .arg(&backup_path)
                .arg("-C")
                .arg(&files_dir)
                .arg("--recursive-unlink")
                .arg("--preserve-permissions")
                .status()?;
            if !status.success() {
                return Err(io::Error::new(io::ErrorKind::Other, "tar restore failed"));
            }
        }
    }

    println!("\x1B[0;32m Restoring Finished! \x1B[0m");
    Ok(())
}

fn remove_path(path: &Path) -> io::Result<()> {
    let meta = fs::symlink_metadata(path)?;
    if meta.is_dir() {
        fs::remove_dir_all(path)
    } else {
        fs::remove_file(path)
    }
}

fn remove_dir_contents(dir: &Path) -> io::Result<()> {
    for entry in fs::read_dir(dir)? {
        remove_path(&entry?.path())?;
    }
    Ok(())
}

fn keep_only(dir: &Path, keep: &[&str]) -> io::Result<()> {
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let name = entry.file_name();
        let name_lossy = name.to_string_lossy();
        if name_lossy.starts_with('.') {
            continue;
        }
        if keep.iter().any(|k| name_lossy == *k) {
            continue;
        }
        remove_path(&entry.path())?;
    }
    Ok(())
}

fn clean_all_but_keep_core_functions() -> io::Result<()> {
    let files_dir = Path::new(TERMUX_ROOT).join("files");
    let usr_dir = files_dir.join("usr");
    let bin_dir = usr_dir.join("bin");
    let lib_dir = usr_dir.join("lib");

    // Clean Files Directory, keep usr
    keep_only(&files_dir, &["usr"])?;
    // Clean $PREFIX Directory, keep bin and lib
    keep_only(&usr_dir, &["bin", "lib"])?;
    // Clean Bin Directory, keep utilities needed for restore
    keep_only(
        &bin_dir,
        &["coreutils", "rm", "xargs", "find", "grep", "tar", "gzip"],
    )?;
    // Clean Lib Directory, keep libraries needed for tar/gzip
    keep_only(
        &lib_dir,
        &[
            "libandroid-glob.so",
            "libtermux-exec.so",
            "libiconv.so",
            "libandroid-support.so",
            "libgmp.so",
        ],
    )?;
    // Remove temporary utilities that are no longer needed
    for name in ["coreutils", "grep", "xargs", "find", "rm"] {
        let _ = fs::remove_file(bin_dir.join(name));
    }
    let _ = fs::remove_file(lib_dir.join("libgmp.so"));
    let _ = fs::remove_file(lib_dir.join("libandroid-support.so"));

    Ok(())
}

fn press_enter() -> io::Result<()> {
    println!();
    print!("Press Enter To Continue...");
    io::stdout().flush()?;
    let mut buf = String::new();
    io::stdin().lock().read_line(&mut buf).unwrap();
    clear_screen();
    Ok(())
}

fn incorrect_selection() {
    println!("Incorrect Selection! Try Again.");
}
