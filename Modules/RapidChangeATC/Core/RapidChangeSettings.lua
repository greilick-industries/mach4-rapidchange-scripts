local RapidChangeSettings = {}
--RapidChange constants
local k = rcConstants

--Get Mach4 instance
local inst = mc.mcGetInstance()

local RC_SECTION = "RapidChangeATC"

--Setting definition creation helpers
local function createDefinition(key, section, label, description, settingType, defaultValue, options)
  defaultValue = defaultValue or 0
  options = options or {}

  return {
    key = key,
    section = section,
    label = label,
    description = description,
    settingType = settingType,
    defaultValue = defaultValue,
    options = options
  }
end

local function createOptionDefinition(key, section, label, description, options)
  local value = options[1].value
  --wx.wxMessageBox(string.format("Value: %i", value))
  return createDefinition(key, section, label, description, k.OPTION_SETTING, value, options)
end

--Setting definitions defined in display order for UI looping
local definitions = {
  --Tool Change
  createOptionDefinition(k.ALIGNMENT, k.SECTION_ATC, "Alignment", "Axis on which the magazine is aligned.", k.ALIGNMENT_OPTIONS),
  createOptionDefinition(k.DIRECTION, k.SECTION_ATC, "Direction", "Direction of travel from Pocket 1 to Pocket 2.", k.DIRECTION_OPTIONS),
  createDefinition(k.POCKET_COUNT, k.SECTION_ATC, "Pocket Count", "The number of tool pockets in your magazine.", k.COUNT_SETTING),
  createDefinition(k.POCKET_OFFSET, k.SECTION_ATC, "Pocket Offset", "Distance between pockets (center-to-center) along the alignment axis.", k.UDISTANCE_SETTING),
  createDefinition(k.X_POCKET_1, k.SECTION_ATC, "X Pocket 1", "X Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.Y_POCKET_1, k.SECTION_ATC, "Y Pocket 1", "Y Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.X_MANUAL, k.SECTION_ATC, "X Manual", "X Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  createDefinition(k.Y_MANUAL, k.SECTION_ATC, "Y Manual", "Y Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  createDefinition(k.Z_ENGAGE, k.SECTION_ATC, "Z Engage", "Z Position (Machine Coordinates) for full engagement with the clamping nut.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_LOAD, k.SECTION_ATC, "Z Move To Load", "Z Position to rise to after unloading a tool, before moving to the pocket for loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_PROBE, k.SECTION_ATC, "Z Move To Probe", "Z Position to rise to after loading a tool, before moving to the tool setter for probing.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SAFE_CLEARANCE, k.SECTION_ATC, "Z Safe Clearance", "Z Position for the safe clearance of all obstacles.", k.DISTANCE_SETTING),
  createDefinition(k.LOAD_RPM, k.SECTION_ATC, "Load RPM", "Spindle speed for loading a tool (Clockwise operation).", k.RPM_SETTING),
  createDefinition(k.UNLOAD_RPM, k.SECTION_ATC, "Unload RPM", "Spindle speed for unloading a tool (Counterclockwise operation).", k.RPM_SETTING),
  createDefinition(k.ENGAGE_FEED_RATE, k.SECTION_ATC, "Engage Feed Rate", "Feed rate for the engagement process.", k.FEED_SETTING),

  --Tool Touch Off
  --TODO: Add Probe input selection for tool setter?
  createDefinition(k.TOUCH_OFF_ENABLED, k.SECTION_TOOL_MEASURE, "Tool Touch Off Enabled", "Calls the configured Tool Touch Off M-Code after loading a tool.", k.SWITCH_SETTING),
  createDefinition(k.TOOL_SETTER_INTERNAL, k.SECTION_TOOL_MEASURE, "Tool Setter Internal", "When enabled the dust cover will open for independent tool touch offs.", k.SWITCH_SETTING),
  createDefinition(k.USE_MASTER_TOOL, k.SECTION_TOOL_MEASURE, "Use Master Tool", "When enabled, the chosen master tool will be treated as a master tool.", k.SWITCH_SETTING),
  createDefinition(k.MASTER_TOOL, k.SECTION_TOOL_MEASURE, "Master Tool", "The tool number of the master tool employed when \"Use Master Tool\" mode is enabled.", k.COUNT_SETTING),
  createDefinition(k.X_TOOL_SETTER, k.SECTION_TOOL_MEASURE, "X Tool Setter", "X Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Y_TOOL_SETTER, k.SECTION_TOOL_MEASURE, "Y Tool Setter", "Y Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SEEK_START, k.SECTION_TOOL_MEASURE, "Z Seek Start", "Z Position (Machine Coordinates) to begin the initial(seek) probe.", k.DISTANCE_SETTING),
  createDefinition(k.SEEK_MAX_DISTANCE, k.SECTION_TOOL_MEASURE, "Seek Max Distance", "Maximum distance of travel from Z Seek Start on initial probe. Used to calculate a probe target and guard against gross over travel.", k.UDISTANCE_SETTING),
  createDefinition(k.SEEK_FEED_RATE, k.SECTION_TOOL_MEASURE, "Seek Feed Rate", "Feedrate for the initial(seek) probe.", k.FEED_SETTING),
  createDefinition(k.SEEK_RETREAT, k.SECTION_TOOL_MEASURE, "Seek Retreat", "Distance to retreat after trigger, before a subsequent(set) probe.", k.UDISTANCE_SETTING),
  createDefinition(k.SET_FEED_RATE, k.SECTION_TOOL_MEASURE, "Set Feed Rate", "Feedrate for any subsequent(seek) probe.", k.FEED_SETTING),

  --Internal use only
  createDefinition(k.MASTER_TOOL_REF_POS, k.SECTION_INTERNAL, "Master Tool Ref Pos", "Last triggered machine pos when probing the master tool.", k.INTERNAL_SETTING),
  createDefinition(k.MASTER_TOOL_REF_POS_SET, k.SECTION_INTERNAL, "Master Tool Ref Pos Set", "Indicates whether the master tool reference position has been set", k.INTERNAL_SETTING),

  --Tool Recognition
  createDefinition(k.TOOL_REC_ENABLED, k.SECTION_TOOL_RECOGNITION, "Tool Recognition Enabled", "Enable infrared tool recognition.", k.SWITCH_SETTING),
  createDefinition(k.TOOL_REC_OVERRIDE, k.SECTION_TOOL_RECOGNITION, "Tool Recognition Override", "When enabled will override the default disable behavior of pausing for user confirmation.", k.SWITCH_SETTING),
  createOptionDefinition(k.IR_INPUT, k.SECTION_TOOL_RECOGNITION, "IR Input", "Input # for the tool recognition IR sensor.", k.INPUT_SIGNAL_OPTIONS),
  createOptionDefinition(k.BEAM_BROKEN_STATE, k.SECTION_TOOL_RECOGNITION, "Beam Broken State", "The state of the IR input when the beam is broken..", k.BEAM_BROKEN_STATE_OPTIONS),
  createDefinition(k.Z_ZONE_1, k.SECTION_TOOL_RECOGNITION, "Z Zone 1", "Z Position (Machine Coordinates) for confirming the absence of a nut when unloading and the presence of a nut when loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_ZONE_2, k.SECTION_TOOL_RECOGNITION, "Z Zone 2", "Z Position (Machine Coordinates) for confirming complete threading when loading.", k.DISTANCE_SETTING),

  --Dust Cover
  createDefinition(k.COVER_ENABLED, k.SECTION_COVER, "Dust Cover Enabled", "Enable programmatic dust cover control.", k.SWITCH_SETTING),
  createOptionDefinition(k.COVER_CONTROL, k.SECTION_COVER, "Dust Cover Control", "Method for controlling the dust cover programmatically.", k.COVER_CONTROL_OPTIONS),
  createOptionDefinition(k.COVER_AXIS, k.SECTION_COVER, "Dust Cover Axis", "Designated axis for controlling the dust cover with axis control.", k.COVER_AXIS_OPTIONS),
  createDefinition(k.COVER_OPEN_POS, k.SECTION_COVER, "Dust Cover Open Position", "Designated axis position (machine coordinates) at which the dust cover is fully open.", k.DISTANCE_SETTING),
  createDefinition(k.COVER_CLOSED_POS, k.SECTION_COVER, "Dust Cover Closed Position", "Designated axis position (machine coordinates) at which the dust cover is fully closed.", k.DISTANCE_SETTING),
  createOptionDefinition(k.COVER_OUTPUT, k.SECTION_COVER, "Dust Cover Output", "Output # for controlling the dust cover.", k.OUTPUT_SIGNAL_OPTIONS),
  createDefinition(k.COVER_DWELL, k.SECTION_COVER, "Dust Cover Dwell", "Dwell time (seconds) to allow an output controlled dust cover to fully open or close.", k.DWELL_SETTING),
  createDefinition(k.COVER_OPEN_M_CODE, k.SECTION_COVER, "Dust Cover Open M-Code", "The assigned M-Code for opening the dust cover.", k.MCODE_SETTING),
  createDefinition(k.COVER_CLOSE_M_CODE, k.SECTION_COVER, "Dust Cover Close M-Code", "The assigned M-Code for closing the dust cover.", k.MCODE_SETTING),
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
    section = definition.section,
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

function RapidChangeSettings.GetRequiredDataType( settingType)
	
	local ValueType = {
		[k.DISTANCE_SETTING] 	= function ( ) return "float" end,
		[k.UDISTANCE_SETTING] 	= function ( ) return "float" end,
		[k.FEED_SETTING] 		= function ( ) return "float" end,
		[k.RPM_SETTING] 		= function ( ) return "float" end,
		[k.MCODE_SETTING] 		= function ( ) return "integer" end,
		[k.OPTION_SETTING] 		= function ( ) return "integer" end,
		[k.SWITCH_SETTING] 		= function ( ) return "integer" end,
		[k.COUNT_SETTING] 		= function ( ) return "integer" end,
		-- [k.PORT_SETTING] 	= function ( ) return "integer" end,
		-- [k.PIN_SETTING] 		= function ( ) return "integer" end,
		[k.DWELL_SETTING] 		= function ( ) return "float" end,
	}	
	
	return ValueType [ settingType ] ( )
	
end

--Retrieve a setting's value
function RapidChangeSettings.GetValue(key)
  local definition = definitionMap[key]

  if definition.settingType == k.DISTANCE_SETTING or
    definition.settingType == k.UDISTANCE_SETTING or
    definition.settingType == k.FEED_SETTING or
    definition.settingType == k.RPM_SETTING or
    definition.settingType == k.DWELL_SETTING or
    definition.settingType == k.INTERNAL_SETTING
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
  registeredControls[key] = {
    control = control,
    controlType = controlType
  }
end

function RapidChangeSettings.UnregisterUIControl(key)
  --Is this enough for memory management?
  registeredControls[key] = nil
end

--Call from UI to save user input
--Settings will handle reading the input control and updating stored values
function RapidChangeSettings.SaveUISettings()
  --TODO: Save data from UI controls
end

--Temporary function for configuring from a file
function RapidChangeSettings.SetValue(key, value)
  local definition = definitionMap[key]

  if definition.settingType == k.DISTANCE_SETTING or
    definition.settingType == k.UDISTANCE_SETTING or
    definition.settingType == k.FEED_SETTING or
    definition.settingType == k.RPM_SETTING or
    definition.settingType == k.DWELL_SETTING or
    definition.settingType == k.INTERNAL_SETTING
  then
    return mc.mcProfileWriteDouble(inst, RC_SECTION, definition.key, value)
  else
    return mc.mcProfileWriteInt(inst, RC_SECTION, definition.key, value)
  end
end

return RapidChangeSettings