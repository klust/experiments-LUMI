#! /usr/bin/lua

function get_fortune()

    local fortune_file = 'lumi_fortune.txt'

    -- Read the file in a single read statement
    local fp = io.open( fortune_file, 'r' )
    if fp == nil then return nil end
    local fortune = fp:read( '*all' )
    fp:close()

    -- Now split up in the blocks of text and delete leading and
    -- trailing whitespace in each block
    separator = '====='
    local fortune_table = {}
    for str in string.gmatch( fortune, "([^" .. separator .. "]+)" ) do
        str = str:gsub( '^%s*', ''  ):gsub( '%s*$', '' )
        table.insert( fortune_table, str )
    end

    -- Select a text block (based on the time)
    -- Indices in LUA arrays start at 1.
    fortune_number = os.time() % #(fortune_table) + 1

    return fortune_table[fortune_number] .. '\n'

end

function get_motd()

    local motd_file = 'motd.txt'

    -- Read the file in a single read statement
    local fp = io.open( motd_file, 'r' )
    if fp == nil then return nil end
    local motd = fp:read( '*all' )
    fp:close()

    -- Delete trailing white space.
    motd = motd:gsub( '%s*$', '' )

    -- Return nil if we had an empty file and otherwise return the motd
    if  #(motd) == 0 then
        return nil
    else
        return motd
    end

end


print( get_motd() )

print( '\n' ..
       'Did you know...\n' ..
       '❄❄❄❄❄❄❄❄❄❄❄❄❄❄❄' )
print( get_fortune() )

