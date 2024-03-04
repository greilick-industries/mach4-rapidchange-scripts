local RapidChangeController = {}
--Constants
local k = rcConstants

--Load modules, called from loader
function RapidChangeController.Load(apiExecutor)
		--Allow for debug updates
		package.loaded.RapidChangeConstants = nil
		--Reload the module
		RapidChangeController.Constants = require "RapidChangeConstants"
		--Reassign local convenience variable
		k = RapidChangeController.Constants
end

--Get mach instance
local inst = mc.mcGetInstance()

-- Gcode constants

local LINEAR_TO_MACH = "g90g53g1"
local LINEAR_INCREMENTAL = "g91g1"
local PROBE = "g90g31"
local RAPID_INCREMENTAL = "g91g0"
local RAPID_TO_MACH = "g90g53g0"
local ACTIVATE_TLO = "g43"
local CANCEL_TLO = "g49"
local COOLANT_STOP = "m9"
local DWELL = "g4"
local SPIN_STOP = "m5"
local SPIN_CW = "m3"
local SPIN_CCW = "m4"

--Formatting constants
local F1 = "%.1f"
local F2 = "%.2f"
local F4 = "%.4f"
local I = "%i"


--Word function builder
local function wordFunction(letter, format)
  return function (value)
    return string.format(letter .. format, value)
  end
end

--Word functions
local a = wordFunction("a", F4)
local b = wordFunction("b", F4)
local c = wordFunction("c", F4)
local x = wordFunction("x", F4)
local y = wordFunction("y", F4)
local z = wordFunction("z", F4)

local f = wordFunction("f", F2)
local g = wordFunction("g", I)
local h = wordFunction("h", I)
local m = wordFunction("m", I)
local p = wordFunction("p", F2)
local s = wordFunction("s", F1)

--Concats the provided args to a single string
local function concat(...)
	local result = ""
  local arg = {...}

  for _, v in ipairs(arg) do
    result = result .. v
  end

  return result
end

local function getAxisWord(axis, pos)
	if axis == k.X_AXIS then
		return x(pos)
	elseif axis == k.Y_AXIS then
		return y(pos)
	elseif axis == k.Z_AXIS then
		return z(pos)
	elseif axis == k.A_AXIS then
		return a(pos)
	elseif axis == k.B_AXIS then
		return b(pos)
	elseif axis == k.C_AXIS then
		return c(pos)
	else
		rcErrors.Throw("Invalid axis argument: getAxisWord(axis, pos)")
	end
end

-- Concats the provided args and adds a "\n", for composing a line of gcode
local function line(...)
  return concat(...) .. "\n"
end

local function spin(direction, speed)
	return line(direction, s(speed))
end

--Execute provided lines of gcode. Pass each line of gcode as a separate arg.
local function executeLines(...)
  local block = concat(...)
	local rc = mc.mcCntlGcodeExecuteWait(inst, block)
	rcErrors.GuardAPIError(rc)
end

local function getAxisPos(axis, useMach)
	local pos, rc

	if useMach == k.TRUE then
		pos, rc = mc.mcAxisGetMachinePos(inst, axis)
	else
		pos, rc = mc.mcAxisGetPos(inst, axis)
	end

	rcErrors.GuardAPIError(rc)
	return pos
end

local function getProbeMachPosZ()
	local pos, rc = mc.mcAxisGetProbePos(inst, k.Z_AXIS, k.TRUE)
	rcErrors.GuardAPIError(rc)
	return pos
end

--Public controller functions
function RapidChangeController.GetCurrentTool()
	local tool, rc = mc.mcToolGetCurrent(inst)
	rcErrors.GuardAPIError(rc)
	return tool
end

function RapidChangeController.SetCurrentTool(tool)
	local rc = mc.mcToolSetCurrent(inst, tool)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeController.GetSelectedTool()
	local tool, rc = mc.mcToolGetSelected(inst)
	rcErrors.GuardAPIError(rc)
	return tool
end

function RapidChangeController.ActivateTLO(tool)
	executeLines(line(ACTIVATE_TLO, h(tool)))
end

function RapidChangeController.CancelTLO()
	executeLines(line(CANCEL_TLO))
end

