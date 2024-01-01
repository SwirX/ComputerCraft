-- Define the constants
local pi = math.pi

-- Function to calculate the displacement volume
function calculateDisplacementVolume(bore, stroke, numCylinders)
    local displacementVolume = (pi / 4) * bore * bore * stroke * numCylinders
    return displacementVolume
end

-- Function to calculate the IMEP
function calculateIMEP(indicatedWork, displacementVolume)
    local IMEP = indicatedWork / displacementVolume
    return IMEP
end

-- Example usage
local bore = 0.1 -- Bore diameter in meters
local stroke = 0.1 -- Stroke length in meters
local numCylinders = 4 -- Number of cylinders

local displacementVolume = calculateDisplacementVolume(bore, stroke, numCylinders)
print("Displacement Volume:", displacementVolume, "m^3")

local indicatedWork = 1000 -- Example indicated work in Joules
local IMEP = calculateIMEP(indicatedWork, displacementVolume)
print("IMEP:", IMEP, "Pa")
