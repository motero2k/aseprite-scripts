-- Get the active layer
local layer = app.activeLayer

if layer == nil then
  return app.alert("There is no active layer, please select a layer and try again.")
end

-- Get the active layer
local layer = app.activeLayer

if layer == nil then
  return app.alert("There is no active layer")
end

-- Prompt the user for the new opacity value
local dlg = Dialog("Set Layer Opacity")
dlg:number {
  id="opacity",
  label="Opacity (0-255):",
  value=layer.opacity
}
dlg:button {
  text="OK",
  onclick=function()
    -- Get the opacity value from the dialog
    local opacity = dlg.data.opacity
    if opacity < 0 then
      opacity = 0
    end
    if opacity > 255 then
      opacity = 255
    end
    -- Set the opacity of the active layer
    layer.opacity = opacity
    app.refresh()
    return

  end
}
dlg:button {
  text="Cancel",
  onclick=function()
    -- Close the dialog without changing anything
    dlg:close()
  end
}
dlg:show{wait=false}
