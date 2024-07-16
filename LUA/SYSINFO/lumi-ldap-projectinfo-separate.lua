#! /usr/bin/env lua

local debug = false

local lfs = require('lfs')

local json = require('json')


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
        '\nlumi-ldap-projectinfo: Print information about current quota and allocations\n\n' ..
        'Arguments:\n' ..
        '  -h/--help:              Show this help and quit\n' ..
        '  -p/--project <project>: Show information for the given project or given list of projects\n' ..
        '                          (comma-separated and without spaces)\n' ..
        'Projects can also be specified without using -p.'
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

    local threshold_red =    90
    local threshold_orange = 80
    
    if value >= threshold_red then 
        return string.char(27) .. '[31m', string.char(27) .. '[0m'
    elseif value >= threshold_orange then 
        return string.char(27) .. '[33m', string.char(27) .. '[0m'
    else
        return '', ''
    end

end


-- -----------------------------------------------------------------------------
--
-- Process the command line arguments
--

local argctr = 1
local project_list = {}

while ( argctr <= #arg )
do
    if ( arg[argctr] == '-h' or arg[argctr] == '--help' ) then
        print_help()
        os.exit( 0 )
    elseif ( arg[argctr] == '-p' or arg[argctr] == '--project' ) then
        argctr = argctr + 1
        for _, project in ipairs( arg[argctr]:split( ',' ) ) do
            table.insert( project_list, project )
        end
        if debug then io.stderr:write( 'DEBUG: Found -p/--project argument with value ' .. arg[argctr] .. '\n' ) end
    elseif arg[argctr]:sub(1, 1)  ~=  '-' then
        -- An argument that does not start with a dash: treat as a project list
         for _, project in ipairs( arg[argctr]:split( ',' ) ) do
            table.insert( project_list, project )
        end
        if debug then io.stderr:write( 'DEBUG: Found project argument with value ' .. arg[argctr] .. '\n' ) end        
    else
        io.stderr:write( 'Error: ' .. arg[argctr]  .. ' is an unrecognised argument.\n' )
        os.exit( 1 )
    end
    argctr = argctr + 1
end

local project_path = '/var/lib/project_info'
local first = true

for _,project in ipairs( project_list )
do

    -- print( 'Gathering information for project ' .. project )
    
    local project_postfix = project .. '/' .. project .. '.json'

    local project_file = project_path .. '/users/' .. project_postfix
    -- print( 'Attempting to read information from ' ..project_file )
    local fh = io.open( project_file, 'r' )
    if fh == nil then
        project_file = project_path .. '/lust/' .. project_postfix
        -- print( 'Now attempting to read information from ' project_file )
        fh = io.open( project_file, 'r' )
    end
    if fh == nil then 
        io.stderr:write( 'ERROR: You may not have sufficient rights to get information from project ' .. project .. 
                         ' or the project name is invalid.\n\n' )
        os.exit( 1 )
    end
    local project_info_str = fh:read( '*all' )
    fh:close()
    
    local project_timestamp = lfs.attributes( project_file, 'modification' )

    local project_info = json.decode( project_info_str )
    for key,value in pairs( project_info ) do
        print( 'Key: ' .. key )
    end

    --
    -- Print the header
    --

    if first then
        print()
        first = false
    else
        print( '--------------------------------------------------------------------------------\n' )
    end
    print( 'Information for ' .. project .. '):\n' )
    print( '- Data was last refreshed at ' .. os.date( '%c', project_timestamp ) )
        
    --
    -- Get some general information
    --
    print( '- General information:' )
    print( '  - Title: ' .. (project_info['title'] or 'UNKNOWN') )
    
    if project_info['is_open'] then
        print( '  - Project is active' )
    else
        print( '  - Project is closed ' )
    end

    --
    -- Storage information
    --
    
    if project_info['storage_quotas']['directories'] == nil or project_info['storage_quotas']['directories']['projappl']  == nil then
        print( '- Project is no longer hosted on lumi.' )
    else
	    local project_scratch_dir = lfs.symlinkattributes( '/scratch/' .. project, 'target' )
	    local project_fs
	    if project_scratch_dir == nil then
	        project_fs = UNKNOWN
	    else
		    --
		    -- Determine the location of the project in the file system
		    --
	        _, _, project_fs = string.find( project_scratch_dir, '/pfs/(lustrep%d)/.*' )
	    end
	    print( '- Storage information:' )
	    print( '  - Project hosted on ' .. ( project_fs or 'UNKNOWN' ) )
 
        --
        -- Check disk quotas
        --

	    local use_cached = true
	    local quota = {}
	    
	    local quota_cached = project_info['storage_quotas']['directories']
	    
	    -- Project directory
	    quota['project'] = {}
	    quota['project']['has_dir'] = quota_cached ~= nil and quota_cached ['projappl'] ~=  nil
	    if quota['project']['has_dir'] then
		    quota['project']['block_used'] = quota_cached['projappl']['block_quota_used']
		    quota['project']['block_soft'] = quota_cached['projappl']['block_quota_soft']
		    quota['project']['block_hard'] = quota_cached['projappl']['block_quota_hard']
		    quota['project']['inode_used'] = quota_cached['projappl']['inode_quota_used']
		    quota['project']['inode_soft'] = quota_cached['projappl']['inode_quota_soft']
		    quota['project']['inode_hard'] = quota_cached['projappl']['inode_quota_hard']
	    end
	    
	    -- Scratch directory
	    quota['scratch'] = {}
	    quota['scratch']['has_dir'] = quota_cached ~= nil and quota_cached ['scratch'] ~=  nil
	    if quota['scratch']['has_dir'] then
		    quota['scratch']['block_used'] = quota_cached['scratch']['block_quota_used']
		    quota['scratch']['block_soft'] = quota_cached['scratch']['block_quota_soft']
		    quota['scratch']['block_hard'] = quota_cached['scratch']['block_quota_hard']
		    quota['scratch']['inode_used'] = quota_cached['scratch']['inode_quota_used']
		    quota['scratch']['inode_soft'] = quota_cached['scratch']['inode_quota_soft']
		    quota['scratch']['inode_hard'] = quota_cached['scratch']['inode_quota_hard']
		end
	    
	    -- Flash directory
	    quota['flash'] = {}
	    quota['flash']['has_dir'] = true
	    quota['flash']['has_dir'] = quota_cached ~= nil and quota_cached ['flash'] ~=  nil
	    if quota['flash']['has_dir'] then
		    quota['flash']['block_used'] = quota_cached['flash']['block_quota_used']
		    quota['flash']['block_soft'] = quota_cached['flash']['block_quota_soft']
		    quota['flash']['block_hard'] = quota_cached['flash']['block_quota_hard']
		    quota['flash']['inode_used'] = quota_cached['flash']['inode_quota_used']
		    quota['flash']['inode_soft'] = quota_cached['flash']['inode_quota_soft']
		    quota['flash']['inode_hard'] = quota_cached['flash']['inode_quota_hard']
	    end
	    
	
	    print( '  - Disk quota (cached info):' )
	    
	    local spacer = string.gsub( project, '.', ' ' )
	
	    if quota['project']['has_dir'] then
		    block_perc_used = 100 * quota['project']['block_used'] / quota['project']['block_soft']
		    inode_perc_used = 100 * quota['project']['inode_used'] / quota['project']['inode_soft']
		    local block_colour_on, block_colour_off = colour_thresholds( block_perc_used )
		    local inode_colour_on, inode_colour_off = colour_thresholds( block_perc_used )
		    
		    print( '    - /project/' .. project .. ': ' ..
		           'block quota: '  .. block_colour_on .. string.format( '%5.1f', block_perc_used ) .. '% used (' .. quota['project']['block_used'] .. ' of ' .. quota['project']['block_soft'] .. '/' .. quota['project']['block_hard'] .. ' soft/hard)' .. block_colour_off ..
		           ',\n                 ' .. spacer ..  
		           'file quota:  ' .. inode_colour_on .. string.format( '%5.1f', inode_perc_used ) .. '% used (' .. quota['project']['inode_used'] .. ' of ' .. quota['project']['inode_soft'] .. '/' .. quota['project']['inode_hard'] .. ' soft/hard)' .. block_colour_off )
	    end
	
	    if quota['scratch']['has_dir'] then
		    block_perc_used = 100 * quota['scratch']['block_used'] / quota['scratch']['block_soft']
		    inode_perc_used = 100 * quota['scratch']['inode_used'] / quota['scratch']['inode_soft']
		    local block_colour_on, block_colour_off = colour_thresholds( block_perc_used )
		    local inode_colour_on, inode_colour_off = colour_thresholds( block_perc_used )
		    
		    print( '    - /scratch/' .. project .. ': ' ..
		           'block quota: '  .. block_colour_on .. string.format( '%5.1f', block_perc_used ) .. '% used (' .. quota['scratch']['block_used'] .. ' of ' .. quota['scratch']['block_soft'] .. '/' .. quota['scratch']['block_hard'] .. ' soft/hard)' .. block_colour_off ..
		           ',\n                 ' .. spacer ..  
		           'file quota:  ' .. inode_colour_on .. string.format( '%5.1f', inode_perc_used ) .. '% used (' .. quota['scratch']['inode_used'] .. ' of ' .. quota['scratch']['inode_soft'] .. '/' .. quota['scratch']['inode_hard'] .. ' soft/hard)' .. block_colour_off )
	    end
	
	    if quota['flash']['has_dir'] then
		    block_perc_used = 100 * quota['flash']['block_used'] / quota['flash']['block_soft']
		    inode_perc_used = 100 * quota['flash']['inode_used'] / quota['flash']['inode_soft']
		    local block_colour_on, block_colour_off = colour_thresholds( block_perc_used )
		    local inode_colour_on, inode_colour_off = colour_thresholds( block_perc_used )
		    
		    print( '    - /flash/' .. project .. ':   ' ..
		           'block quota: '  .. block_colour_on .. string.format( '%5.1f', block_perc_used ) .. '% used (' .. quota['flash']['block_used'] .. ' of ' .. quota['flash']['block_soft'] .. '/' .. quota['flash']['block_hard'] .. ' soft/hard)' .. block_colour_off ..
		           ',\n                 ' .. spacer ..  
		           'file quota:  ' .. inode_colour_on .. string.format( '%5.1f', inode_perc_used ) .. '% used (' .. quota['flash']['inode_used'] .. ' of ' .. quota['flash']['inode_soft'] .. '/' .. quota['flash']['inode_hard'] .. ' soft/hard)' .. block_colour_off )
	    end
    
    end

    --
    -- Check the allocation
    --
    
    if project_info['billing']['cpu_hours']['alloc'] == 0 and
       project_info['billing']['gpu_hours']['alloc'] == 0 and
       project_info['billing']['storage_hours']['alloc'] == 0 and
       project_info['billing']['qpu_secs']['alloc'] == 0 then

        print( '- The project has no allocation' )
       
       
    else
        
        print( '- State of the allocation (cached info):' )

	    if project_info['billing']['cpu_hours']['alloc'] > 0 then
	        local alloc = project_info['billing']['cpu_hours']['alloc']
	        local used = project_info['billing']['cpu_hours']['used']
	        local perc_used = 100 * used / alloc
	        local colour_on, colour_off = colour_thresholds( perc_used )
	        print( '  - CPU Khours:      ' .. colour_on .. string.format( '%5.1f', perc_used ) .. '% used (' .. used .. ' of ' .. alloc .. ')' .. colour_off )
	    else
	        print( '  - No CPU hours allocated' )
	    end
	
	    if project_info['billing']['gpu_hours']['alloc'] > 0 then
	        local alloc = project_info['billing']['gpu_hours']['alloc']
	        local used = project_info['billing']['gpu_hours']['used']
	        local perc_used = 100 * used / alloc
	        local colour_on, colour_off = colour_thresholds( perc_used )
	        print( '  - GPU hours:       ' .. colour_on .. string.format( '%5.1f', perc_used ) .. '% used (' .. used .. ' of ' .. alloc .. ')' .. colour_off )
	    else
	        print( '  - No GPU hours allocated' )
	    end
	
	    if project_info['billing']['storage_hours']['alloc'] > 0 then
	        local alloc = project_info['billing']['storage_hours']['alloc']
	        local used = project_info['billing']['storage_hours']['used']
	        local perc_used = 100 * used / alloc
	        local colour_on, colour_off = colour_thresholds( perc_used )
	        print( '  - Storage TBhours: ' .. colour_on .. string.format( '%5.1f', perc_used ) .. '% used (' .. used .. ' of ' .. alloc .. ')' .. colour_off )
	    else
	        print( '  - No storage TBhours allocated' )
	    end
	
	    if project_info['billing']['qpu_secs']['alloc'] > 0 then
	        local alloc = project_info['billing']['qpu_secs']['alloc']
	        local used = project_info['billing']['qpu_secs']['used']
	        local perc_used = 100 * used / alloc
	        local colour_on, colour_off = colour_thresholds( perc_used )
	        print( '  - QPU seconds:     ' .. colour_on .. string.format( '%5.1f', perc_used ) .. '% used (' .. used .. ' of ' .. alloc .. ')' .. colour_off )
	    end
    
    end

    print( )

end
