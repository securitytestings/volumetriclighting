local Volumetrics = require(script.Volumetrics)

local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local VolumetricQuality = TeleportService:GetLocalPlayerTeleportData()
print(VolumetricQuality)

local camera = workspace.CurrentCamera

repeat
	task.wait(1)
until game:IsLoaded()

repeat
	task.wait(0.1)
until camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 and camera.FieldOfView > 0


if VolumetricQuality == "Max" or VolumetricQuality == "Medium" or RunService:IsStudio() then
	local volumetric = Volumetrics.new(camera, script:GetAttribute("Layers"), script:GetAttribute("Spacing"), Volumetrics.Enum[script:GetAttribute("RenderMethod")], VolumetricQuality)
	print("Setup volumetrics!")
	volumetric.Visible = script:GetAttribute("Visible")
	volumetric.Transparency = script:GetAttribute("Transparency")

	script.AttributeChanged:Connect(function(attribute: string)
		local num = script:GetAttribute(attribute)

		if tonumber(num) == nil then
			return
		end

		if attribute == "Layers" then
			volumetric.Depth = num
			volumetric:RenderVolumetrics()
		end
		if attribute == "Spacing" then
			volumetric.LayerSpacing = num
			volumetric:RenderVolumetrics()
		end
		if attribute == "Transparency" then
			volumetric.Transparency = num
			volumetric:RenderVolumetrics()
		end
		if attribute == "LightEmission" then
			volumetric.LightEmission = num
			volumetric:RenderVolumetrics()
		end
	end)
	script:GetAttributeChangedSignal("Visible"):Connect(function()
		volumetric.Visible = script:GetAttribute("Visible")
		volumetric:RenderVolumetrics()
	end)
	script:GetAttributeChangedSignal("RenderMethod"):Connect(function()
		volumetric.RenderMethod = Volumetrics.Enum[script:GetAttribute("RenderMethod")]
		volumetric:RenderVolumetrics()
	end)

	RunService.RenderStepped:Connect(function(delta: number)
		volumetric:UpdateVolumetrics(delta)
	end)
else
	warn("No Volumetric Lighting enabled.")
end
