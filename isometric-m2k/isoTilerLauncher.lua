-- VARIABLES--------------------------------------------------------------------------------------------------
isoTiler = {
    tile = {
        size = {
            x = 64,
            y = 32
        }

    },
    points = {
        square64x64 = {{0, 0}, {63, 0}, {63, 63}, {0, 63}},
        ground64x32 = {{0, 15}, {31, 0}, {32, 0}, {63, 15}, {63, 16}, {32, 31}, {31, 31}, {0, 16}},
        fullCube64x64 = {{0, 15}, {31, 0}, {32, 0}, {63, 15}, {63, 16}, {63, 48}, {32, 63}, {31, 63}, {0, 48}, {0, 16}}
        
    },
    selectionShape = "fullCube64x64",
    shapeScale = 100,
    repetitions = 3,
    sourceCel = nil,
    sourceSprite = nil,

}

dofile("./.utils.lua")
-- creates the dialog
dofile("./.isoTilerDialog.lua")



function initializeParameters()
    local activeCel = app.activeCel
    if not activeCel then
        app.alert(
            "AutoTiler: There is no selected cel, please open a sprite and select a Layer with content in the current Frame  (white circle in the timeline)")
        return
    end
    if activeCel.layer.name == "Tiled-Layer" then
        app.alert("AutoTiler: The source layer cannot be the same as the destination layer, please select another layer")
        return
    end
    
    isoTiler.sourceCel = activeCel
    isoTiler.sourceSprite = isoTiler.sourceCel.sprite
    isoTiler.selectionShape = isoTilerDialog.data.selectionShape --TODO: check
    isoTiler.repetitions = isoTilerDialog.data.repetitions
    isoTiler.selection = selectionByPoints(isoTiler.points[isoTiler.selectionShape], isoTiler.shapeScale)
    -- The origin of the selection is the top left corner of the sprite
    -- We want to center the selection in the sprite
    local spriteCenter = {
        x = app.sprite.width / 2,
        y = app.sprite.height / 2
    }

    isoTiler.selection.origin = Point(spriteCenter.x - isoTiler.selection.bounds.width / 2,
        spriteCenter.y - isoTiler.selection.bounds.height / 2)
    
    return true -- No errors
end

return

