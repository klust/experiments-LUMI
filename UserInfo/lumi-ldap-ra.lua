#! /usr/bin/env lua

local debug = false

local lfs = require('lfs')

-- -----------------------------------------------------------------------------
--
-- Include code to decode a JSON file
--
-- -----------------------------------------------------------------------------

function json_decode( str )

	local escape_char_map = {
	    [ "\\" ] = "\\",
	    [ "\"" ] = "\"",
	    [ "\b" ] = "b",
	    [ "\f" ] = "f",
	    [ "\n" ] = "n",
	    [ "\r" ] = "r",
	    [ "\t" ] = "t",
	}
	
	local escape_char_map_inv = { [ "/" ] = "/" }
	for k, v in pairs(escape_char_map) do
	    escape_char_map_inv[v] = k
	end

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
-- Helper function: Check if a node has the proper data
--
-- -----------------------------------------------------------------------------

function check_ldap_info()

    require( 'lfs' )
    
    return ( lfs.attributes( '/var/lib/project_info', 'mode' ) == 'directory' )

 end


-- -----------------------------------------------------------------------------
--
-- Function to print help information.
--
-- -----------------------------------------------------------------------------

function print_help()

    print( 
        '\nlumi-ldap-ra: List information on projects for which the VSC is the allocator.\n\n' ..
        'Arguments:\n' ..
        '  -h/--help:          Show this help and quit\n' ..
        '  -c/--comma:         Use a comma as the decimal separator when printing numbers\n' ..
        '  -m/--markdown:      Format output in markdown / user-readable text\n' ..
        '  --multimarkdown:    Format for the multimarkdown variant of markdown (better table syntax)\n' ..
        '  --csv:              Format output in CSV format (separator ;\n' ..
        '  --ra-vsc:           List VSC projects\n' .. 
        '  --ra-ceci:          List CÉCI projects\n'
    )

end


-- -----------------------------------------------------------------------------
--
-- Helper function: CSV formatter
--
-- -----------------------------------------------------------------------------


function format_CSV( project_selected, project_data, use_locale )

    local io_device = io.stdout
    
    local store_locale = os.setlocale()
    os.setlocale( use_locale )
    
    io_device:write( 'Title;;CPU kHours;;;GPU kHours;;;Storage TiBhours;\n' )
    io_device:write( ';Used;Allocated;% used;Used;Allocated;% used;Used;Allocated;% Used\n' )

    for _,project in ipairs( project_selected )
    do

        project_info = project_data[project]

        local cpu_alloc = project_info['billing']['cpu_hours']['alloc'] / 1000
        local cpu_used = project_info['billing']['cpu_hours']['used'] / 1000
        local cpu_perc_used
        if cpu_alloc > 0 then
	        cpu_perc_used = 100 * cpu_used / cpu_alloc
	    else
	        cpu_perc_used = '""'
	    end
	
        local gpu_alloc = project_info['billing']['gpu_hours']['alloc'] / 1000
        local gpu_used = project_info['billing']['gpu_hours']['used'] / 1000
        local gpu_perc_used
        if gpu_alloc > 0 then
	        gpu_perc_used = 100 * gpu_used / gpu_alloc
	    else
	        gpu_perc_used = '""'
	    end

        local storage_alloc = project_info['billing']['storage_hours']['alloc']
        local storage_used = project_info['billing']['storage_hours']['used']
        local storage_perc_used
        if storage_alloc > 0 then
	        storage_perc_used = 100 * storage_used / storage_alloc
	    else
	        storage_perc_used = '""'
	    end

        
        io_device:write( (project_info['title'] or 'UNKNOWN') .. ';' ..
                         cpu_used .. ';' .. cpu_alloc .. ';' .. cpu_perc_used .. ';' .. 
                         gpu_used .. ';' .. gpu_alloc .. ';' .. gpu_perc_used .. ';' .. 
                         storage_used .. ';' .. storage_alloc .. ';' .. storage_perc_used .. '\n' )

    end
    
    os.setlocale( store_locale )
    
end -- of function format_CSV


-- -----------------------------------------------------------------------------
--
-- Helper function: multimarkdown formatter
--
-- -----------------------------------------------------------------------------


