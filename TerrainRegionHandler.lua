local ModuleContainer = require(game:GetService("ReplicatedStorage").ModuleScriptLookup)
local ReplicatedConnectionLookup = require(game:GetService("ReplicatedStorage").ReplicatedConnectionLookup)
local ObjectOrientation = require(ModuleContainer.ObjectOrientation)

local Terrain = workspace.Terrain

local TerrainRegionHandler = {
    monitoringHeartbeat = nil;
    isMonitoring = false;
    lastGrid = nil;
    records = {};
}

--constants
local stepSize = 10
local DrawDist = 800

--Debug Settings
local RegionVisualizer = false
local debugging = false

--Map dimensions (Enter only integers)
--TODO: read map bounds from game config
-- This module could be an interface for doing things like getting the bounds of the map
local RawMapXMax = 2314
local RawMapXMin = -3190
local RawMapYMax = 400
local RawMapYMin = -150
local RawMapZMax = 1925
local RawMapZMin = -3422

local MapXMax
local MapXMin
local MapYMax
local MapYMin
local MapZMax
local MapZMin

--Desired cell resolution (cells take the form of 4x4x4 regions, the resolution setting will result in culling 2D XZ grids containing nxn cells. I.e resolution 3 will contain 3x3 or 9 cells) Y parameters will be used to fill cells vertically to min and max
local Resolution = 32

function TerrainRegionHandler:ProcessMapBoundaries() -- Aligns boundary to the voxel grid
    if (RawMapXMax % 4) == 0 then
        MapXMax = RawMapXMax
    else
        MapXMax = RawMapXMax + (4 - (RawMapXMax % 4))
    end
    if (RawMapXMin % 4) == 0 then
        MapXMin = RawMapXMin
    else
        MapXMin = RawMapXMin - (RawMapXMin % 4)
    end
    if (RawMapYMax % 4) == 0 then
        MapYMax = RawMapYMax
    else
        MapYMax = RawMapYMax + (4 - (RawMapYMax % 4))
    end
    if (RawMapYMin % 4) == 0 then
        MapYMin = RawMapYMin
    else
        MapYMin = RawMapYMin - (RawMapYMin % 4)
    end
    if (RawMapZMax % 4) == 0 then
        MapZMax = RawMapZMax
    else
        MapZMax = RawMapZMax + (4 - (RawMapZMax % 4))
    end
    if (RawMapZMin % 4) == 0 then
        MapZMin = RawMapZMin
    else
        MapZMin = RawMapZMin - (RawMapZMin % 4)
    end
end

function TerrainRegionHandler:EstablishTerrainRegions() -- Divides map into even regions specified by resolution value (will extend boundary to compensate)
    local RawXBoundary = MapXMax - MapXMin
    local RawZBoundary = MapZMax - MapZMin
    local StudsPerGrid = (4 * Resolution)
    local XBoundary
    local ZBoundary
    if (RawXBoundary % StudsPerGrid) == 0 then
        XBoundary = RawXBoundary
    else
        XBoundary = RawXBoundary + (StudsPerGrid - (RawXBoundary % StudsPerGrid))
    end
    if (RawZBoundary % StudsPerGrid) == 0 then
        ZBoundary = RawZBoundary
    else
        ZBoundary = RawZBoundary + (StudsPerGrid - (RawZBoundary % StudsPerGrid))
    end
    local NumberOfXGrids = XBoundary/StudsPerGrid
    local NumberOfZGrids = ZBoundary/StudsPerGrid
    print(NumberOfXGrids)
    print(NumberOfZGrids)
    local TotalGrids = 0
    for ZGrid=1,NumberOfZGrids do
        task.wait()
        for XGrid=1,NumberOfXGrids do
            TotalGrids += 1
            local GridMinBoundary = Vector3.new((MapXMax - (StudsPerGrid * (XGrid))), MapYMin, (MapZMax - (StudsPerGrid * (ZGrid))))
            local GridMaxBoundary = Vector3.new((MapXMax - (StudsPerGrid * (XGrid-1))), MapYMax, (MapZMax - (StudsPerGrid * (ZGrid-1))))
            TerrainRegionHandler:CreateTerrainRecord(GridMinBoundary, GridMaxBoundary, XGrid, ZGrid)
        end
    end
    print(TotalGrids)
end

