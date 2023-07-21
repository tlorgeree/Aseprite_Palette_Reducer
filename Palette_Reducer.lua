numColors = 1
colors = {}

function updateColorPickerUI ()
    if dlg then dlg:close() end
    
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
                                            if dlg.data["colorType"] == "LAB" then
                                                currDelta = calcColorDeltaLAB(pixelValue, currColor)
                                            else 
                                                currDelta = calcColorDeltaRGB(pixelValue, currColor)
                                            end

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
    
    dlg:combobox{ 
        id="colorType",
        label="colorType",
        option="LAB",
        options={ "LAB", "RGB" }, 
    }

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


function RGBtoXYZ(rgb)
    local r = rgb.red / 255
    local g = rgb.green / 255
    local b = rgb.blue / 255

    -- Applying gamma correction
    r = (r > 0.04045) and (( (r + 0.055) / 1.055) ^ 2.4) or (r / 12.92)
    g = (g > 0.04045) and (( (g + 0.055) / 1.055) ^ 2.4) or (g / 12.92)
    b = (b > 0.04045) and (( (b + 0.055) / 1.055) ^ 2.4) or (b / 12.92)

    -- sRGB D65 illuminant
    local x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    local y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    local z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

    return x, y, z
end

-- Helper function to convert XYZ to LAB
function XYZtoLab(x, y, z)
    local epsilon = 0.008856
    local kappa = 903.3
    local xn, yn, zn = 0.950456, 1.0, 1.088754

    local fX = (x > epsilon) and (x ^ (1 / 3)) or ((kappa * x + 16) / 116)
    local fY = (y > epsilon) and (y ^ (1 / 3)) or ((kappa * y + 16) / 116)
    local fZ = (z > epsilon) and (z ^ (1 / 3)) or ((kappa * z + 16) / 116)

    local L = (116 * fY) - 16
    local a = 500 * (fX - fY)
    local b = 200 * (fY - fZ)

    return L, a, b
end

-- Main function to convert RGB to Lab
function RGBtoLab(rgb)
    local x, y, z = RGBtoXYZ(rgb)
    return XYZtoLab(x, y, z)
end

-- Function to calculate LAB delta
function calcColorDeltaLAB(pixel, color)
    -- Convert pixel color to RGB
    local pixelColor = Color(
        app.pixelColor.rgbaR(pixel),
        app.pixelColor.rgbaG(pixel),
        app.pixelColor.rgbaB(pixel)
    )

    local pixelL, pixelA, pixelB = RGBtoLab(pixelColor)
    local targetL, targetA, targetB = RGBtoLab(color)

    local deltaL = math.abs(targetL - pixelL)
    local deltaA = math.abs(targetA - pixelA)
    local deltaB = math.abs(targetB - pixelB)

    local totalDelta = math.sqrt(deltaL^2 + deltaA^2 + deltaB^2)

    return totalDelta
end

function calcColorDeltaRGB(pixel, color)
    delta = math.abs(app.pixelColor.rgbaR(pixel) - color.red)
    + math.abs(app.pixelColor.rgbaB(pixel) - color.blue)
    + math.abs(app.pixelColor.rgbaG(pixel) - color.green)

    return delta
end

updateColorPickerUI()
