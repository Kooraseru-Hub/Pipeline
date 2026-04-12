-- Shared/Pipeline/Stages/Validation/Validator.luau
--!strict
--!optimize 2

local NilType = require("./Types/Nil")
local BooleanType = require("./Types/Boolean")
local NumberType = require("./Types/Number")
local StringType = require("./Types/String")
local TableType = require("./Types/Table")
local AnyType = require("./Types/Any")
local Vector2Type = require("./Types/Vector2")
local Vector3Type = require("./Types/Vector3")
local CFrameType = require("./Types/CFrame")
local Color3Type = require("./Types/Color3")
local UDimType = require("./Types/UDim")
local UDim2Type = require("./Types/UDim2")
local InstanceType = require("./Types/Instance")
local PlayerType = require("./Types/Player")

export type TypeModule = {
	Name: string,
	Tag: number,
	Check: (value: any) -> boolean,
	Encode: (buf: buffer, cursor: number, value: any, validator: any?) -> number,
	Decode: (buf: buffer, cursor: number, validator: any?) -> (any, number),
}

local BUILT_IN_TYPES: { TypeModule } = {
	NilType,
	BooleanType,
	NumberType,
	StringType,
	TableType,
	AnyType,
	Vector2Type,
	Vector3Type,
	CFrameType,
	Color3Type,
	UDimType,
	UDim2Type,
	InstanceType,
	PlayerType,
}

local Validator = {}
Validator.typesByName = {} :: { [string]: TypeModule }
Validator.typesByTag = {} :: { [number]: TypeModule }
Validator.networkedObjects = nil :: any

function Validator:Register(typeModule: TypeModule)
	self.typesByName[typeModule.Name] = typeModule
	self.typesByTag[typeModule.Tag] = typeModule
end

function Validator:LoadBuiltIns()
	self.typesByName = {}
	self.typesByTag = {}
	for i = 1, #BUILT_IN_TYPES do
		self:Register(BUILT_IN_TYPES[i])
	end
end

function Validator:GetByName(name: string): TypeModule?
	return self.typesByName[name]
end

function Validator:GetByTag(tag: number): TypeModule?
	return self.typesByTag[tag]
end

function Validator:SetNetworkedObjects(networkedObjects: any)
	self.networkedObjects = networkedObjects
end

function Validator:GetNetworkedObjects(): any
	return self.networkedObjects
end

function Validator:ResolveByValue(value: any): TypeModule?
	local robloxType: string = typeof(value)
	local byTypeof = self.typesByName[robloxType]
	if byTypeof then
		return byTypeof
	end
	if value == nil then
		return self.typesByName["nil"]
	end
	if robloxType == "Instance" and (value :: Instance):IsA("Player") then
		return self.typesByName["Player"]
	end
	return nil
end

function Validator:Handle(network: any, message: any)
	local paramTypes = message.paramTypes
	if not paramTypes then
		return
	end

	local args = message.args
	for i = 1, #paramTypes do
		local typeName: string = paramTypes[i]
		local typeMod = self.typesByName[typeName]
		if not typeMod then
			warn(`[Validator] unknown type: {typeName}`)
			message.dropped = true
			return
		end

		if not typeMod.Check(args[i]) then
			message.dropped = true
			return
		end
	end
end

return Validator