function format_md( project_selected, project_data, use_locale, use_multimarkdown )

    local io_device = io.stdout


    -- 
    -- Determine the length of the longest project title for beautiful output
    --


    local title_size = 7
    for _,project in ipairs( project_selected )
    do
        local len = string.len( (project_data[project]['title'] or 'UNKNOWN') )
        if len > title_size then title_size = len end
    end
    if title_size > 99 then title_size = 99 end -- Looks like string.format can handle at most %-99s and not longer...

    --
    -- Print the header
    --

    local title_format = '%-' .. title_size .. 's'
    local title_line = '----------'
    while string.len( title_line ) < title_size do title_line = title_line .. '----------' end
    title_line = string.sub( title_line, 1, title_size )

    local store_locale = os.setlocale()
    os.setlocale( use_locale )
    
    if use_multimarkdown then
        io_device:write( '| ' .. string.format( title_format, 'Title' ) .. ' | ' .. 
                         string.format( '%-35s', 'CPU kHours' ) .. '     ||| ' ..
                         string.format( '%-35s', 'GPU kHours' ) .. '     ||| ' ..
                         string.format( '%-39s', 'Storage TiBHours' ) .. '     |||\n' )
        io_device:write( '| ' .. string.format( title_format, ' ' ) .. ' | ' .. 
                         '         used |     allocated |    % used | ' ..
                         '         used |     allocated |    % used | ' ..
                         '          used |      allocated |      % used |\n' )
    else
        io_device:write( '| ' .. string.format( title_format, 'Title' ) .. ' | ' .. 
                         '     CPU used |     CPU alloc | %CPU used | ' ..
                         '     GPU used |     GPU alloc | %GPU used | ' ..
                         '      TiB used |      TiB alloc |   %TiB used |\n' )
    end
    io_device:write( '|:' .. string.format( title_format, title_line ) .. '-|-' ..
                     '-------------:|--------------:|----------:|-' ..
                     '-------------:|--------------:|----------:|-' ..
                     '--------------:|---------------:|------------:|\n' )
    
    --
    -- Now print the data for projects
    --
    
    for _,project in ipairs( project_selected )
    do


        project_info = project_data[project]

        local cpu_alloc = project_info['billing']['cpu_hours']['alloc'] / 1000
        local cpu_used = project_info['billing']['cpu_hours']['used'] / 1000
        local cpu_perc_used_str
        if cpu_alloc > 0 then
	        cpu_perc_used_str = string.format( '%7.2f %%', 100 * cpu_used / cpu_alloc )
	    else
	        cpu_perc_used_str = '         '
	    end
	
        local gpu_alloc = project_info['billing']['gpu_hours']['alloc'] / 1000
        local gpu_used = project_info['billing']['gpu_hours']['used'] / 1000
        local gpu_perc_used_str
        if gpu_alloc > 0 then
	        gpu_perc_used_str = string.format( '%7.2f %%', 100 * gpu_used / gpu_alloc )
	    else
	        gpu_perc_used_str = '         '
	    end

        local storage_alloc = project_info['billing']['storage_hours']['alloc']
        local storage_used = project_info['billing']['storage_hours']['used']
        local storage_perc_used_str
        if storage_alloc > 0 then
	        storage_perc_used_str = string.format( '%9.2f %%', 100 * storage_used / storage_alloc )
	    else
	        storage_perc_used_str = '           '
	    end

        local title = (project_info['title'] or 'UNKNOWN' )

        io_device:write( '| ' .. string.format( title_format, title ) .. ' | ' .. 
                         string.format( '%10.3f kH', cpu_used ) .. ' | ' .. string.format( '%10.3f kH', cpu_alloc ) .. ' | ' .. cpu_perc_used_str .. ' | ' ..
                         string.format( '%10.3f kH', gpu_used ) .. ' | ' .. string.format( '%10.3f kH', gpu_alloc ) .. ' | ' .. gpu_perc_used_str .. ' | ' ..
                         string.format( '%9.0f TiBH', storage_used ) .. ' | ' .. string.format( '%9.0f TiBH', gpu_alloc ) .. ' | ' .. storage_perc_used_str .. ' |\n' )


    end    

    os.setlocale( store_locale )
    
end -- function format_mmd

-- -----------------------------------------------------------------------------
--
-- Main code
--


--
-- Initialisations
--

