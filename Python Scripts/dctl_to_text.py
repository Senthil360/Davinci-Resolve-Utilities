import os
import sys
import platform

# =========================================================
#  OS DETECTION & CONFIGURATION
# =========================================================

# Detect OS
CURRENT_OS = platform.system() # 'Windows', 'Darwin' (Mac), or 'Linux'

# 1. Define Root Folder based on OS
if CURRENT_OS == "Windows":
    # Windows Global Path
    ROOT_FOLDER = r"C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\LUT"
elif CURRENT_OS == "Darwin":
    # Mac Global Path
    ROOT_FOLDER = r"/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT"
    # Alternative User Path (uncomment if needed):
    # ROOT_FOLDER = os.path.expanduser("~/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT")
else:
    # Linux Global Path (Standard)
    ROOT_FOLDER = r"/var/BlackmagicDesign/DaVinci Resolve/Support/LUT"

# 2. File Name Blacklist (Skip specific files)
FILE_BLACKLIST = [
    "Exclude", "Backup", "Test", "WIP", "_old", "====", '----'
]

# 3. Folder Name Blacklist (Skip entire directories)
FOLDER_BLACKLIST = [
    "Assets", "Archive", "Old Versions"
]

# =========================================================
#  API SETUP
# =========================================================

try:
    resolve = app.GetResolve()
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
except:
    print("Error: Please run this from the DaVinci Resolve Console.")
    sys.exit()

if not timeline:
    print("Error: No timeline active. Please create one first.")
    sys.exit()

# =========================================================
#  HELPER FUNCTIONS
# =========================================================

def is_blacklisted(name, blacklist):
    """Checks if name contains any blacklisted word (Case Insensitive)."""
    name_lower = name.lower()
    for word in blacklist:
        if word.lower() in name_lower:
            return True
    return False

def add_clip(filename):
    """Adds a Text+ clip and renames it to the filename."""
    item = timeline.InsertFusionTitleIntoTimeline("Text+")
    
    if item:
        # Access the Fusion Comp to set the label reliably
        comp = item.GetFusionCompByIndex(1)
        if comp:
            tools = comp.GetToolList(False, "TextPlus")
            if tools:
                # Tools are usually 1-indexed in the wrapper, but Python dicts vary.
                # safely get the first tool found
                tool = tools[1] if 1 in tools else list(tools.values())[0]
                
                tool.SetInput("StyledText", filename)
                print(f"✅ Added: {filename}")
                return True
    
    print(f"Failed to add clip for: {filename}")
    return False

# =========================================================
#  MAIN EXECUTION
# =========================================================

def run_scanner():
    print("========================================")
    print(f"STARTED: Universal DCTL Scanner (Python)")
    print(f"OS: {CURRENT_OS}")
    print(f"Root: {ROOT_FOLDER}")
    print("========================================")

    if not os.path.exists(ROOT_FOLDER):
        print(f"Error: The path does not exist on this system.")
        print(f"Path checked: {ROOT_FOLDER}")
        return

    resolve.OpenPage("edit")
    count = 0

    # os.walk is native and recursive
    for root, dirs, files in os.walk(ROOT_FOLDER, topdown=True):
        
        # 1. FILTER FOLDERS (In-place modification)
        # We iterate backwards to remove blacklisted folders safely
        for i in range(len(dirs) - 1, -1, -1):
            dir_name = dirs[i]
            if is_blacklisted(dir_name, FOLDER_BLACKLIST):
                # Using 'del' prevents os.walk from entering this folder
                del dirs[i] 

        # 2. PROCESS FILES
        for filename in files:
            if filename.lower().endswith(('.dctl', '.dctle')):
                
                if is_blacklisted(filename, FILE_BLACKLIST):
                    print(f"Skipped File: {filename}")
                else:
                    if add_clip(filename):
                        count += 1

    print("========================================")
    print(f"COMPLETE: Created {count} clips.")
    print("========================================")

run_scanner()
