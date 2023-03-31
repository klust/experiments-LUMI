#! /usr/bin/env lua

local debug = true

-- -----------------------------------------------------------------------------
--
-- Include code to decode a JSON file
--
-- -----------------------------------------------------------------------------

function json_decode( str )

    local parse

    local function create_set(...)
        local res = {}
        for i = 1, select("#", ...) do
            res[ select(i, ...) ] = true
        end
        return res
    end

    local space_chars   = create_set(" ", "\t", "\r", "\n")
    local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
    local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local literals      = create_set("true", "false", "null")

    local literal_map = {
    [ "true"  ] = true,
    [ "false" ] = false,
    [ "null"  ] = nil,
    }


    local function next_char(str, idx, set, negate)
        for i = idx, #str do
            if set[str:sub(i, i)] ~= negate then
            return i
            end
        end
        return #str + 1
    end


    local function decode_error(str, idx, msg)
        local line_count = 1
        local col_count = 1
        for i = 1, idx - 1 do
            col_count = col_count + 1
            if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
            end
        end
        error( string.format("%s at line %d col %d", msg, line_count, col_count) )
    end


    local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
        local f = math.floor
        if n <= 0x7f then
            return string.char(n)
        elseif n <= 0x7ff then
            return string.char(f(n / 64) + 192, n % 64 + 128)
        elseif n <= 0xffff then
            return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
        elseif n <= 0x10ffff then
            return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                            f(n % 4096 / 64) + 128, n % 64 + 128)
        end -- if
        error( string.format("invalid unicode codepoint '%x'", n) )
    end


    local function parse_unicode_escape(s)
        local n1 = tonumber( s:sub(1, 4),  16 )
        local n2 = tonumber( s:sub(7, 10), 16 )
        -- Surrogate pair?
        if n2 then
            return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
        else
            return codepoint_to_utf8(n1)
        end
    end


    local function parse_string(str, i)
        local res = ""
        local j = i + 1
        local k = j

        while j <= #str do
            local x = str:byte(j)

            if x < 32 then
                decode_error(str, j, "control character in string")

            elseif x == 92 then -- `\`: Escape
                res = res .. str:sub(k, j - 1)
                j = j + 1
                local c = str:sub(j, j)
                if c == "u" then
                    local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                            or str:match("^%x%x%x%x", j + 1)
                            or decode_error(str, j - 1, "invalid unicode escape in string")
                    res = res .. parse_unicode_escape(hex)
                    j = j + #hex
                else
                    if not escape_chars[c] then
                    decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                    end
                    res = res .. escape_char_map_inv[c]
                end
                k = j + 1

            elseif x == 34 then -- `"`: End of string
                res = res .. str:sub(k, j - 1)
                return res, j + 1
            end -- if x < 32 ... elsif ... elsif

            j = j + 1
        end

        decode_error(str, i, "expected closing quote for string")
    end -- function parse_string


    local function parse_number(str, i)
        local x = next_char(str, i, delim_chars)
        local s = str:sub(i, x - 1)
        local n = tonumber(s)
        if not n then
            decode_error(str, i, "invalid number '" .. s .. "'")
        end
        return n, x
    end


    local function parse_literal(str, i)
        local x = next_char(str, i, delim_chars)
        local word = str:sub(i, x - 1)
        if not literals[word] then
            decode_error(str, i, "invalid literal '" .. word .. "'")
        end
        return literal_map[word], x
    end


    local function parse_array(str, i)
        local res = {}
        local n = 1
        i = i + 1
        while 1 do
            local x
            i = next_char(str, i, space_chars, true)
            -- Empty / end of array?
            if str:sub(i, i) == "]" then
            i = i + 1
            break
            end
            -- Read token
            x, i = parse(str, i)
            res[n] = x
            n = n + 1
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "]" then break end
            if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
        end
        return res, i
    end


    local function parse_object(str, i)
        local res = {}
        i = i + 1
        while 1 do
            local key, val
            i = next_char(str, i, space_chars, true)
            -- Empty / end of object?
            if str:sub(i, i) == "}" then
                i = i + 1
                break
            end
            -- Read key
            if str:sub(i, i) ~= '"' then
                decode_error(str, i, "expected string for key")
            end
            key, i = parse(str, i)
            -- Read ':' delimiter
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) ~= ":" then
                decode_error(str, i, "expected ':' after key")
            end
            i = next_char(str, i + 1, space_chars, true)
            -- Read value
            val, i = parse(str, i)
            -- Set
            res[key] = val
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "}" then break end
            if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
        end
        return res, i
    end


    local char_func_map = {
    [ '"' ] = parse_string,
    [ "0" ] = parse_number,
    [ "1" ] = parse_number,
    [ "2" ] = parse_number,
    [ "3" ] = parse_number,
    [ "4" ] = parse_number,
    [ "5" ] = parse_number,
    [ "6" ] = parse_number,
    [ "7" ] = parse_number,
    [ "8" ] = parse_number,
    [ "9" ] = parse_number,
    [ "-" ] = parse_number,
    [ "t" ] = parse_literal,
    [ "f" ] = parse_literal,
    [ "n" ] = parse_literal,
    [ "[" ] = parse_array,
    [ "{" ] = parse_object,
    }


    parse = function(str, idx)
        local chr = str:sub(idx, idx)
        local f = char_func_map[chr]
        if f then
            return f(str, idx)
        end
        decode_error(str, idx, "unexpected character '" .. chr .. "'")
    end

  --
  -- Actual json_decode code
  --

    if type(str) ~= "string" then
        error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res

