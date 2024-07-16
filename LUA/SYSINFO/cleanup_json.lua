-- -----------------------------------------------------------------------------
--
-- Function to clean up json code with problems that we have observed.
--
-- -----------------------------------------------------------------------------

function cleanup_json( json_in )

    -- Helper function from https://stackoverflow.com/questions/7983574/how-to-write-a-unicode-symbol-in-lua
    function utf8Char (decimal)
        if decimal < 128 then 
            return string.char(decimal)
        elseif decimal < 2048 then 
            local byte2 = (128 + (decimal % 64))
            local byte1 = (192 + math.floor(decimal / 64))
            return string.char(byte1, byte2)
        elseif decimal < 65536 then 
            local byte3 = (128 + (decimal % 64))
            decimal = math.floor(decimal / 64)
            local byte2 = (128 + (decimal % 64))
            local byte1 = (224 + math.floor(decimal / 64))
            return string.char(byte1, byte2, byte3)
        elseif decimal < 1114112 then
            local byte4 = (128 + (decimal % 64))
            decimal = math.floor(decimal / 64)
            local byte3 = (128 + (decimal % 64))
            decimal = math.floor(decimal / 64)
            local byte2 = (128 + (decimal % 64))
            local byte1 = (240 + math.floor(decimal / 64))
            return string.char(byte1, byte2, byte3, byte4)
        else
            return nil  -- Invalid Unicode code point
        end
    end

	local json_out = json_in

    -- Found a \" which is likely confusing in project_465000200 title.
    -- json_out = string.gsub( json_out, '\\"', 'QuOtE' )

    -- Search for UNICODE patterns '\\u%x%x%x%x' and convert to a character.
    local first, last = string.find( json_out, '\\u%x%x%x%x' )
    while first do 
    
        local charnum = tonumber( '0x' .. string.sub( json_out, first+2, last ) )
        json_out = string.gsub( json_out, string.sub( json_out, first, last ), utf8Char( charnum ) )
        -- json_out = string.gsub( json_out, string.sub( json_out, first, last ), 'XXXX' )
        
        first, last = string.find( json_out, '\\u%x%x%x%x' )
    
    end
    
    return json_out


end  -- function cleanup_json

