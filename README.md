# termux-backup
A Rust program to backup and restore your Termux home and sysroot directories.

## Usage
### How To Use termux-backup

#### Install from crates.io
1. Install using Cargo
   ```bash
   cargo install termux-backup
   ```
2. Run the program:
   ```bash
   termux-backup
   ```

#### Build from source
1. Install dependencies in Termux:
   ```bash
   pkg update -y && pkg install git rust tar gzip -y
   ```
2. Git clone the repository:
   ```bash
   git clone https://github.com/rc-chuah/termux-backup
   ```
   or
   ```bash
   git clone https://github.com/RaynerSec/termux-backup
   ```
3. Change directory:
   ```bash
   cd termux-backup
   ```
4. Build the release binary:
   ```bash
   cargo build --release
   ```
5. Run the program:
   ```bash
   ./target/release/termux-backup
   ```

### Optional: Install to PATH
```bash
cp target/release/termux-backup $PREFIX/bin/termux-backup
chmod +x $PREFIX/bin/termux-backup
termux-backup
```

### Notes
- Backup only works in a normal Termux session.
- Restore works in both normal and failsafe sessions.
- Backups are stored at `/storage/emulated/0/termux/backups`.
- The restore process in a normal session will clean the current Termux environment before restoring, keeping only essential core utilities needed for extraction.

## Star History (Mirror 1)
<a href="https://www.star-history.com/#rc-chuah/termux-backup&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=rc-chuah/termux-backup&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=rc-chuah/termux-backup&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=rc-chuah/termux-backup&type=Date" />
 </picture>
</a>

## Star History (Mirror 2)
<a href="https://www.star-history.com/#RaynerSec/termux-backup&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=RaynerSec/termux-backup&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=RaynerSec/termux-backup&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=RaynerSec/termux-backup&type=Date" />
 </picture>
</a>

## Credits To The Original Creator
Thanks To Zongou