end  -- function json_decode

-- -----------------------------------------------------------------------------
--
-- End of: Include code to decode a JSON file
--
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
--
-- Helper function: Split a string
--
-- -----------------------------------------------------------------------------

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
 end


-- -----------------------------------------------------------------------------
--
-- Function to print help information.
--
-- -----------------------------------------------------------------------------

function print_help()

    print( 
        '\nlumi-workspaces: Print information about current quota and allocations\n\n' ..
        'Arguments:\n' ..
        '  -h/--help:              Show this help and quit\n' ..
        '  -u/--user <user>:       Show information for the user <user>\n' ..
        '                          This is only useful if you have sufficient rights on the system to check\n' ..
        '                          data from other users as the default is already to list your own data.\n' ..
        '                          Default: Current user ($USER)\n' ..
        '  -p/--project <project>: Show information for the given project or given list of projects\n' ..
        '                          (comma-separated and without spaces)\n' ..
        '                          Default: All projects for the selected user\n' ..
        '  -a/--all                Show information for all projects.\n' ..
        '                          This is only useful if you have sufficient rights on the system to check\n' ..
        '                          data from other users as the default is already to list all your projects.\n'
    )

end



-- -----------------------------------------------------------------------------
--
-- Function to generate the escape codes for printing values that are compared
-- to thresholds. Two values are returned: The escape codes to turn the colour
-- on and off.
--
-- -----------------------------------------------------------------------------

function colour_thresholds( value )

    local threshold_red = 90
    local threshold_orange = 80

    if value >= threshold_red then 
        return '\\u001b[31m', '\\u001b[0m'
    elseif value >= threshold_orange then 
        return '\\u001b[31m', '\\u001b[0m'
    else
        return '', ''
    end

end


-- -----------------------------------------------------------------------------
--
-- Process the command line arguments
--

local argctr = 1
local user_given = nil
local projects_given = nil
local all_projects = false

