-- UTIL

-- https://love2d.org/forums/viewtopic.php?p=196465&sid=7893979c5233b13efed2f638e114ce87#p196465
function colliding(x1,y1,w1,h1, x2,y2,w2,h2)
    return (
      x1 < x2+w2 and
      x2 < x1+w1 and
      y1 < y2+h2 and
      y2 < y1+h1
    )
  end
  
  -- https://www.codegrepper.com/code-examples/lua/lua+object+to+string
  function object_to_string(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. object_to_string(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
  end