function TerrainRegionHandler:CreateTerrainRecord(TerrainMinBoundary, TerrainMaxBoundary, XGrid, ZGrid)
    if RegionVisualizer then
        local MinCorner = Instance.new("Part", game.Workspace)
        MinCorner.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " MinCorner"
        MinCorner.Color = Color3.fromRGB(255,0,0)
        MinCorner.Position = TerrainMinBoundary
        MinCorner.Anchored = true

        local MaxCorner = Instance.new("Part", game.Workspace)
        MaxCorner.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " MaxCorner"
        MaxCorner.Color = Color3.fromRGB(255,0,0)
        MaxCorner.Position = TerrainMaxBoundary
        MaxCorner.Anchored = true

        local Corner2 = Instance.new("Part", game.Workspace)
        Corner2.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner2"
        Corner2.Color = Color3.fromRGB(0,0,255)
        Corner2.Position = Vector3.new(TerrainMaxBoundary.X, TerrainMinBoundary.Y, TerrainMinBoundary.Z)
        Corner2.Anchored = true

        local Corner3 = Instance.new("Part", game.Workspace)
        Corner3.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner3"
        Corner3.Color = Color3.fromRGB(0,0,255)
        Corner3.Position = Vector3.new(TerrainMinBoundary.X, TerrainMinBoundary.Y, TerrainMaxBoundary.Z)
        Corner3.Anchored = true

        local Corner4 = Instance.new("Part", game.Workspace)
        Corner4.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner4"
        Corner4.Color = Color3.fromRGB(0,0,255)
        Corner4.Position = Vector3.new(TerrainMaxBoundary.X, TerrainMinBoundary.Y, TerrainMaxBoundary.Z)
        Corner4.Anchored = true

        local Corner5 = Instance.new("Part", game.Workspace)
        Corner5.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner5"
        Corner5.Color = Color3.fromRGB(0,0,255)
        Corner5.Position = Vector3.new(TerrainMinBoundary.X, TerrainMaxBoundary.Y, TerrainMinBoundary.Z)
        Corner5.Anchored = true

        local Corner6 = Instance.new("Part", game.Workspace)
        Corner6.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner6"
        Corner6.Color = Color3.fromRGB(0,0,255)
        Corner6.Position = Vector3.new(TerrainMaxBoundary.X, TerrainMaxBoundary.Y, TerrainMinBoundary.Z)
        Corner6.Anchored = true

        local Corner7 = Instance.new("Part", game.Workspace)
        Corner7.Name = tostring(XGrid) .. ":" .. tostring(ZGrid) .. " Corner7"
        Corner7.Color = Color3.fromRGB(0,0,255)
        Corner7.Position = Vector3.new(TerrainMinBoundary.X, TerrainMaxBoundary.Y, TerrainMaxBoundary.Z)
        Corner7.Anchored = true
    end
    local TerrainMinBoundaryint16 = Vector3int16.new(TerrainMinBoundary.X/4, TerrainMinBoundary.Y/4, TerrainMinBoundary.Z/4)
    local TerrainMaxBoundaryint16 = Vector3int16.new(TerrainMaxBoundary.X/4, TerrainMaxBoundary.Y/4, TerrainMaxBoundary.Z/4)
    local TerrainRegion = Region3int16.new(TerrainMinBoundaryint16, TerrainMaxBoundaryint16)
    local terrainRegionInstance = workspace.Terrain:CopyRegion(TerrainRegion)
    local record = {
        region = TerrainRegion; -- Region3int16
        FillRegion = Region3.new(TerrainMinBoundary, TerrainMaxBoundary);
        terrainRegionInstance = terrainRegionInstance;
        corner = TerrainMinBoundaryint16; -- Vector3int16
        visible = true;
        centerX = TerrainMinBoundary.X - ((TerrainMinBoundary.X - TerrainMaxBoundary.X)/2);
        centerZ = TerrainMinBoundary.Z - ((TerrainMinBoundary.Z - TerrainMaxBoundary.Z)/2);
    }

    TerrainRegionHandler.records[tostring(XGrid) .. ":" .. tostring(ZGrid)] = record
end

function TerrainRegionHandler:Init()
    TerrainRegionHandler:ProcessMapBoundaries()
    TerrainRegionHandler:EstablishTerrainRegions()
    TerrainRegionHandler:BeginMonitoring()
end

function TerrainRegionHandler:UpdateVis(name,record,pos)
    local XZCameraPos = pos - Vector3.new(0,pos.Y,0)
    local XZCenter = Vector3.new(record.centerX, 0, record.centerZ)
	--see if we're in the scene
	local dist = (XZCenter - XZCameraPos).magnitude
    local MaxDist = DrawDist

	if (dist > MaxDist) then
		--Can see it
		if(record.visible == true) then
			if (debugging == true) then

				print("Detail hiding", name)
			end
			
			record.visible = false
            local FillRegion = record.FillRegion
            FillRegion = FillRegion:ExpandToGrid(4)
            game.Workspace.Terrain:FillRegion(FillRegion, 4, Enum.Material.Air)
		end
	else
		--can't see it
		if (record.visible == false) then
			if (debugging == true) then
				print("Detail showing", name)
			end
			
			record.visible = true
			workspace.Terrain:PasteRegion(record.terrainRegionInstance, record.corner, true)
		end		
	end
end


function TerrainRegionHandler:AttachHeartbeat()
    self.monitoringHeartbeat = game:GetService("RunService").Heartbeat:Connect(function()
        if not self.isMonitoring then return end
        debug.profilebegin("TerrainRegionStep")
        local pos = workspace.CurrentCamera.CFrame.Position
        local step = stepSize
        local grid = Vector3.new(math.floor(pos.x/step),math.floor(pos.y/step),math.floor(pos.z/step))
    
        --Make sure the camera has moved into a new 4 unit grid
        if (self.lastGrid == nil or self.lastGrid ~= grid) then
            for name,record in pairs(TerrainRegionHandler.records) do
                TerrainRegionHandler:UpdateVis(name,record,pos)
            end
        end
        self.lastGrid = grid
        debug.profileend()
    end)
end

function TerrainRegionHandler:BeginMonitoring()
    self.isMonitoring = true
    if not self.monitoringHeartbeat then
        self:AttachHeartbeat()
    end
end

return TerrainRegionHandler