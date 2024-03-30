-- VARIABLES--------------------------------------------------------------------------------------------------
isoTiler = {
    tile = {
        size = {
            x = 64,
            y = 32
        }

    },
    -- First selection is the active selection, the rest are defined by isoTiler.points
    selectionShapes = {"Current User Selection","fullCube_64x64", "ground_64x32","square_64x64"},
    selectionShape = "fullCube_64x64",--Default
    points = {
        fullCube_64x64 = {{0, 15}, {31, 0}, {32, 0}, {63, 15}, {63, 16}, {63, 48}, {32, 63}, {31, 63}, {0, 48}, {0, 16}},
        ground_64x32 = {{0, 15}, {31, 0}, {32, 0}, {63, 15}, {63, 16}, {32, 31}, {31, 31}, {0, 16}},
        square_64x64 = {{0, 0}, {63, 0}, {63, 63}, {0, 63}},
        
    },
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
    isoTiler.selectionShape = isoTilerDialog.data.selectionShape
    isoTiler.repetitions = isoTilerDialog.data.repetitions
    if isoTiler.selectionShape == isoTiler.selectionShapes[1] then
        if not app.activeSprite.selection then
            app.alert("AutoTiler: There is no active selection, please select an area in the sprite")
            return
        end
        local selectionCopy = Selection()
        selectionCopy:add(app.activeSprite.selection)
        isoTiler.selection = selectionCopy


    else
        isoTiler.selection = selectionByPoints(isoTiler.points[isoTiler.selectionShape], isoTiler.shapeScale)
        -- The origin of the selection is the top left corner of the sprite
        -- We want to center the selection in the sprite
        local spriteCenter = {
            x = app.sprite.width / 2,
            y = app.sprite.height / 2
        }
        
        isoTiler.selection.origin = Point(spriteCenter.x - isoTiler.selection.bounds.width / 2,
        spriteCenter.y - isoTiler.selection.bounds.height / 2)
    end
    
    return true -- No errors
end

return

