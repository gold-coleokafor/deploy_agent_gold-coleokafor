# deploy_agent

A shell script that deploys, runs, and archives the logs of the Student Attendance Tracker (`attendance_checker.py`). The Python file is never modified. Everything here is shell scripting around it.

## Repository contents

```
deploy_agent_gold-coleokafor/
├── deploy_agent.sh      # the master script
├── templates/           # unmodified source files
│   ├── attendance_checker.py
│   ├── assets.csv
│   └── config.json
└── README.md
```

## Requirements

- A Linux shell with bash
- `python3` and `zip` (the script checks for both and stops with a clear message if either is missing)

## How to run and select a feature

```bash
chmod +x deploy_agent.sh
./deploy_agent.sh
```

I chose an **interactive menu**. After the script starts, it shows:

```
1. Deploy
2. Run
3. Archive
4. Exit
```

Type 1, 2, 3 or 4. Anything else (including Enter alone) prints `Invalid input!!` and the menu comes back. The menu repeats until you choose 4.

Projects are created in the folder you run the script from. The script finds `templates/` using its own location, so it works from any folder (for example `~/deploy_agent_gold-coleokafor/deploy_agent.sh`).

## Feature 1: Deploy

Deploy runs these steps in order:

1. **Pre-flight checks.** `command -v` confirms `python3` and `zip` exist (output hidden with `>/dev/null 2>&1`). It reports every tool found or missing and exits if any are missing. It then prints the Python version.
2. **Project name.** You are asked for a name. Empty names and names with anything other than letters, numbers, `_` and `-` are rejected, which blocks input such as `a/b` or `../x`. The folder is `attendance_tracker_<name>`.
3. **Existing folder.** If it already exists, you choose overwrite (`o`) or abort (`a`). Anything else is treated as abort, so nothing is deleted by accident. Overwrite removes the old folder and rebuilds it.
4. **Structure.** The script creates the folders and prints success only if `mkdir` worked:

   ```
   attendance_tracker_<name>/
   ├── attendance_checker.py
   ├── Helpers/
   │   ├── assets.csv
   │   └── config.json
   └── reports/
   ```

5. **Fixed files.** `attendance_checker.py` and `config.json` are copied unmodified from `templates/`.
6. **Roster.** You choose how to build `Helpers/assets.csv`. The question repeats until you answer `a` or `b`.
   - **Option A (copy from template):** you enter a number from 1 to 10. The script copies the header plus that many rows (`head -n <N+1>`) from `templates/assets.csv`.
   - **Option B (generate fresh):** you enter a number from 1 to 10. The script writes the header, then builds that many rows from arrays of names and emails defined in the script, with both counts at `0`.
7. **Permissions.** `chmod +x` on `attendance_checker.py` and `chmod 600` on `Helpers/config.json` (owner read/write only, because it holds the grading thresholds). A confirmation is printed for each.
8. **Thresholds** (see below).
9. **Verify.** Deploy ends by running Feature 2, so a successful start proves the structure, roster and config work together.

### Roster size and `total_sessions`

`total_sessions` in `config.json` counts all sessions including today's, so it must be one more than the prior sessions in the roster.

| Roster option | Prior sessions per student | `total_sessions` |
|---|---|---|
| A (copy from template) | 4 | 5 (left as in the template) |
| B (fresh roster) | 0 | 1 (set with `sed`) |

If these disagreed, the app would print a note such as "has 6 prior sessions on record, expected 4". I saw this when I ran the app twice on the same deployment, because each run adds a session to the roster. To get clean results, redeploy with overwrite.

### How the threshold update works

After permissions are set, the script asks `Update attendance alert thresholds? (y/n)`.

- **n:** thresholds stay at the template values (warning 75, failure 50).
- **y:** you are asked for a warning and a failure value. Pressing Enter uses the defaults, 75 and 50.
- **Anything else:** the script keeps the defaults and says so.

Before editing, each value is validated: it must be digits only, between 1 and 100, and warning must be greater than failure. If a check fails, the script prints an error and returns to the menu. The edit uses `sed -i` on only the `"warning": <number>` and `"failure": <number>` lines, so the file is not reformatted or reordered.

## Feature 2: Run

Menu option 2 asks for a project name and checks that `attendance_tracker_<name>` exists. It then runs the app inside a subshell, `( cd <folder> && python3 attendance_checker.py )`, so the script itself stays in its original folder. The app is interactive, so it takes over the terminal while you mark each student present or absent. When it ends, the script reports whether it ran successfully. If the folder does not exist, it prints an error and returns to the menu.

When Deploy calls Run, it passes the project folder in, so you are not asked for the name twice.

## Feature 3: Archive logs

Archiving is a **manual** step: after a marking session, choose menu option 3. This is the archive trigger. The app creates `reports/attendance.log` and `reports/absent.log` when it runs, and archiving saves timestamped copies of them.

