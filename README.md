# Davinci Resolve Utilities

A collection of simple automation scripts for DaVinci Resolve Studio.

## 📂 The Scripts

### 1. DCTL Timeline Generator (`dctl_to_text.py` or `dctl_to_text.py`)
Automatically creates a timeline with "Text+" clips for every DCTL file in your library.
* **Scans Subfolders:** Finds all files automatically.
* **Smart Filtering:** Skips "Archive" or "Backup" folders (customizable).
* **Cross-Platform:** Works on Windows and Mac.
---

## 🚀 How to Use

1.  Open **DaVinci Resolve**.
2.  Go to the top menu: **Workspace** > **Console**.
3.  Select **Py3** (Python 3) at the top of the console window or Lua if you do not have Python installed.
4.  Copy the code from the script file (e.g., `dctl_scanner.py` or `dctl_to_text.py`).
5.  Paste it into the console and press **Run**.

> **Note:** For the Lua version, select **Lua** instead of Py3 in the console.
---
## ⚙️ Configuration

Before running the script, open it in a text editor and update the top section:

```python
# 1. PATH TO YOUR FILES
ROOT_FOLDER = r"C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\LUT\RenderHub"

# 2. FOLDERS TO SKIP
FOLDER_BLACKLIST = ["Archive", "Old Versions"]

# 3. FILENAME PATTERNS TO SKIP
FILE_BLACKLIST = ["----", "===="]

