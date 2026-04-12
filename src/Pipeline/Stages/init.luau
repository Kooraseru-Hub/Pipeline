-- Shared/Pipeline/Stages/init.luau
--!strict

--[[
	Declares the ordered pipeline stage configuration consumed by Pipeline.

	Each entry in Entries describes one pipeline stage:
	  - stage     : the stage name to run; matches the sibling folder name
	                under Stages/ that holds the handler modules
	  - breakOn   : message boolean fields that, when true after the stage
	                runs, halt the pipeline and jump to the terminal stage
	  - skipIf    : message boolean fields that, when true before the stage
	                runs, cause the stage to be skipped entirely
	  - alwaysRun : when true the stage is never skipped and breakpoints are
	                never evaluated against it; used for the terminal stage
	  - order     : optional explicit module load order for the stage. When
	                present, modules are loaded in this sequence; any
	                children not in the list are appended at the end
	  - modules   : handler modules for the stage, populated by requiring
	                all ModuleScripts in the stage folder that expose a
	                Handle method
]]

export type StageEntry = {
	stage: string,
	breakOn: { string }?,
	skipIf: { string }?,
	alwaysRun: boolean?,
	order: { string }?,
	modules: { any }?,
}

local Stages = {}

Stages.Entries = {
	{
		stage = "PreSend",
		breakOn = { "dropped" },
	},
	{
		stage = "Validation",
		skipIf = { "isRelay" },
		breakOn = { "dropped" },
	},
	{
		stage = "Sending",
		-- BulkSender must batch before Transport sends, and Transport must
		-- mark dropped before Dispatcher fires locally.
		order = { "BulkSender", "Transport", "Dispatcher", "P2PRelay" },
	},
	{
		stage = "PostSend",
		alwaysRun = true,
	},
} :: { StageEntry }

for _, entry in Stages.Entries do
	local folder = script:FindFirstChild(entry.stage)
	local modules: { any } = {}

	if folder then
		if entry.order then
			local loaded: { [string]: boolean } = {}
			for _, childName in entry.order do
				local child = folder:FindFirstChild(childName)
				if child and child:IsA("ModuleScript") then
					local ok, mod = pcall(require, child)
					if ok and type(mod) == "table" and type(mod.Handle) == "function" then
						modules[#modules + 1] = mod
						loaded[childName] = true
					end
				end
			end
			for _, child in folder:GetChildren() do
				if child:IsA("ModuleScript") and not loaded[child.Name] then
					local ok, mod = pcall(require, child)
					if ok and type(mod) == "table" and type(mod.Handle) == "function" then
						modules[#modules + 1] = mod
					end
				end
			end
		else
			for _, child in folder:GetChildren() do
				if child:IsA("ModuleScript") then
					local ok, mod = pcall(require, child)
					if ok and type(mod) == "table" and type(mod.Handle) == "function" then
						modules[#modules + 1] = mod
					end
				end
			end
		end
	end

	entry.modules = modules
end

return Stages
