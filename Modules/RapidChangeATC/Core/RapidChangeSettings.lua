local RapidChangeSettings = {}
--RapidChange constants
local k = rcConstants

--Get Mach4 instance
local inst = mc.mcGetInstance()

local RC_SECTION = "RapidChangeATC"

--Setting definition creation helpers
local function createDefinition(key, label, description, settingType, defaultValue, options)
  defaultValue = defaultValue or 0
  options = options or {}

  return {
    key = key,
    label = label,
    description = description,
    settingType = settingType,
    defaultValue = defaultValue,
    options = options
  }
end

local function createOptionDefinition(key, label, description, options)
  local value = options[1].value
  --wx.wxMessageBox(string.format("Value: %i", value))
  return createDefinition(key, label, description, k.OPTION_SETTING, value, options)
end

--Setting definitions defined in display order for UI looping
local definitions = {
  --Tool Change
  createOptionDefinition(k.ALIGNMENT, "Alignment", "Axis on which the magazine is aligned.", k.ALIGNMENT_OPTIONS),
  createOptionDefinition(k.DIRECTION, "Direction", "Direction of travel from Pocket 1 to Pocket 2.", k.DIRECTION_OPTIONS),
  createDefinition(k.POCKET_COUNT, "Pocket Count", "The number of tool pockets in your magazine.", k.COUNT_SETTING),
  createDefinition(k.POCKET_OFFSET, "Pocket Offset", "Distance between pockets (center-to-center) along the alignment axis.", k.UDISTANCE_SETTING),
  createDefinition(k.X_POCKET_1, "X Pocket 1", "X Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.Y_POCKET_1, "Y Pocket 1", "Y Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.X_MANUAL, "X Manual", "X Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  createDefinition(k.Y_MANUAL, "Y Manual", "Y Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  --createDefinition(k.Z_MANUAL, "Z Manual", "Z Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  -- Comment:  I'd like to create the "Z Manual" setting for those that can't access the manual tool change position easily at k.Z_SAFE_CLEARANCE or 0
  createDefinition(k.Z_ENGAGE, "Z Engage", "Z Position (Machine Coordinates) for full engagement with the clamping nut.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_LOAD, "Z Move To Load", "Z Position to rise to after unloading a tool, before moving to the pocket for loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_PROBE, "Z Move To Probe", "Z Position to rise to after loading a tool, before moving to the tool setter for probing.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SAFE_CLEARANCE, "Z Safe Clearance", "Z Position for the safe clearance of all obstacles.", k.DISTANCE_SETTING),
  createDefinition(k.LOAD_RPM, "Load RPM", "Spindle speed for loading a tool (Clockwise operation).", k.RPM_SETTING),
  createDefinition(k.UNLOAD_RPM, "Unload RPM", "Spindle speed for unloading a tool (Counterclockwise operation).", k.RPM_SETTING),
  createDefinition(k.ENGAGE_FEED_RATE, "Engage Feed Rate", "Feed rate for the engagement process.", k.FEED_SETTING),

  --Tool Touch Off
  --TODO: Add Probe input selection for tool setter?
  -- Comment:  there is the beginning of some code in RapidChangeController.lua
  createDefinition(k.TOUCH_OFF_ENABLED, "Tool Touch Off Enabled", "Calls the configured Tool Touch Off M-Code after loading a tool.", k.SWITCH_SETTING),
  createDefinition(k.TOOL_SETTER_INTERNAL, "Tool Setter Internal", "When enabled the dust cover will open for independent tool touch offs.", k.SWITCH_SETTING),
  createDefinition(k.X_TOOL_SETTER, "X Tool Setter", "X Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Y_TOOL_SETTER, "Y Tool Setter", "Y Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Z_TOOL_SETTER, "Z Tool Setter", "Z Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SEEK_START, "Z Seek Start", "Z Position (Machine Coordinates) to begin the initial(seek) probe.", k.DISTANCE_SETTING),
  --createDefinition(k.SEEK_MAX_DISTANCE, "Seek Max Distance", "Maximum distance of travel from Z Seek Start on initial probe. Used to calculate a probe target and guard against gross over travel.", k.UDISTANCE_SETTING),
  createDefinition(k.SEEK_OVERSHOOT, "Seek Overshoot", "Maximum distance of travel beyond expected probe strike.", k.DISTANCE_SETTING),
  createDefinition(k.SEEK_FEED_RATE, "Seek Feed Rate", "Feedrate for the initial(seek) probe.", k.FEED_SETTING),
  createDefinition(k.SEEK_RETREAT, "Seek Retreat", "Distance to retreat after trigger, before a subsequent(set) probe.", k.UDISTANCE_SETTING),
  createDefinition(k.SET_FEED_RATE, "Set Feed Rate", "Feedrate for any subsequent(seek) probe.", k.FEED_SETTING),

  --Tool Recognition
  createDefinition(k.TOOL_REC_ENABLED, "Tool Recognition Enabled", "Enable infrared tool recognition.", k.SWITCH_SETTING),
  createDefinition(k.TOOL_REC_OVERRIDE, "Tool Recognition Override", "When enabled will override the default disable behavior of pausing for user confirmation.", k.SWITCH_SETTING),
  createOptionDefinition(k.IR_INPUT, "IR Input", "Input # for the tool recognition IR sensor.", k.INPUT_SIGNAL_OPTIONS),
  createOptionDefinition(k.BEAM_BROKEN_STATE, "Beam Broken State", "The state of the IR input when the beam is broken..", k.BEAM_BROKEN_STATE_OPTIONS),
  createDefinition(k.Z_ZONE_1, "Z Zone 1", "Z Position (Machine Coordinates) for confirming the absence of a nut when unloading and the presence of a nut when loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_ZONE_2, "Z Zone 2", "Z Position (Machine Coordinates) for confirming complete threading when loading.", k.DISTANCE_SETTING),

  --Dust Cover
  createDefinition(k.COVER_ENABLED, "Dust Cover Enabled", "Enable programmatic dust cover control.", k.SWITCH_SETTING),
  createOptionDefinition(k.COVER_CONTROL, "Dust Cover Control", "Method for controlling the dust cover programmatically.", k.COVER_CONTROL_OPTIONS),
  createOptionDefinition(k.COVER_AXIS, "Dust Cover Axis", "Designated axis for controlling the dust cover with axis control.", k.COVER_AXIS_OPTIONS),
  createDefinition(k.COVER_OPEN_POS, "Dust Cover Open Position", "Designated axis position (machine coordinates) at which the dust cover is fully open.", k.DISTANCE_SETTING),
  createDefinition(k.COVER_CLOSED_POS, "Dust Cover Closed Position", "Designated axis position (machine coordinates) at which the dust cover is fully closed.", k.DISTANCE_SETTING),
  createOptionDefinition(k.COVER_OUTPUT, "Dust Cover Output", "Output # for controlling the dust cover.", k.OUTPUT_SIGNAL_OPTIONS),
  createDefinition(k.COVER_DWELL, "Dust Cover Dwell", "Dwell time (seconds) to allow an output controlled dust cover to fully open or close.", k.DWELL_SETTING),
  createDefinition(k.COVER_OPEN_M_CODE, "Dust Cover Open M-Code", "The assigned M-Code for opening the dust cover.", k.MCODE_SETTING),
  createDefinition(k.COVER_CLOSE_M_CODE, "Dust Cover Close M-Code", "The assigned M-Code for closing the dust cover.", k.MCODE_SETTING),
}

local function isChecked(value)
  if value == k.ENABLED then
    return true
  elseif value == k.DISABLED then
    return false
  else
    return nil
  end
end

local function getOptionLabels(options)
  local labels = {}

  for i, v in ipairs(options) do
    labels[i] = v.label
  end

  return labels
end

local function getSelectedIndex(options, value)
  for i, v in ipairs(options) do
    if v.value == value then
      return i
    else
      return nil
    end
  end
end

--Setting Provider helper functions
local function createUISetting(definition)
  local value = RapidChangeSettings.GetValue(definition.key)

  return {
    key = definition.key,
    label = definition.label,
    description = definition.description,
    settingType = definition.settingType,
    optionLabels = getOptionLabels(definition.options),
    selectedIndex = getSelectedIndex(definition.options, value),
    isChecked = isChecked(value),
    value = value,
  }
end

--Setting Providers

--Local lookup map
local function buildDefinitionMap()
  local map = {}

  for _, v in ipairs(definitions) do
    if v.key ~= nil then
      map[v.key] = v
    end
  end

  return map
end

local definitionMap = buildDefinitionMap()

--Retrieve a setting's value
function RapidChangeSettings.GetValue(key)
  local definition = definitionMap[key]

  if definition.settingType == k.DISTANCE_SETTING or
    definition.settingType == k.UDISTANCE_SETTING or
    definition.settingType == k.FEED_SETTING or
    definition.settingType == k.RPM_SETTING or
    definition.settingType == k.DWELL_SETTING
  then
    return mc.mcProfileGetDouble(inst, RC_SECTION, definition.key, definition.defaultValue)
  else
    return mc.mcProfileGetInt(inst, RC_SECTION, definition.key, definition.defaultValue)
  end
end

function RapidChangeSettings.GetCurrentSettings()
  local settings = {}

  for _, value in ipairs(definitions) do
    settings[value.key] = RapidChangeSettings.GetValue(value.key)
  end

  return settings
end

--Get an iterable list of settings for UI controls
function RapidChangeSettings.GetUISettingsList()
  local settings = {}

  for i, v in ipairs(definitions) do
    settings[i] = createUISetting(v)
  end

  return settings
end

--UIControl Registration
--Register the UI control upon construction, unregister upon destruction.
--This will allow for the handling of apapting control values to stored values to be handled by RapidChangeSettings.
--The UI can fetch the settings list and create whichever appropriate controls it chooses and let the
--settings worry about what to do with them. Indicate the control type used for the setting from the defined
--control type constants when registering a control.
local registeredControls = {}

function RapidChangeSettings.RegisterUIControl(key, control, controlType)
	
	table.insert(registeredControls, { key = key, control = control, controlType = controlType })

end

function RapidChangeSettings.UnregisterUIControls()
	
	for _, v in ipairs(registeredControls) do
		v.control = nil
	end
	
	collectgarbage()
end

local ControlValueLib = {
	
	[k.INPUT_CONTROL] 	= function (control) return control:GetValue() end,
	[k.CHECK_CONTROL] 	= function (control) if control:IsChecked() then return 1 else return 0 end end,
	[k.RADIO_CONTROL] 	= function (control) return control:GetInt() end,
	[k.SELECT_CONTROL] 	= function (control) return control:GetSelection() end,
	[k.LISTBOX_CONTROL]	= function (control) return control:GetSelection() end,
	[k.CHOICE_CONTROL] 	= function (control) return control:GetSelection() end,
	[k.SPIN_CONTROL] 	= function (control) return control:GetValue() end

}

local function GetControlValue(control, controlType)
	
	return ControlValueLib[controlType] (control)
	
end

--Call from UI to save user input
--Settings will handle reading the input control and updating stored values
function RapidChangeSettings.SaveUISettings()
	
	for _, v in ipairs(registeredControls) do
		
		local key = v.key
		local cntrl = v.control
		local cntrlType = v.controlType
		local value = GetControlValue(cntrl, cntrlType)
		RapidChangeSettings.SetValue(key, value)
	end
	
	mc.mcProfileFlush(inst)
	
end

function RapidChangeSettings.SetValue(key, value)
  
  local definition = definitionMap[key]

  if definition.settingType == k.DISTANCE_SETTING or
		definition.settingType == k.UDISTANCE_SETTING or
		definition.settingType == k.FEED_SETTING or
		definition.settingType == k.RPM_SETTING or
		definition.settingType == k.DWELL_SETTING
  then
		mc.mcProfileWriteDouble(inst, RC_SECTION, definition.key, tonumber(value))
  else
		mc.mcProfileWriteInt(inst, RC_SECTION, definition.key, math.tointeger(value))
  end
  
end

return RapidChangeSettings
