# Bob Task-Session Reports Export

This folder contains all Bob task-session reports and logs exported on 2026-05-04.

## Contents

### 1. bobide_logs/
Contains Bob IDE logs from `/home/ubuntu/.bobide/logs`:
- Daily log files (bob-code-YYYY-MM-DD.log)
- Daily error logs (bob-code-YYYY-MM-DD.error.log)
- Audit JSON files

**Date Range:** May 1-4, 2026

### 2. bob_tmp_sessions/
Contains Bob session data from `/home/ubuntu/.bob/tmp`:
- Session JSON files with chat histories
- logs.json files with session metadata
- Binary utilities (rg - ripgrep)

**Sessions Found:**
- session-2026-05-01T13-32-2818b75f.json

## File Structure

```
bob_sessions/
├── README.md (this file)
├── bobide_logs/
│   ├── bob-code-2026-05-01.log
│   ├── bob-code-2026-05-01.error.log
│   ├── bob-code-2026-05-02.log
│   ├── bob-code-2026-05-02.error.log
│   ├── bob-code-2026-05-03.log
│   ├── bob-code-2026-05-03.error.log
│   ├── bob-code-2026-05-04.log
│   ├── bob-code-2026-05-04.error.log
│   └── audit JSON files
└── bob_tmp_sessions/
    ├── [hash]/logs.json
    ├── [hash]/chats/session-*.json
    └── bin/rg

```

## Log File Sizes
- May 1: ~5.5 KB
- May 2: ~500 KB (largest)
- May 3: ~120 KB
- May 4: ~4.5 KB

## Notes
- All files are copied from the original locations
- Original files remain intact in their source directories
- Session files contain complete chat histories and task details
- Log files contain detailed execution traces and error information