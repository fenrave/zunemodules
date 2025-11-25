--[+[API]+]--------
local process = zune.process
local fs = zune.fs
local path = fs.path
-------------------
type List<key, value> = {
    [key]: value
}


--[+[Directories]+]--
local dir: List<string, string> = {
    main_Dir = "src"
}
--[+[Exclude List]+]--
local exclude_List = {
    "startup.luau",
    ".luaurc",
    -- "main.luau"
}
--[+[Include List]+]--
local include_List = {
    "png",
    "tmj",
    "bmp",
    "mp3",
    "ogg",
    "toml",
    "luaurc"
}

local env_addList: {[string]: string} = { --Used these for testing, use as reference
    -- __GLX_VENDOR_LIBRARY_NAME = "mesa",
    -- sam = "true",
    -- MESA_GL_VERSION_OVERRIDE = "4.6",
    -- MESA_LOADER_DRIVER_OVERRIDE = "zink",
    -- GALLIUM_DRIVER = "zink" 
}

--[+[Configuration]+]--
local rc_Path = fs.realPath(".luaurc")
local zune_toml = fs.realPath("zune.toml")
local flags = "--debug"
local env = process.env
-------------------
local main = "./src/main.luau"

local output_Dir = "./build/main"

local zune_Path = ""..fs.getExePath()

local function GetType(fileName: string): string?
    return string.match(fileName, "%.([^%.]+)$")
end

local function Bundle(): ()
    local comp_Scripts: List<string, string> = {}
    local comp_Files: List<string, string> = {
        ["maintoml"] = zune_toml,
        ["mainrc"] = rc_Path
    }
    local include_Scripts: string = main..""
    local include_Files: string = "-f "

    for Index,Env in pairs(env_addList) do
        env[Index] = Env
    end

    local function recurse(directories: List<string, string>, base_Dir: string)
        for _,directory: string in pairs(directories :: List<string, string>) do
            local files = fs.entries(directory)
            local recurse_Dirs: List<string, string> = {}
            local do_Recurse = false

            for i,f_table in files do
                if GetType(f_table.name) == "luau" then
                    if table.find(exclude_List, f_table.name) then
                        continue
                    end

                    comp_Scripts[tostring(i)..f_table.name] = path.join(directory, f_table.name)
                elseif table.find(include_List, GetType(f_table.name)) then

                    comp_Files[tostring(i)..f_table.name] = path.join(directory, f_table.name)
                elseif f_table.kind == "directory" then
                    recurse_Dirs[f_table.name] = path.join(directory, f_table.name)
                    do_Recurse = true
                end
            end

            if do_Recurse then
                recurse(recurse_Dirs, directory)
            end
            
        end

    end; recurse(dir, "")
    
    for _, fpath in comp_Scripts do
        include_Scripts = include_Scripts.." "..fpath
    end

    for _, fpath in comp_Files do
        include_Files = include_Files.." "..fpath
    end
    
    if not fs.stat("build/") then
        fs.makeDir("./build/")
        fs.createFile("./build/main")
    end

    local result = process.run(
        zune_Path, 
        {
            "bundle",
            include_Scripts,
            include_Files,
            "--out="..output_Dir,
            flags
        },
        {shell = true, stdin = "inherit"} :: ProcessOptions
    )
    print(env)
    local runner = process.run(
        "./build/main",
        {}, 
        {env = env} :: ProcessOptions
    )
    print(runner)
end; Bundle()

process.exit(0)