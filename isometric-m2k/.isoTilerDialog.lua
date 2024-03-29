-- FUNCTIONS----------------------------------------------------------------------------------------------------------------------------
function newsIsoTilerTab(dialog)
    dialog:tab{
        id = "tiler",
        text = "Settings"
    }
    dialog:separator{
        text = "TILES"
    }
    dialog:label{
        label = "TIP:",
        text = "PixelArt Isometric ratio is 2:1"
    }
    dialog:newrow()
    dialog:label{
        text = "Pure Isometric ratio is 1.732:1"
    }
    dialog:number{
        id = "tileSizeX",
        label = "Tile width (" .. isoTiler.tile.size.x .. "):",
        text = "" .. isoTiler.tile.size.x,
        onchange = function()
            isoTiler.tile.size.x = dialog.data.tileSizeX
        end
    }
    dialog:number{
        id = "tileSizeY",
        label = "Tile height (" .. isoTiler.tile.size.y .. "):",
        text = "" .. isoTiler.tile.size.y,
        onchange = function()
            isoTiler.tile.size.y = dialog.data.tileSizeY
        end
    }

    dialog:separator{
        text = "TEXTURE"
    }

    dialog:combobox{
        id = "selectionShape",
        label = "Texture Shape:",
        option = "fullCube64x64",
        options = {"fullCube64x64", "square64x64", "ground64x32"}, -- TODO: This from isoTiler paramater object
        onchange = function()
            isoTiler.selectionShape = dialog.data.selectionShape

        end
    }
    dialog:button{
        text = "Mask shape",
        onclick = function()
            if app.activeSprite then
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
        end
    }
    dialog:button{
        text = "Invert mask",
        onclick = function()
            if app.activeSprite then
                app.command.InvertMask()
            end
        end

    }

    dialog:slider{
        id = "shapeScale",
        label = "Texture scale:",
        min = 1,
        max = 500,
        value = isoTiler.shapeScale,
        onrelease = function()
            isoTiler.shapeScale = dialog.data.shapeScale
        end
    }
    dialog:button{
        text = "Reset Scale",
        onclick = function()
            dialog:modify{
                id = "shapeScale",
                value = 100
            }
            isoTiler.shapeScale = 100
        end
    }
    dialog:label{
        text = "Textures can be bigger than the tile size"
    }
    dialog:newrow()
    dialog:label{
        text = "[1-500] 100% means no change in scale. "
    }

    dialog:separator{
        text = "GENERATION"
    }
    -- sourceLayer
    dialog:combobox{
        id = "sourceLayer",
        label = "Source Layer",
        option = "Active layer",
        options = {"Active layer"}, -- TODO: Add all layers in the sprite?
        enabled = false,
        onchange = function()
        end
    }
    dialog:number{
        id = "repetitions",
        label = "Clones per axis:",
        text = "" .. isoTiler.repetitions,
        decimals = 0
    }
    dialog:separator{
        text = "EXECUTE"
    }
    dialog:label{
        label = "WARNING:",
        text = "Never use it when AutoTiler is ON"
    }
    dialog:button{
        id = "executeOnce",
        text = "Execute Once",
        onclick = function()
            if not app.activeSprite then
                app.alert("There is no active sprite")
                return
            end
            printIsoLayer()
            return
        end,
        hexpand = false
    }

    dialog:separator{
        text = "AUTOTILER"
    }

    dialog:check{
        id = "started",
        label = "Activate ------>",
        text = "AutoTiler is Stopped",
        selected = false,
        onclick = function()
            toggleAutoUpdate(dialog)
        end,
        focus = false
    }
    dialog:label{
        text = "on spritechange updates 'Tiled-Layer' "
    }
    dialog:newrow()
    dialog:label{
        text = "To delete the 'Tiled-Layer' stop AutoTiler"
    }
    return dialog
end

-- Creates a file tab in the dialog
function newFilePanel(dialog, tile)
    -- Makes a tab
    dialog:tab{
        id = "NewFile",
        text = "NewFile"
    }
    dialog:separator{
        text = "Tile size"
    }
    -- Size input
    dialog:number{
        id = "ftileSizeX",
        label = "width:",
        text = "" .. tile.size.x,
        decimals = 0,
        focus = false
    }
    -- Size input
    dialog:number{
        id = "ftileSizeY",
        label = "height:",
        text = "" .. tile.size.y,
        decimals = 0,
        focus = false
    }
    -- Repetitions input

    dialog:number{
        id = "horizontalTiles",
        label = "Number of horizontal tiles:",
        text = "10",
        decimals = 0
    }
    -- Create new file button
    dialog:button{
        text = "Create New File",
        onclick = function()
            tile = {
                size = {
                    x = dialog.data.ftileSizeX,
                    y = dialog.data.ftileSizeY
                }
            }
            horizontalTiles = dialog.data.horizontalTiles
            createNewFile(tile, horizontalTiles)
        end
    }
    return dialog

end

-- Creates a new sprite
function createNewFile(tile, repetitions)
    local newSprite = Sprite(tile.size.x * repetitions, tile.size.y * repetitions, ColorMode.RGB)
    app.activeSprite = newSprite
    app.command.LoadPalette {
        preset = "default"
    }
    return newSprite
end

function toggleAutoUpdate(dialog)

    if dialog.data.started then
        if not app.activeSprite then
            app.alert("There is no active sprite")
            dialog:modify{
                id = "started",
                selected = false
            }
            return
        end
        dialog:modify{
            id = "started",
            text = "AutoTiler Is Running..."
        }
        dialog:modify{
            id = "executeOnce",
            enabled = false
        }
        isoTiler.sourceSprite = app.activeSprite
        local listener = isoTiler.sourceSprite.events:on('change', printIsoLayer)

    else
        dialog:modify{
            id = "started",
            text = "AutoTiler is Stopped"
        }
        isoTiler.sourceSprite.events:off(printIsoLayer)
        dialog:modify{
            id = "executeOnce",
            enabled = true
        }
    end
    return
end

function printIsoLayer(ev)
    if ev and ev.fromUndo then -- Skip the event if it comes from an undo operation
        return
    end
    app.transaction(function()

        local userSelection = Selection() -- Makes a new instance of a selection (not a reference to the active selection, a copy)
        userSelection:add(app.activeSprite.selection)

        if not initializeParameters() then
            return
        end
        propagateSelectionIsometric(isoTiler.sourceCel, isoTiler.selection, isoTiler.tile, isoTiler.repetitions)
        -- Restore the user selection
        if userSelection then
            app.activeSprite.selection = userSelection
        end
    end)
    return true
end
isoTilerDialog = Dialog {
    title = "IsoTiler by @motero2k",
    onclose = function()
        if isoTiler.sourceSprite then
            isoTiler.sourceSprite.events:off(printIsoLayer)
        end
    end
}
newsIsoTilerTab(isoTilerDialog)
newFilePanel(isoTilerDialog, isoTiler.tile, isoTiler.repetitions)
isoTilerDialog:endtabs():show{
    wait = false
}

return
