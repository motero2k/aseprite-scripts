dofile("./.utils.lua")



-- Function to handle button click event
function onButtonClick()
    -- Get cartesian coordinates from the input field
    local tile = {size = {x = dlg.data.tileSizeX, y = dlg.data.tileSizeY}}
    local isoX, isoY, isoZ = dlg.data.inputX, dlg.data.inputY, dlg.data.inputZ

    
    -- Check active cel
    local cel = app.activeCel
    if not cel then
        app.alert("There is no active cel, please select a cel (cel = layer-frame in a sprite)")
        return
    end
    -- Check active layer (redundant)
    local layer = app.activeLayer
    if not layer then
        app.alert("There is no active layer")
        return
    end

    local spriteX, spriteY, spriteZ = IsometricToSpriteCoord(cel.sprite,tile,isoX, isoY, isoZ)
    -- Draw a point using useTool at the isometric coordinates
    drawPoint(layer,{x = spriteX, y = spriteY, z = s})
end

-- Create a dialog
dlg = Dialog("Draw Point in ISO grid")
-- Description of the dialog
dlg:separator()
dlg:label{label="Description:", text = "This script will draw in an isometric grid "}
dlg:label{label="", text = "using the selected brush (even image brushes)"}
dlg:separator{ text = "Tile size"}
dlg:number{ id="tileSizeX", label="    width:", text="64" }
dlg:number{ id="tileSizeY", label="    height:", text="32" }
dlg:separator{ text = "Isometric Coordinates"}
dlg:label{label="WARINING:", text = "X+ is Right, Y+ is Left, Z+ is Down"}
dlg:newrow()
dlg:label{ text = "If you don't want to use Z, leave it as 0"}
dlg:newrow()
dlg:label{ text = "[0,0,0] is the center of the sprite"}
dlg:number{ id="inputX", label="    Iso Coordinate (x):", text="0" }
dlg:number{ id="inputY", label="    Iso Coordinate (y):", text="0" }
dlg:number{ id="inputZ", label="    Iso Coordinate (z):", text="0" }
dlg:button{ text="Draw", onclick=onButtonClick }
dlg:show{ wait=false }