function RapidChangeController.SetTLO(tool, masterTool, refPos)
	local offset = 0 -- master tool offset
	local triggerPos = getProbeMachPosZ()

	if masterTool == nil or refPos == nil then -- not in master tool mode, offset is Z machine pos
		offset = triggerPos
	elseif tool ~= masterTool then -- master tool mode, but we don't have the master tool so calculate the offset
		offset = refPos - triggerPos
	else -- we have the master tool in master tool mode, the offset is 0
		-- we need to update the internal reference
		rcSettings.SetValue(k.MASTER_TOOL_REF_POS, triggerPos)
	end

	-- Record the appropriate offset in the tool table
	local rc = mc.mcToolSetData(inst, mc.MTOOL_MILL_HEIGHT, tool, offset)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeController.CoolantStop()
	executeLines(line(COOLANT_STOP))
end

function RapidChangeController.IsHomed(axis)
	local isHomed, rc = mc.mcAxisIsHomed(inst, axis)
	rcErrors.GuardAPIError(rc)
	return isHomed
end

function RapidChangeController.Dwell(seconds)
	executeLines(line(DWELL, p(seconds)))
end

function RapidChangeController.GetDefaultUnits()
  local units, rc = mc.mcCntlGetUnitsDefault(inst)
	rcErrors.GuardAPIError(rc)
	return units
end

function RapidChangeController.RecordState()
	local rc = mc.mcCntlMachineStatePush(inst)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeController.RestoreState()
	local rc = mc.mcCntlMachineStatePop(inst)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeController.SetDefaultUnits()
  local units = RapidChangeController.GetDefaultUnits()
  local unitCode = units / 10
  RapidChangeController.SetUnits(unitCode)
end

function RapidChangeController.SetUnits(units)
	if units == 20 or units == 21 then
		executeLines(line(g(units)))
	end
end

--Spindle
function RapidChangeController.SpinCCW(speed)
	executeLines(spin(SPIN_CCW, speed))
end

function RapidChangeController.SpinCW(speed)
	executeLines(spin(SPIN_CW, speed))
end

function RapidChangeController.SpinStop()
	executeLines(SPIN_STOP)
end

--Movement
function RapidChangeController.RapidIncremental_Z(zDist)
	executeLines(RAPID_INCREMENTAL, z(zDist))
end

--Rapid machine coord move to xPos, yPos, then to zPos
function RapidChangeController.RapidToMachCoords_XY_Z(xPos, yPos, zPos)
	executeLines(
		line(RAPID_TO_MACH, x(xPos), y(yPos)),
		line(RAPID_TO_MACH, z(zPos))
	)
end

--Rapid machine coord move to zPosTraverse then to xPos, yPos, then to zPosTarget
function RapidChangeController.RapidToMachCoords_Z_XY_Z(zPosTraverse, xPos, yPos, zPosTarget)
	executeLines(
		line(RAPID_TO_MACH, z(zPosTraverse)),
		line(RAPID_TO_MACH, x(xPos), y(yPos)),
		line(RAPID_TO_MACH, z(zPosTarget))
	)
end

function RapidChangeController.LinearIncremental_Z(zDist, feed)
	executeLines(LINEAR_INCREMENTAL, z(zDist), f(feed))
end

function RapidChangeController.LinearToMachCoords_Z_Z(zPos1, zPos2, feed)
	executeLines(
		line(LINEAR_TO_MACH, z(zPos1), f(feed)),
		line(LINEAR_TO_MACH, z(zPos2), f(feed))
	)
end

function RapidChangeController.ProbeDown(maxDistance, feed)
	if maxDistance < 0 then
		maxDistance = maxDistance * -1
	end

	local currentZPos = getAxisPos(k.Z_AXIS)
	local targetZPos = currentZPos - maxDistance

	executeLines(line(PROBE, z(targetZPos), f(feed)))
end

function RapidChangeController.GetProbeStrikeStatus()
	local didStrike, rc = mc.mcCntlProbeGetStrikeStatus(inst)
	rcErrors.GuardAPIError(rc)
	return didStrike
end

function RapidChangeController.RapidToMachCoord(axis, pos)
	local axisWord = getAxisWord(axis, pos)
	executeLines(line(RAPID_TO_MACH, axisWord))
end

function RapidChangeController.RapidToMachCoord_Z(zPos)
	executeLines(line(RAPID_TO_MACH, z(zPos)))
end

function RapidChangeController.ShowBox(message, terminate)
	wx.wxMessageBox(message, "RapidChange ATC")

	if terminate == true then
		error(message)
	end
end

function RapidChangeController.ShowStatus(message)
	local rc = mc.mcCntlSetLastError(inst, message)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeController.Terminate(message)
	if tostring(message) == nil then
		message = "Script terminated without message"
	end

	RapidChangeController.ShowStatus(message)
	error(message)
end

return RapidChangeController