while ( argctr <= #arg )
do
    if ( arg[argctr] == '-h' or arg[argctr] == '--help' ) then
        print_help()
        os.exit( 0 )
    elseif ( arg[argctr] == '-u' or arg[argctr] == '--user' ) then
        argctr = argctr + 1
        user_given = arg[argctr]
        if debug then io.stderr:write( 'DEBUG: Found -u/--user argument with value ' .. user_given .. '\n' ) end
    elseif ( arg[argctr] == '-p' or arg[argctr] == '--project' ) then
        argctr = argctr + 1
        project_given = arg[argctr]
        if debug then io.stderr:write( 'DEBUG: Found -p/--project argument with value ' .. project_given .. '\n' ) end
        if ( all_projects ) then
            io.stderr:write( 'Error: -p/--project cannot be combined with -a/--all.\n' )
        end
    elseif ( arg[argctr] == '-a' or arg[argctr] == '--all' ) then
        all_projects = true
        if debug then io.stderr:write( 'DEBUG: Found -a/--all\n' ) end
        if ( projects_given ) then
            io.stderr:write( 'Error: -a/--all cannot be combined with -p/--project.\n' )
        end
    end
    argctr = argctr + 1
end

local user_executing = os.getenv( 'USER' )
if debug then io.stderr:write( 'DEBUG: User executing the script: ' .. user_executing .. '\n' ) end

--
-- Determine if the executing user has access to the data in the lust trees
--

-- TODO! Check if the user can read their own data from the LUST tree.

local use_lust_tree = false

--
-- Determine for which user the data should be shown
-- 
local user_requested = nil
if user_given then
    if user_given ~= user_executing and not use_lust_tree then
        io.stderr:write( 'ERROR: You do not have sufficient rights to check information from another user.\n' )
        os.exit( 1 )
    end
    user_requested = user_given
else
    user_requested = user_executing
end

--
-- Determine for which projects the data should be shown
--
-- Decision tree:
--  - Project list given with -p/--project: Show only those projects and produce an error
--    if the data cannot be read in either the project or the lust tree.
--  - -u/--user given and -a/--all given: Show all information about the given user that is
--    accessible by the current user:
--    - User can read from the lust tree: Show all projects of the given user.
--    - User cannot read from the lust tree but is the given user: Use the user/project tree
--    - User can 
--    
--
local project_list = {}
if use_lust_tree
then -- Executing user has the rights to check all projects and users.
    
    if project_given then

        project_list = project_given:split( ',' )
        -- TODO: Get data for the given projects. Check if the project numbers are valid via the lust tree.

    elseif user_given then

        -- TODO: Get the projects of the requested user.

    elseif all_projects then

        -- TODO: Build a list of all projects in the lust tree

    else

        -- Basically a LUSTer asking information about their own projects, so basically the second case:
        -- Get all projects of the requested user.

    end

else -- User with regular privileges

    if project_given then

        project_list = project_given:split( ',' )
        -- TODO: Get data for the given projects. Check if the project numbers are valid via the lust tree.

    else

        -- We can only get here if all projects for the executing user are requested, which we read from the user/project tree.

    end

end

io.stdout:write( 'Hello, world!\n' )

local project_path = '/Users/klust/Projects/LUMI-WS/experiments-LUMI/LUA/SYSINFO/project_info'

for _,project in ipairs( project_list )
do

    print( 'Gathering information for project ' .. project )

    local project_file = project_path .. '/' .. project .. '/' .. project .. '.json'
    local fh = io.open( project_file, 'r' )
    if fh == nil then 
        io.stderr:write( 'ERROR: Could not read the information of project ' .. project .. '\n' )
        exit( 1 )
    end
    local project_info_str = fh:read( '*all' )
    fh:close()

    local project_info = json_decode( project_info_str )

    print( '--------------------------------------------------------------------------------\n' )
    print( 'Information for ' .. project .. ' (' .. project_info['title'] .. '):\n' )

    local project_fs = 'lustrep1'
    print( '- Project and scratch dir on filesystem ' .. project_fs )


    print( '- Current disk quota:' )



    print( '- State of the allocation (cached info):' )

    if project_info['billing']['cpu_hours']['alloc'] > 0 then
        local alloc = project_info['billing']['cpu_hours']['alloc']
        local used = project_info['billing']['cpu_hours']['used']
        local perc_used = 100 * used / alloc
        local colour_on, colour_off = colour_thresholds( perc_used )
        print( '  - CPU Khours: ' .. colour_on .. used .. ' used of ' .. alloc .. ' (' .. string.format( '%.1f', perc_used ) .. '%)' .. colour_off )
    else
        print( '  - No CPU hours allocated' )
    end

    if project_info['billing']['gpu_hours']['alloc'] > 0 then
        local alloc = project_info['billing']['gpu_hours']['alloc']
        local used = project_info['billing']['gpu_hours']['used']
        local perc_used = 100 * used / alloc
        local colour_on, colour_off = colour_thresholds( perc_used )
        print( '  - GPU hours: ' .. colour_on .. used .. ' used of ' .. alloc .. ' (' .. string.format( '%.1f', perc_used ) .. '%)' .. colour_off )
    else
        print( '  - No GPU hours allocated' )
    end

    if project_info['billing']['storage_hours']['alloc'] > 0 then
        local alloc = project_info['billing']['storage_hours']['alloc']
        local used = project_info['billing']['storage_hours']['used']
        local perc_used = 100 * used / alloc
        local colour_on, colour_off = colour_thresholds( perc_used )
        print( '  - Storage TBhours: ' .. colour_on .. used .. ' used of ' .. alloc .. ' (' .. string.format( '%.1f', perc_used ) .. '%)' .. colour_off )
    else
        print( '  - No storage TBhours allocated' )
    end

    if project_info['billing']['qpu_secs']['alloc'] > 0 then
        local alloc = project_info['billing']['qpu_secs']['alloc']
        local used = project_info['billing']['qpu_secs']['used']
        local perc_used = 100 * used / alloc
        local colour_on, colour_off = colour_thresholds( perc_used )
        print( '  - QPU seconds: ' .. colour_on .. used .. ' used of ' .. alloc .. ' (' .. string.format( '%.1f', perc_used ) .. '%)' .. colour_off )
    end

    print( '- Cached info was gathered at TODO' )


end