-- Place on LUMI where the project information is stored.
local project_path = '/var/lib/project_info'

--
-- Check: Can we run the script on this node?
--

if not check_ldap_info() then

    io.stderr:write( 'Error: This node does not provide the LDAP information needed.\n\n' )
    os.exit( 1 )

end

-- -----------------------------------------------------------------------------
--
-- Process the command line arguments
--

local argctr = 1

local use_locale = 'en_US.utf8'
local format = 'CSV'
local search_expressions = {}

while ( argctr <= #arg )
do
    if ( arg[argctr] == '-h' or arg[argctr] == '--help' ) then
        print_help()
        os.exit( 0 )
    elseif ( arg[argctr] == '-c' or arg[argctr] == '--comma' ) then
        use_locale = 'nl_BE.utf8'
    elseif ( arg[argctr] == '--csv' ) then
        format = 'CSV'
    elseif ( arg[argctr] == '-m' or arg[argctr] == '--markdown' ) then
        format = 'md'
    elseif ( arg[argctr] == '--multimarkdown' ) then
        format = 'mmd'
    elseif ( arg[argctr] == '--ra-vsc' ) then
        table.insert( search_expressions, 'VLAAMS SUPERCOMPUTER CENTRUM' )
    elseif ( arg[argctr] == '--ra-ceci' ) then
        table.insert( search_expressions, 'Consortium des Équipements de Calcul Intensif' )
     else
        io.stderr:write( 'Error: ' .. arg[argctr]  .. ' is an unrecognised argument.\n' )
        print_help()
        os.exit( 1 )
    end
    argctr = argctr + 1
end

-- -----------------------------------------------------------------------------
--
-- Get the list of projects known to LUMI
--

local project_list = {}

local cmd

local cmd = "/usr/bin/ls -1 " .. project_path .. "/lust |& " ..
            "grep -v 'Permission denied'"

fh = io.popen( cmd, 'r')
for line in fh:lines() do 
    table.insert( project_list, line )
    if debug then io.stderr:write( 'DEBUG: Adding ' .. line .. ' to the project list.\n' ) end
end
fh:close()

if ( #project_list == 0 ) then

    io.stderr:write( 'No projects found. You may not have enough privileges to list all projects.\n\n' )

end

table.sort( project_list )

-- -----------------------------------------------------------------------------
--
-- Gather  and print information about all projects that should be listed.
--

local project_selected = {}
local project_data = {}

for _,project in ipairs( project_list )
do

    if debug then io.stderr:write( 'Gathering information for project ' .. project .. '\n' ) end
    
    local project_postfix = project .. '/' .. project .. '.json'

    -- Open the LUST version of the data.
    local project_file = project_path .. '/lust/' .. project_postfix
    if debug then io.stderr:write( 'Attempting to read information from ' ..  project_file .. '\n' ) end
    local fh = io.open( project_file, 'r' )
    if fh == nil then 
        io.stderr:write( 'ERROR: You may not have sufficient rights to get information from the projects and to run this command.\n\n' )
        os.exit( 1 )
    end
    local project_info_str = fh:read( '*all' )
    fh:close()
    
    local project_info = json_decode( project_info_str )
    
    -- Check if the project should be included in the list
    
    local match = false
    if #search_expressions == 0 then
    
        match = true

    else
    
        local work_title = (project_info['title'] or 'UNKNOWN')
        
        for _,search_expression in ipairs( search_expressions ) do
            if string.find( work_title, search_expression ) then
                match = true
            end
        end
        
    end
    
    if match then
    
        if debug then io.stderr:write( 'Selecting ' .. project .. ': ' .. (project_info['title'] or 'UNKNOWN') .. '\n' ) end
        
        table.insert( project_selected, project )
        project_data[project] = project_info
        
    end

end

-- -----------------------------------------------------------------------------
--
-- Call the desired formatter.
--

if ( format == 'CSV' ) then
    format_CSV( project_selected, project_data, use_locale )
elseif ( format == 'md' ) then
    format_md( project_selected, project_data, use_locale, false )
elseif ( format == 'mmd' ) then
    format_md( project_selected, project_data, use_locale, true )
else
    io.stderr:write( 'Internal error: Unrecognized format ' .. format .. '.\n' )
end
