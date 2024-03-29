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
        label = "    TIP:",
        text = "Isometric pxArt is 2:1 ratio"
    }
    dialog:newrow()
    dialog:label{
        text = "so the tile width is twice the height"
    }
    dialog:number{
        id = "tileSizeX",
        label = "    Tile width ("..isoTiler.tile.size.x .."):",
        text = "" .. isoTiler.tile.size.x,
        onchange = function()
            isoTiler.tile.size.x = dialog.data.tileSizeX
        end
    }
    dialog:number{
        id = "tileSizeY",
        label = "    Tile height ("..isoTiler.tile.size.y .."):",
        text = "" .. isoTiler.tile.size.y,
        onchange = function()
            isoTiler.tile.size.y = dialog.data.tileSizeY
        end
    }

    dialog:separator{
        text = "TEXTURE"
    }
    dialog:label{
        label = "    TIP:",
        text = "Select the shape of the texture"
    }
    dialog:newrow()
    dialog:label{
        text = "Textures can be bigger than the tile size"
    }

    dialog:combobox{
        id = "selectionShape",
        label = "    Texture Shape:",
        option = "fullCube64x64",
        options = {"fullCube64x64", "square64x64", "ground64x32"}, -- TODO: This from isoTiler paramater object
        onchange = function()
            isoTiler.selectionShape = dialog.data.selectionShape

        end
    }
    dialog:slider{
        id = "shapeScale",
        label = "    Texture scale:",
        min = 1,
        max = 500,
        value = isoTiler.shapeScale,
        onrelease = function()
            isoTiler.shapeScale = dialog.data.shapeScale
        end
    }
    dialog:label{
        text = "[1-500]->100% means no change in scale. "
    }
    dialog:newrow()
    dialog:label{
        text = "Only recomended for square textures"
    }
    dialog:separator{
        text = "GENERATION"
    }
    -- sourceLayer
    dialog:combobox{
        id = "sourceLayer",
        label = "    Source Layer",
        option = "Active layer",
        options = {"Active layer"}, -- TODO: Add all layers in the sprite?
        enabled = false,
        onchange = function()
        end
    }
    dialog:number{
        id = "repetitions",
        label = "    Clones per axis:",
        text = "" .. isoTiler.repetitions,
        decimals = 0
    }
    dialog:separator{
        text = "EXECUTE"
    }
    dialog:label{
        label = "    WARNING:",
        text = "Never use execute once and auto tiler at the same time"
    }
    dialog:button{
        id = "executeOnce",
        text = "Execute Once",
        onclick = function()
            printIsoLayer()
            return
        end,
        hexpand = false
    }
    dialog:label{
        label = "    WARNING:",
        text = "If you want to use selections, stop the AutoTiler"
    }
    dialog:separator{
        text = "AUTOTILER"
    }
    dialog:check{
        id = "started",
        label = "    Activate -------->",
        text = "AutoTiler is Stopped",
        selected = false,
        onclick = function()
            toggleAutoUpdate(dialog)
        end,
        focus = false
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
        label = "    width:",
        text = "" .. tile.size.x,
        decimals = 0,
        focus = false
    }
    -- Size input
    dialog:number{
        id = "ftileSizeY",
        label = "    height:",
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
    if not initializeParameters() then
        return
    end

    if dialog.data.started then
        dialog:modify{
            id = "started",
            text = "AutoTiler Is Running..."
        }
        dialog:modify{
            id = "executeOnce",
            enabled = false
        }
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

function printIsoLayer()
    if not initializeParameters() then
        return
    end

    propagateSelectionIsometric(isoTiler.sourceCel, isoTiler.selection, isoTiler.tile, isoTiler.repetitions)
    return true
end

isoTilerDialog = Dialog {
    title = "IsoTiler by @motero2k",
    onclose = stop
}
newsIsoTilerTab(isoTilerDialog)
newFilePanel(isoTilerDialog, isoTiler.tile, isoTiler.repetitions)
isoTilerDialog:endtabs():show{
    wait = false
}

return
