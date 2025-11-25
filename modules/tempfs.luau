------------------
local fs = zune.fs
local platform = zune.platform
local process = zune.process
local Case = require("@Case")
local path = fs.path
------------------
local temp_Dir: string = ""
local system_TempDir: string?
local SystemPlatform: string = platform.os
local envQuery = process.env
local envPlatform: string?
------------------
local Symbol = if SystemPlatform == "windows" then "\\" else "/"

-----------------------------------------------------------------
local tempdir_Case = Case("tempdir_Case",
    {
        ["linux"] = "XDG_RUNTIME_DIR",
        ["windows"] = "TMP",
        ["macos"] = "TMPDIR",
        ["freebsd"] = "XDG_RUNTIME_DIR"
    }
)

local function init_Dir(): string
    envPlatform = tempdir_Case(SystemPlatform)

    if not envPlatform then
        error("Unknown platform"..SystemPlatform.."?")
    end

    if envQuery[envPlatform] then
        system_TempDir = envQuery[envPlatform]
    elseif envPlatform == "linux" or envPlatform == "freebsd" then
        system_TempDir = "/var/tmp"
    else
        print("Unknown temp directory location, please assign one manually. Using local directory instead.")
        
        local executable_Path = path.dirname(fs.getExePath())

        if executable_Path then
            system_TempDir = executable_Path
        end
    end

    assert(system_TempDir ~= nil, "Failed to assign path.")

    local processDir: string =  path.join(
        system_TempDir,
        "zunedir",
        tostring(process.pid())
    )

    fs.makeDir(processDir, true)

    return processDir
end; temp_Dir = init_Dir()
-----------------------------------------------------------------
type templib = {
    MakeDirectory: (self: templib, Path: string) -> string
}

local tempfs = {} :: templib

--[==[+]

    @usage

    local = tempfs:MakeDirectory("assets") 

    Adds a folder under the automatically assigned temp directory.
    Returns the path to the folder, which you can use for temp files.

[+]==]--

function tempfs:MakeDirectory(Path: string): string
    local newDir: string = path.join(temp_Dir,Path) do
        fs.makeDir(newDir)
    end

    return newDir
end



--[==[+]

@tempfs

Creates a new directory under your systems temp file directory.
Hopefully this gives you access to a directory held in memory,
although some platforms may use your disk instead.

Linux distros typically uses the directory assigned under XDG_RUNTIME_DIR aka /run/user/xxxx (usually 1000 but the number can be anything)

Alternatively, some platforms don't conform to Freedesktop standards, and may instead use /var/tmp/ or /tmp/, -
- such as the BSDs or user-setup distros like Arch or Gentoo, assuming it isn't automatically assigned with their DE.

Windows always uses %temp% or TMP, as the environment variable, assuming no major change in the future.

MacOS needs further testing.

[+]==]--

return tempfs