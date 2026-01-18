-- =========================================================
--  OS DETECTION
-- =========================================================

-- Check directory separator to guess OS
-- Windows uses '\', Mac/Linux uses '/'
local is_windows = package.config:sub(1,1) == "\\"

-- =========================================================
--  CONFIGURATION
-- =========================================================

local root_folder = ""

if is_windows then
    -- WINDOWS PATH (Global)
    root_folder = [[C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\LUT]]
    
    -- Optional: If you use the User folder instead, uncomment the below line:
    -- root_folder = os.getenv("APPDATA") .. [[/Blackmagic Design/DaVinci Resolve/Support/LUT]]
else
    -- MAC PATH (Global)
    root_folder = [[/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT]]
    
    -- Optional: If you use the User folder (~/Library/...), uncomment the below line:
    -- root_folder = os.getenv("HOME") .. [[/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT]]
end

-- 2. File Name Blacklist (Skip specific files)
local file_blacklist = {
    "Exclude", "Backup", "Test", "WIP", "_old", "====", "----"
}

-- 3. Folder Name Blacklist (Skip entire directories)
local folder_blacklist = {
    "Assets", "Archive", "Old Versions"
}

-- =========================================================
--  HELPER FUNCTIONS
-- =========================================================

local resolve = Resolve()
local project = resolve:GetProjectManager():GetCurrentProject()
local timeline = project:GetCurrentTimeline()

if not timeline then
    print("Error: No timeline active. Please create one first.")
    return
end

-- 1. CROSS-PLATFORM SYSTEM COMMAND
--    Wraps io.popen in pcall (Try-Catch)
function get_file_list(path)
    local cmd = ""
    
    if is_windows then
        -- Windows: dir /s /b /a-d (Recursive, Bare format, Files only)
        cmd = 'dir "' .. path .. '" /s /b /a-d'
    else
        -- Mac/Linux: find "path" -type f (Recursive, Files only)
        cmd = 'find "' .. path .. '" -type f'
    end

    print("🛠️ System: " .. (is_windows and "Windows" or "Mac/Linux"))
    print("🛠️ Command: " .. cmd)

    -- pcall (Protected Call) acts as "Try-Catch"
    local success, handle = pcall(io.popen, cmd, 'r')
    
    if not success or not handle then
        return nil, "Failed to execute command."
    end
    
    local content = handle:read("*a")
    handle:close()
    
    if content == "" or content == nil then
        return nil, "No files found or path does not exist."
    end

    return content, nil
end

-- 2. STRING HELPERS
function is_blacklisted(str, blacklist)
    local str_lower = string.lower(str)
    for _, word in ipairs(blacklist) do
        -- Use plain matching (4th arg true) to avoid regex issues
        if string.find(str_lower, string.lower(word), 1, true) then
            return true
        end
    end
    return false
end

function get_filename(path)
    -- Matches both / and \ separators
    return path:match("^.+[\\/](.+)$") or path
end

function add_clip(path)
    local filename = get_filename(path)
    local item = timeline:InsertFusionTitleIntoTimeline("Text+")
    
    if item then
        local comp = item:GetFusionCompByIndex(1)
        if comp then
            local tools = comp:GetToolList(false, "TextPlus")
            if tools and tools[1] then
                tools[1].StyledText = filename
                print("✅ Added: " .. filename)
                return true
            end
        end
    else
        print("❌ Error: Could not create clip for: " .. filename)
    end
    return false
end

-- =========================================================
--  MAIN EXECUTION
-- =========================================================

print("========================================")
print("STARTED: Universal DCTL Scanner")
print("Root: " .. root_folder)
print("========================================")

resolve:OpenPage("edit")

-- 1. Execute Command (Protected)
local output, err = get_file_list(root_folder)

if err then
    print("CRITICAL ERROR: " .. err)
    print("Check if the path exists and is formatted correctly.")
    return
end

local count = 0

-- 2. Parse Output
for full_path in output:gmatch("[^\r\n]+") do
    
    -- Clean whitespace
    full_path = full_path:gsub("^%s*(.-)%s*$", "%1")

    -- Check Extension
    if string.match(full_path, "%.dctl$") or string.match(full_path, "%.dctle$") then
        
        local filename = get_filename(full_path)
        
        if is_blacklisted(full_path, folder_blacklist) then
            -- Blacklisted Folder (Silent skip)
        elseif is_blacklisted(filename, file_blacklist) then
            print("Skipped: " .. filename)
        else
            -- Add to Timeline
            if add_clip(full_path) then
                count = count + 1
            end
        end
    end
end

print("========================================")
print("COMPLETE: Created " .. count .. " clips.")
print("========================================")
