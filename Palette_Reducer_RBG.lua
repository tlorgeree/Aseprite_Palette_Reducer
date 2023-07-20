numColors = 1
colors = {}

function updateColorPickerUI ()
    dlg:close()
    
    dlg = getDialogue()
end

function applyPaletteReduction ()
    app.transaction(
        function()
            local sprite = app.site.sprite
        
            if not sprite then
                print("we got here")
                print("No active sprite.")
                return
            end
            
        
            for _, frame in ipairs(sprite.frames) do
                for _, layer in ipairs(sprite.layers) do
                    local cel = layer:cel(frame)
                    if cel then
                        local image = cel.image
                        if image.colorMode == ColorMode.RGB then
                            for it in image:pixels() do
                                local pixelValue = it() -- get pixel
                                
                                if app.pixelColor.rgbaA(pixelValue) > 0 then
                                    currDelta = nil
                                    selectedColor = nil
                                    for i = 1, numColors do
                                        currColor = dlg.data["clr"..i]
                                        if currDelta == nil then 
                                            currDelta = calcColorDelta(pixelValue, currColor)
                                            selectedColor = currColor
                                        else
                                            compare = calcColorDelta(pixelValue, currColor)
                                            if compare < currDelta then
                                                currDelta = compare
                                                selectedColor = currColor
                                            end
                                        end
                                    end
                                    if selectedColor ~= nil then
                                        selectedColor.alpha = app.pixelColor.rgbaA(pixelValue)
                                        image:drawPixel(it.x, it.y, selectedColor) -- set pixel
                                    end
                                end
                            end
                        else
                            print("Error: Image color mode is not RGB.")
                        end
                    else
                        print("Error: No cel found for frame " .. frame.frameNumber .. ", layer '" .. layer.name .. "'.")
                    end
                end
            end
        end

    )
    dlg:close()
end

function getDialogue ()
    local dlg = Dialog { title = "Palette Reducer" }
    for i=1, numColors do
        dlg:color {
            id = "clr"..i,
            label = "Color "..i..":",
            color = Color(0xffff7f00)
        }
    end
    
    dlg:button{
        id = "apply",
        text = "Apply",
        focus = true,
        onclick = function ()
            applyPaletteReduction()
        end
    }

    dlg:button {
        id = "cancel",
        text = "Cancel",
        onclick = function()
            dlg:close()
        end
    }

    dlg:button {
        id = "addColor",
        text = "Add Color",
        onclick = function ()
            numColors = numColors + 1
            updateColorPickerUI()
        end
    }

    dlg:button {
        id = "deleteColor",
        text = "Delete Color",
        onclick = function ()
            if numColors>1 then 
                numColors = numColors - 1
                updateColorPickerUI()
            end
        end
    }

    dlg:show { wait = false }
    return dlg
end

function calcColorDelta(pixel, color)
    delta = math.abs(app.pixelColor.rgbaR(pixel) - color.red)
    + math.abs(app.pixelColor.rgbaB(pixel) - color.blue)
    + math.abs(app.pixelColor.rgbaG(pixel) - color.green)

    return delta
end

updateColorPickerUI()
