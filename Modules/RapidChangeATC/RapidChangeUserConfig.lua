--[[
Temporary RapidChange ATC Configuration
This file contains a single function to load your configuration RapidChange ATC.
In the function RapidChangeUserConfig.load(), each line sets a value to a particular
RapidChange setting. See the format below:

rcSettings.SetValue(k.SETTING_NAME, Value)

Replace the Value parameter for each setting with the appropriate value for your configuration.
Values will either be numbers or one of a list of options.

For values that use options, see the format below:

-- Options: (OPTION_ONE, OPTION_TWO)
rcSettings.SetValue(k.SETTING_NAME, k.OPTION_ONE)

If you wanted to declare OPTION_TWO, change k.OPTION_ONE to k.OPTION_TWO:

-- Options: (OPTION_ONE, OPTION_TWO)
rcSettings.SetValue(k.SETTING_NAME, k.OPTION_TWO) 
--]]

local RapidChangeUserConfig = {}

local k = rcConstants

function RapidChangeUserConfig.Load()
  -- Tool Change Settings

  -- IMPORTANT: UNITS --
  -- Configure using your established default machine units.

  -- Axis on which the magazine is aligned.
  -- Options: (X_AXIS, Y_AXIS)
  rcSettings.SetValue(k.ALIGNMENT, k.X_AXIS)

  -- Direction of travel from Pocket 1 to Pocket 2.
  -- Options: (POSITIVE, NEGATIVE)
  rcSettings.SetValue(k.DIRECTION, k.POSITIVE)

  -- Number of tool pockets in the magazine.
  rcSettings.SetValue(k.POCKET_COUNT, 0)

  -- Distance between pockets (center-to-center) along the alignment axis.
  rcSettings.SetValue(k.POCKET_OFFSET, 0)

  -- X Position (Machine Coordinates) of the center of Pocket 1.
  rcSettings.SetValue(k.X_POCKET_1, 0.000)

  -- Y Position (Machine Coordinates) of the center of Pocket 1.
  rcSettings.SetValue(k.Y_POCKET_1, 0.000)

  -- X Position (Machine Coordinates) for manual tool changes.
  rcSettings.SetValue(k.X_MANUAL, 0.000)

  -- Y Position (Machine Coordinates) for manual tool changes.
  rcSettings.SetValue(k.Y_MANUAL, 0.000)

  -- Z Position (Machine Coordinates) for full engagement with the clamping nut.
  rcSettings.SetValue(k.Z_ENGAGE, 0.000)

  -- Z Position (Machine Coordinates) for traversal between unloading and loading a tool.
  rcSettings.SetValue(k.Z_MOVE_TO_LOAD, 0.000)

  -- Z Position (Machine Coordinates) for traversal between loading and probing a tool.
  rcSettings.SetValue(k.Z_MOVE_TO_PROBE, 0.000)

  -- Z Position (Machine Coordinates) for clearance of all potential obstacles.
  rcSettings.SetValue(k.Z_SAFE_CLEARANCE, 0.000)

  -- Spindle speed for loading a tool (Clockwise operation).
  rcSettings.SetValue(k.LOAD_RPM, 1000.0)

  -- Spindle speed for unloading a tool (Counterclockwise operation).
  rcSettings.SetValue(k.UNLOAD_RPM, 1000.0)

  -- Feed rate for the engagement process.
  rcSettings.SetValue(k.ENGAGE_FEED_RATE, 0.0)


  -- Tool Touch Off Settings

  -- Calls the configured Tool Touch Off M-Code after loading a tool when enabled.
  -- Options: (DISABLED, ENABLED)
  rcSettings.SetValue(k.TOUCH_OFF_ENABLED, k.DISABLED)

  -- When enabled the dust cover will operate for independently called tool touch offs.
  -- Options: (TRUE, FALSE)
  rcSettings.SetValue(k.TOOL_SETTER_INTERNAL, k.TRUE)

  -- When enabled, the chosen MASTER_TOOL will be treated as the master tool.
  -- Touch offs with the MASTER_TOOL will record the trigger position for a 0
  -- reference from which all other tool offsets will be calculated.
  -- Options: (DISABLED, ENABLED)
  rcSettings.SetValue(k.USE_MASTER_TOOL, k.DISABLED)

  -- The tool number of the chosen master tool for USE_MASTER_TOOL mode.
  rcSettings.SetValue(k.MASTER_TOOL, 1)

  -- X Position (Machine Coordinates) of the center of the tool setter.
  rcSettings.SetValue(k.X_TOOL_SETTER, 0.000)

  -- Y Position (Machine Coordinates) of the center of the tool setter.
  rcSettings.SetValue(k.Y_TOOL_SETTER, 0.000)

  -- Z Position (Machine Coordinates) to begin the initial(seek) probe.
  rcSettings.SetValue(k.Z_SEEK_START, 0.000)

  -- Maximum distance of travel from Z Seek Start on initial probe. 
  -- Safety measure for gross over travel.
  rcSettings.SetValue(k.SEEK_MAX_DISTANCE, 0.000)

  -- Feedrate for the initial(seek) probe.
  rcSettings.SetValue(k.SEEK_FEED_RATE, 0.0)

  -- Distance to retreat after trigger, before a subsequent(set) probe.
  rcSettings.SetValue(k.SEEK_RETREAT, 0.000)

  -- Feedrate for any subsequent(set) probe.
  rcSettings.SetValue(k.SET_FEED_RATE, 0.0)


  -- Tool Recognition Settings

  -- Enable/Disable infrared tool recognition.
  -- Default behavior when disabled is to pause for user confirmation on each load or unload.
  -- Options: (DISABLED, ENABLED)
  rcSettings.SetValue(k.TOOL_REC_ENABLED, k.DISABLED)

  -- Enable/Disable tool recognition override.
  -- Enable override when tool recognition is disabled to override the default pause for confirmation.
  -- WARNING: Tool change will NOT stop on a failed load or unload when using override.
  -- Options: (DISABLED, ENABLED)
  rcSettings.SetValue(k.TOOL_REC_OVERRIDE, k.DISABLED)

  -- IR Sensor input #, for Input #1 enter 1, Input #2 enter 2, etc.
  rcSettings.SetValue(k.IR_INPUT, 0)

  -- Indicate the state of the input when the ir beam is broken.
  -- Options: (ACTIVE, INACTIVE)
  rcSettings.SetValue(k.BEAM_BROKEN_STATE, k.ACTIVE)

  -- Z Position (Machine Coordinates) for confirming the absence of a nut when unloading and the presence of a nut when loading.
  rcSettings.SetValue(k.Z_ZONE_1, 0.000)

  -- Z Position (Machine Coordinates) for confirming complete threading when loading.
  rcSettings.SetValue(k.Z_ZONE_2, 0.000)


  -- Dust Cover Settings

  -- Enable programmatic dust cover control.
  -- Options: (DISABLED, ENABLED)
  rcSettings.SetValue(k.COVER_ENABLED, k.DISABLED)

  -- Method for controlling the dust cover programmatically.
  -- Options: (COVER_CONTROL_AXIS, COVER_CONTROL_OUTPUT)
  rcSettings.SetValue(k.COVER_CONTROL, k.COVER_CONTROL_AXIS)

  -- Axis control only
  -- Designated axis for controlling the dust cover with axis control.
  -- Options: (A_AXIS, B_AXIS, C_AXIS)
  rcSettings.SetValue(k.COVER_AXIS, k.A_AXIS)

  -- Axis control only
  -- Designated axis position (machine coordinates) at which the dust cover is fully open.
  rcSettings.SetValue(k.COVER_OPEN_POS, 0.000)

  -- Axis control only
  -- Designated axis position (machine coordinates) at which the dust cover is fully closed.
  rcSettings.SetValue(k.COVER_CLOSED_POS, 0.000)

  -- Ouptut control only
  -- Dust cover output #, for Output #1 enter 1, Output #2 enter 2, etc.
  rcSettings.SetValue(k.COVER_OUTPUT, 0)

  -- Ouptut control only
  -- Dwell time (seconds) to allow an output controlled dust cover to fully open or close.
  rcSettings.SetValue(k.COVER_DWELL, 0.00)

  
  -- DO NOT ALTER OR REMOVE
  -- Call to update settings for macros 
  rcSub.UpdateSettings()
end

return RapidChangeUserConfig