1. You are asked for the project name, and the script checks that `attendance_tracker_<name>` exists (error and back to the menu if not).
2. It creates `archives/attendance/` and `archives/absent/` inside the project with `mkdir -p`, and reports an error if that fails.
3. It stores one timestamp, `date +%Y%m%d_%H%M%S`, so both archived files from the same run share it.
4. For each log it checks with `-f` that the file exists. If it does, it copies it into its own directory with the timestamp in the name and prints the final path. If it does not, it says so and carries on without crashing.

```
attendance_tracker_<name>/
└── archives/
    ├── attendance/
    │   └── attendance_20261014_143022.log
    └── absent/
        └── absent_20261014_143022.log
```

If nobody was marked absent, `absent.log` is never created, so the script prints `Unable to find absent.log: nobody was absent` and the attendance log is still archived. The original logs stay in `reports/`, because they are copied, not moved.

## Signal handling: Ctrl+C and Ctrl+Z during Deploy

The trap is set with `trap signal_feature SIGINT SIGTSTP` inside `deploy_feature`. It is armed after the project name has been validated and the overwrite or abort question is settled, and just before the folders are created. That means nothing has been built yet if the user interrupts earlier, so there is nothing to clean up. At the start of Deploy, `project_folder` is cleared, so a handler can never act on a project from an earlier run.

On either signal, the handler `signal_feature`:

1. resets the trap and prints that the deployment was interrupted,
2. skips cleanup if there is no active project folder, or the folder does not exist yet,
3. removes any old `attendance_tracker_<name>_archive.zip`, so the new archive does not mix with an old one,
4. zips the incomplete project into `attendance_tracker_<name>_archive.zip` using `zip -r`,
5. only if the zip succeeded, deletes the incomplete project folder (`rm -rf`) so no half-built directory is left behind. If zipping fails, the folder is kept and the script says so,
6. exits with `exit 1`, which closes the script cleanly (it does not return to the menu).

The trap is switched off with `trap - SIGINT SIGTSTP` on every early `return 1` path and right before the Python app starts. It therefore covers only the script's own setup, not the marking session, where `attendance_checker.py` handles Ctrl+C itself.

### How to test it

1. Run `./deploy_agent.sh` and choose 1.
2. Enter a name such as `sig`, and press **Ctrl+C** at the roster prompt (`Copy from the template (a) or Generate a fresh roster (b)`).
3. Run it again with another name and press **Ctrl+Z** at the same prompt or at the threshold question (`Update attendance alert thresholds?`).
4. Check the results:

   ```bash
   ls                                          # the zip exists, the project folder is gone
   unzip -l attendance_tracker_sig_archive.zip # list what was archived
   ```

### What the `.zip` contains

Whatever had been built when the signal arrived, with paths starting at the project folder:

- Interrupt at the roster prompt: `attendance_checker.py`, `Helpers/config.json`, and an empty `reports/`.
- Interrupt at the threshold prompt: the same, plus `Helpers/assets.csv`.

## How I tested the deployed structure

- `ls -R attendance_tracker_<name>` and a comparison with the required tree.
- `diff templates/config.json attendance_tracker_<name>/Helpers/config.json` and the same for `attendance_checker.py`, to confirm the copies are unmodified (no output means identical).
- `ls -l` to confirm `attendance_checker.py` is executable and `config.json` is `-rw-------`.
- `wc -l Helpers/assets.csv` to confirm the row count is the number requested plus the header.
- `cat Helpers/config.json` to confirm `total_sessions` is 5 for Option A and 1 for Option B, and that the thresholds changed only when I asked.
- Running the app from Deploy and marking a few students to prove the layout works end to end.
- Bad input: empty names, names with spaces or `/`, counts of `0`, `11` and `abc`, bad thresholds, an invalid overwrite answer, and a name that already exists.
- Interrupts: Ctrl+C and Ctrl+Z at several prompts, Ctrl+C at the overwrite prompt and at the menu (no cleanup needed, nothing was built), and Ctrl+C inside the marking session (handled by the app, not by my trap).

## Notes and design choices

- The script validates input before acting on it, and prints success only after the command that did the work has succeeded.
- `rm -rf` only ever runs on a name that was validated and prefixed with `attendance_tracker_`.
- Test projects and zip files are excluded from Git through `.gitignore`.
- Pre-flight uses `exit 1` because without `python3` and `zip` nothing else can work. Failures inside Deploy use `return 1` so the user lands back in the menu. The interrupt handler uses `exit 1` because the assignment says to close the session.
## Video Walkthrough
   [Watch the run-through video](https://youtu.be/A8dJBltSPbI)
   Backup video access: (https://www.loom.com/share/9f1247a9fd194ce0bcb9e7cacfaee3f5) 
