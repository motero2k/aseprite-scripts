

function TableMapper(array, func)
    local new_array = {}
    for i, v in ipairs(array) do
        new_array[i] = func(v)
    end
    return new_array
end
-- Util for debugging purposes
function serializeTable(val, name, skipnewlines, depth) --https://stackoverflow.com/a/6081639
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else

        tmp = tmp .. "undefinedType["..type(val).."], tostring="..tostring(val)
    end

    return tmp
end

function selectionByPoints(points,scale)
    scale = scale or 1
    app.useTool {
        tool = 'lasso',
        points = TableMapper(points, function(v)
            return Point(v[1]*scale/100, v[2]*scale/100)
        end)
    }
    return app.sprite.selection
end

--- @param sprite {Sprite}
--- @param layerName {string}
--- requires an active sprite with a selected frame
function createLayerBelow(sprite, layerName)
    -- Check if there's an active sprite
    if sprite then
        -- Loop through all layers in the sprite
        for i, layer in ipairs(sprite.layers) do
            -- Check if the layer name matches the desired name
            if layer.name == layerName then
                -- Delete layer if it already exists
                layer.sprite:deleteLayer(layer)
                -- Return the found layer
                return createLayerBelow(sprite, layerName)
            end
        end
        -- Return a new layer if no layer was found
        local index = app.activeLayer.stackIndex
        local newLayer = sprite:newLayer()
        sprite:newCel(newLayer, app.activeFrame, Image(sprite.spec))
        newLayer.name = layerName
        newLayer.stackIndex = index
        return newLayer
    end

    -- Return nil if there's no active sprite
    return nil
end

InverseDirections = {
    right = "left",
    left = "right",
    up = "down",
    down = "up"
}

function MoveMaskWithNegatives(direction, quantity)
    -- Negative values are not supported by the MoveMask command
    if quantity == 0 then
        return
    end
    if quantity < 0 then
        direction = InverseDirections[direction]
        quantity = -quantity
    end
    -- Isometric tiles are drawn in a 2:1 ratio
    -- if IsIsometric and direction == "up" or direction == "down" then
    --     quantity = quantity / 2
    -- end
    app.command.MoveMask {
        target = 'content',
        wrap = false,
        direction = direction,
        units = 'pixel',
        quantity = quantity
    }

end

-- requires an active cel and selection
-- cel.image ----crop selection----> Image with selection size ----> Brush from image
function setActiveBrushImageToCelSelection(cel, selection)

    -- Create a new RECTANGULAR image with no color
    -- Image size is the same as the selection
    local newImage = Image(selection.bounds.width, selection.bounds.height, ColorMode.RGB)

    -- Iterates the new empty image Points 
    for newImgPixel in newImage:pixels() do

        -- the selection can have many shapes like a circle, rectangle, poligon, etc.)
        -- they are encapsulated in a rectangle (the bounds property)
        -- Selection bounding box is not in 0,0 is in bounding.x, bounding.y
        -- This is relative to sprite size.
        local selectionPixel = Point(newImgPixel.x + selection.bounds.x, newImgPixel.y + selection.bounds.y)
        if selection:contains(selectionPixel) then

            -- cel.image dont start at sprites 0,0 but at cel.bounds.x, cel.bounds.y
            -- beacuse only stores the smalles rectangle that contains data, no need to store
            -- a image as big as the sprite if its empty

            -- DISCARDS the pixels in the selection that are outside the cel bounds
            -- getPixel returns a color, if the pixel is outside the cel bounds it returns WHITE, 
            -- we dont want white, we want transparent (non existing pixels)
            if selectionPixel.x > cel.bounds.x and selectionPixel.x < cel.bounds.x + cel.bounds.width and
                selectionPixel.y > cel.bounds.y and selectionPixel.y < cel.bounds.y + cel.bounds.height then
                local coloredPixel =
                    cel.image:getPixel(selectionPixel.x - cel.bounds.x, selectionPixel.y - cel.bounds.y)
                newImage:drawPixel(newImgPixel.x, newImgPixel.y, coloredPixel)
            end
        end

    end

    local brush = Brush {
        type = BrushType.IMAGE,
        blendMode = BlendMode.NORMAL,
        opacity = 255,
        ink = Ink.SIMPLE,
        size = 1,
        -- center = Point(selection.bounds.x / 2, selection.bounds.y / 2),
        image = newImage,
        pattern = BrushPattern.NONE
    }

    app.activeBrush = brush

end

function propagateSelectionIsometric(cel, selection, tile, repetitions)
    local currentBrush = app.activeBrush
    local currentLayer = app.activeLayer
    -- START
    setActiveBrushImageToCelSelection(cel, selection)
    local scriptGeneratedLayer = createLayerBelow(app.sprite, "Tiled-Layer")

    drawTilePropagation(scriptGeneratedLayer, selection, tile, repetitions)
    -- RESET 
    app.activeBrush = currentBrush
    app.activeLayer = currentLayer
end

-- Function to convert isometric coordinates to sprite coordinates
function IsometricToSpriteCoord(sprite, tile, isoX, isoY, isoZ)
    -- xNew  x*0.5*w + y*-0.5*w
    -- yNew  x*0.5*h + y*0.25*h
    local spriteX = isoX * (tile.size.x / 2) - isoY * (tile.size.x / 2)
    local spriteY = isoY * (tile.size.y / 2) + isoX * (tile.size.y / 2)
    if isoZ then
        spriteY = spriteY + isoZ * (tile.size.y / 2) + isoZ * (tile.size.y / 2) -- adds the z axis, z=1 at 00 it's the same as z=0 at 1,1
    end
    -- Center the 0,0 to the spriteCenter
    spriteX = spriteX + sprite.width / 2
    spriteY = spriteY + sprite.height / 2
    return spriteX, spriteY
end

-- Function to draw a point using useTool at the given isometric coordinates
-- Uses the pencil tool with the active brush
--- @param layer {Layer}
--- @param spritePosition {x: number, y: number}
function drawPoint(layer, spritePosition)
    -- This is a placeholder function
    app.useTool {
        tool = 'pencil',
        points = {Point(spritePosition.x, spritePosition.y)},
        layer = layer,
        frame = app.activeFrame
    }
    app.refresh()
end

--- @param layer {Layer}
--- @param selection {Selection}
--- @param tile {size: {x: number, y: number}}
--- @param repetitions {number}
function drawTilePropagation(layer, selection, tile, furdestPoint)
    -- Cant draw outside the mask
    local selec = selection
    app.command.DeselectMask()
    layer.isEditable = true

    app.transaction(function()
        -- Draw z from bottom to top (Z+ -> Z-)  |  but x and y furdest to closer in iso (X- -> X+)(Y- -> Y+)
        for z = furdestPoint, 0, -1 do 
            for x = -furdestPoint , 0 do
                for y = -furdestPoint , 0 do
                    -- Only draw the visible coordinates of the zone
                    if (x ~=0 and y ~=0 and z~=0) then
                        goto continue
                    end
                    -- Skip the origin (user drawing)
                    if (x == 0 and y == 0 and z == 0) then
                        goto continue
                    end

                    local screenPositionX, screenPositionY = IsometricToSpriteCoord(layer.sprite, tile, x, y, z)
                    if (screenPositionY < 0 or screenPositionY > layer.sprite.height) then
                        goto continue
                    end
                    drawPoint(layer, {
                        x = screenPositionX,
                        y = screenPositionY
                    })
                    ::continue::
                end
            end
        end
    end)

    -- Lock the layer
    layer.isEditable = false
end
