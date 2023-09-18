
-- Create main frame with buttons and labels
local function create_main_frame(player)
    -- Create parent frame (Standalone Window) in player.gui.screen for draggability
    local parent_frame = player.gui.screen.add{type="frame", name="parent_frame", direction="vertical"}

    -- Make the frame draggable
    local dragger = parent_frame.add{type="empty-widget"}
    dragger.style = "draggable_space_header"
    dragger.style.size = {400, 10}
    dragger.drag_target = parent_frame

    -- Position the parent frame at the top of the screen
    parent_frame.location = {x=0, y=600}

    -- Create a frame to hold inner_frame1 and inner_frame2 horizontally
    local horizontal_frame = parent_frame.add{type="frame", name="horizontal_frame", direction="vertical"}

    -- Create first inner frame for buttons (Content Frame)
    local inner_frame1 = horizontal_frame.add{
        type = "frame",
        name = "inner_frame1",
        direction = "horizontal",
        style = "frame"
    }

    -- Add sprite-buttons to first inner frame
    inner_frame1.add{type = "sprite-button", name = "start_button", sprite = "start_button_sprite"}
	inner_frame1.add{type = "sprite-button", name = "speed_up_button", sprite = "speed_up_button_sprite" }
    inner_frame1.add{type = "sprite-button", name = "reset_button", sprite = "reset_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "auto_button", sprite = "auto_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "sets_button", sprite = "sets_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "settings_button", sprite = "settings_button_sprite"}
	inner_frame1.start_button.tooltip = "Start/Stop the test"
	inner_frame1.reset_button.tooltip = "Stops the test and delete trains"
	inner_frame1.auto_button.tooltip = "Switch between Auto and Manual mode"
	inner_frame1.sets_button.tooltip = "Sets configuration in manual mode"
	inner_frame1.settings_button.tooltip = "Open Settings"
	inner_frame1.speed_up_button.tooltip = "Changes game.speed between 1 and 20"

    -- Create second inner frame for labels (Content Frame)
    local inner_frame2 = horizontal_frame.add{
        type = "frame",
        name = "inner_frame2",
        direction = "horizontal",
        style = "frame"
    }

    -- Add labels to second inner frame
	inner_frame2.add{type = "label", name = "current_time_running_label", caption = "0", style = "label"}
	inner_frame2.add{type = "label", name = "current_set_label", caption = "Set: 0", style = "label"}
	inner_frame2.add{type = "label", name = "current_tpm_label", caption = "TPM: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set1_label", caption = "Set 1: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set2_label", caption = "Set 2: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set3_label", caption = "Set 3: 0", style = "label"}
    inner_frame2.add{type = "label", name = "score_label", caption = "Score: 0", style = "label"}
end

-- Event handler for game initialization
script.on_configuration_changed(function()
	global.temp_slider_values = {}
	global.sec = 0
    global = global or {}
    global.auto_mode = global.auto_mode or true
    global.set_number = global.set_number or 1
    global.reset_signal = global.reset_signal or false
    global.M_value = global.M_value or 15
	global.pending_resets = global.pending_resets or {}
	global.TPM_value = global.TPM_value or 2900  -- Initialize to 2900 if it doesn't exist
	global.testbench_running = global.testbench_running or false
	global.numberofways = global.numberofways or 4
	global.Wagons_value = global.Wagons_value or 4
	global.Loco_value = global.Loco_value or 2
	global.TestRuns_value = global.TestRuns_value or 1
	global.TestRuns_counter = 1
	global.despawned_trains = 0
	global.current_test = 1
	global.test_scores = {}
	global.testtimer = 0
	global.tpmtick = 360000/global.TPM_value
	global.counter = 0

    for i, player in pairs(game.players) do
        if player and player.valid then
            destroy_GUI(player)  -- Pass player as an argument
            create_main_frame(player)
		end
    end
end)


-- Destroy GUI
function destroy_GUI(player)
    if player.gui.screen["outer_frame"] then
        player.gui.screen["outer_frame"].destroy()
    end
    if player.gui.screen["parent_frame"] then
        player.gui.screen["parent_frame"].destroy()
    end
end

function read_signal_state_at_coordinates(x, y)
    local signal_entity = game.surfaces[1].find_entity("rail-signal", {x, y})
    if signal_entity then
        local state_enum = signal_entity.signal_state
        local state_description = "Unknown"

        if state_enum == defines.signal_state.open then
            state_description = "Closed (red)"
        elseif state_enum == defines.signal_state.reserved then
            state_description = "Reserved (Orange)"
		end

        return state_description
    else
        return nil
    end
end

function create_settings_frame(player)
    if player.gui.screen["settings_frame"] then
        return  -- Do nothing if settings frame already exists
    end

    local frame = player.gui.screen.add{type="frame", name="settings_frame", direction="vertical"}

    -- Make the frame draggable
    local dragger = frame.add{type="empty-widget"}
	dragger.style = "draggable_space_header"
    dragger.style.size = {200, 24}
    dragger.drag_target = frame

    -- Position the frame at the top of the screen
    frame.location = {x=400, y=400}

    -- Add title label to the main frame
    local title_label = frame.add{type="label", name="settings_title_label", caption="Settings"}
    title_label.style.font = "default-large-bold"

    -- Create a flow to hold both sets of sliders and labels
    local main_flow = frame.add{type="flow", name="main_flow", direction="horizontal"}

    -- Create a flow to hold the first set of sliders and labels
    local settings_flow = main_flow.add{type="flow", name="settings_flow", direction="vertical"}

    -- Add M slider and labels
    settings_flow.add{type="label", name="M_label", caption="Test time per set"}
    local M_slider = settings_flow.add{type="slider", name="M_slider", minimum_value=1, maximum_value=120, value=global.M_value or 0, value_step=1}
    settings_flow.add{type="label", name="M_value_label", caption=tostring(global.M_value or 1) .. " Min"}

    -- Add TPM slider and labels
	settings_flow.add{type="label", name="TPM_label", caption="Trains per min goal:"}
	local TPM_slider = settings_flow.add{type="slider", name="TPM_slider", minimum_value=0.5, maximum_value=3300 / 100, value=(global.TPM_value or 50) / 100, value_step=0.5}
	settings_flow.add{type="label", name="TPM_value_label", caption=string.format("%.2f", (global.TPM_value or 50) / 100)}
	
    -- Add Reset Button
    settings_flow.add{type="button", name="reset_values_button", caption="Reset Values"}
	

    -- Create a flow to hold the second set of sliders and labels
    local settings_flow2 = main_flow.add{type="flow", name="settings_flow2", direction="vertical"}

    -- Add Loco slider and labels
    settings_flow2.add{type="label", name="Loco_label", caption="Loco:"}
    local Loco_slider = settings_flow2.add{type="slider", name="Loco_slider", minimum_value=1, maximum_value=5, value=global.Loco_value or 2, value_step=1}
    settings_flow2.add{type="label", name="Loco_value_label", caption=tostring(global.Loco_value or 2)}

    -- Add Wagons slider and labels
    settings_flow2.add{type="label", name="Wagons_label", caption="Wagons:"}
    local Wagons_slider = settings_flow2.add{type="slider", name="Wagons_slider", minimum_value=0, maximum_value=10, value=global.Wagons_value or 0, value_step=1}
    settings_flow2.add{type="label", name="Wagons_value_label", caption=tostring(global.Wagons_value or 4)}

	settings_flow2.add{type="label", name="TestRuns_label", caption="Number of Test Runs:"}
    local TestRuns_slider = settings_flow2.add{type="slider", name="TestRuns_slider", minimum_value=1, maximum_value=100, value=global.TestRuns_value or 1, value_step=1}
    settings_flow2.add{type="label", name="TestRuns_value_label", caption=tostring(global.TestRuns_value or 1)}
	-- Add "Apply" Button to settings_flow2
    settings_flow2.add{type="button", name="apply_button", caption="Apply"}
end


function run_test()
	 global.TestRuns_counter = global.TestRuns_counter or 0
    if global.TestRuns_counter > 0 then
	
        global.TestRuns_counter = global.TestRuns_counter - 1  -- Reduce the counter
    end
end


function populate_train_stops(surface)
  global.train_stops_data = {}  -- Initialize the global table
  local train_stops = surface.find_entities_filtered({type = "train-stop"})
  for _, train_stop in pairs(train_stops) do
    local position = train_stop.position
    local direction = train_stop.direction  -- Get the direction of the train stop
    local closest_signal = surface.find_entities_filtered({
      type = "rail-signal",
      area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}},
      limit = 1
    })[1]
    
    local closest_signal_position = closest_signal and closest_signal.position or nil
    table.insert(global.train_stops_data, {
      x = position.x, 
      y = position.y, 
      direction = direction,  -- Include the direction
      closest_signal = closest_signal_position, 
    })
  end
end


-- Function to delete all trains on a given surface
function delete_all_trains(surface)
  for _, train in pairs(surface.get_trains()) do
    for _, carriage in pairs(train.carriages) do
      carriage.destroy()
    end
  end
end

-- Function to get the opposite direction of a train
function oppositeDirection(direction)
  return (direction + 4) % 8
end
-- Function to get a schedule by its name


function spawnTrainAtStationWithSchedule(stationName, numFrontLoco, numBackLoco, numCargoWagons, numFluidWagons)
  -- Convert to numbers, default to 0 if nil
  numFrontLoco = numFrontLoco or 0
  numBackLoco = numBackLoco or 0
  numCargoWagons = numCargoWagons or 0
  numFluidWagons = numFluidWagons or 0

  -- Find the train stops by name
  local surface = game.surfaces[1]
  local stations = game.get_train_stops{name = stationName}

  if #stations == 0 then
    log("No station found with the name: " .. stationName)
    return
  end

  -- Loop through each station with the given name
  for _, station in pairs(stations) do
    local connectedRail = station.connected_rail
    local stationDirection = station.direction

    local firstLocoCreated = false  -- Flag to track if the first locomotive was created
    local firstFrontLoco  -- Local variable to replace global.firstFrontLoco

    if connectedRail and connectedRail.trains_in_block == 0 then
      firstFrontLoco = surface.create_entity{
        name = "locomotive",
        position = connectedRail.position,
        direction = stationDirection,
        force = "player"
      }
      addFuelToLocomotive(firstFrontLoco)
      firstLocoCreated = true  -- Set the flag to true
    else
    end

    local delta = {x = 0, y = 0}

    if firstLocoCreated then
      local lastPosition = firstFrontLoco.position

      -- Set delta based on stationDirection
      if stationDirection == 0 then
        delta.y = 7
      elseif stationDirection == 2 then
        delta.x = -7
      elseif stationDirection == 4 then
        delta.y = -7
      elseif stationDirection == 6 then
        delta.x = 7
      end

    for i = 2, numFrontLoco do
      local newPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
      local newLoco = surface.create_entity{
        name = "locomotive",
        position = newPosition,
        direction = stationDirection,
        force = "player"
      }
      addFuelToLocomotive(newLoco)
      lastPosition = newPosition
    end

    for i = 1, numCargoWagons do
      local newPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
      local newWagon = surface.create_entity{
        name = "cargo-wagon",
        position = newPosition,
        direction = stationDirection,
        force = "player"
      }
      lastPosition = newPosition
    end

    for i = 1, numFluidWagons do
      local newPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
      local newFluidWagon = surface.create_entity{
        name = "fluid-wagon",
        position = newPosition,
        direction = stationDirection,
        force = "player"
      }
      lastPosition = newPosition
    end

    for i = 1, numBackLoco do
		local newPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
		if stationDirection > 3 then 
		backlocodirection = stationDirection - 4
		elseif stationDirection < 4 then 
		backlocodirection = stationDirection + 4
		end
      local newBackLoco = surface.create_entity{
        name = "locomotive",
        position = newPosition,
        direction = backlocodirection,
        force = "player"
      }
      addFuelToLocomotive(newBackLoco)
      lastPosition = newPosition
    end

    local schedule = create_schedule(stationName)

      if schedule then
        local train = firstFrontLoco.train  -- Use the first front loco to get the train
        train.schedule = {current = 1, records = {{station = schedule}}}
        train.manual_mode = false
		train.speed = 290
		
      else
        log("No schedule found with the name: " .. scheduleName)
      end
    end
  end
end

-- Global State

function find_Output_trainstops()
    local all_train_stops = game.surfaces[1].find_entities_filtered{type="train-stop"}
    local stops = {}
    local Output_stops = {}  -- New table for filtered stops

    for _, stop in pairs(all_train_stops) do
        local stop_data = {
            direction = stop.direction,
            coordinates = stop.position,
            name = stop.backer_name
        }
        table.insert(stops, stop_data)
    end

    for _, stop in pairs(stops) do
        if string.find(stop.name, "Output") then
            table.insert(Output_stops, stop)  -- Add matching stops to the new table
        end
    end

    global.output_trainstops = Output_stops
end

function find_railsignals_and_make_groups()
    for _, train_stop in pairs(global.output_trainstops) do
        local signals_in_radius = game.surfaces[1].find_entities_filtered{
            type = "rail-signal",
            area = {
                {train_stop.coordinates.x - 2, train_stop.coordinates.y - 2},
                {train_stop.coordinates.x + 2, train_stop.coordinates.y + 2}
            }
        }

        for _, signal in pairs(signals_in_radius) do
            local signal_entity = game.surfaces[1].find_entity("rail-signal", signal.position)
            local signal_state = "open"
            if signal_entity then
                signal_state = signal_entity.signal_state  -- Fetching the actual state using the provided definition
            end

            table.insert(global.importantrailsignals, {
                coordinates = signal.position,
                direction = train_stop.direction,
                state = signal_state
            })
        end
    end

    table.sort(global.importantrailsignals, function(a, b)
        return a.direction < b.direction
    end)
end

function check_state_and_update_table()
    local updated_signals = {}

    for _, rail_signal_data in pairs(global.importantrailsignals) do
        local x = rail_signal_data.coordinates.x
        local y = rail_signal_data.coordinates.y
        local state_description = read_signal_state_at_coordinates(x, y)
        -- Convert state description back to the corresponding enum value
        local newState = nil
        if state_description == "Closed (Red)" then
            newState = "closed"
        elseif state_description == "Reserved (Orange)" then
            newState = "reserved"
        end

        -- Only update the state if newState is not nil and not 0
        if newState and newState ~= "Open (green)" then
            rail_signal_data.state = newState
        end

        table.insert(updated_signals, rail_signal_data)
    end

    global.importantrailsignals = updated_signals
end



function RHT_or_LHT_based_on_signal_state()
    -- Step 1: Determine the Min/Max Values for Each Group
    local minX = { [0] = math.huge, [2] = math.huge, [4] = math.huge, [6] = math.huge }
    local maxX = { [0] = -math.huge, [2] = -math.huge, [4] = -math.huge, [6] = -math.huge }
    local minY = { [0] = math.huge, [2] = math.huge, [4] = math.huge, [6] = math.huge }
    local maxY = { [0] = -math.huge, [2] = -math.huge, [4] = -math.huge, [6] = -math.huge }
	global.RHT = 0

    for _, rail_signal_data in pairs(global.importantrailsignals) do
        local dir = rail_signal_data.direction
        minX[dir] = math.min(minX[dir], rail_signal_data.coordinates.x)
        maxX[dir] = math.max(maxX[dir], rail_signal_data.coordinates.x)
        minY[dir] = math.min(minY[dir], rail_signal_data.coordinates.y)
        maxY[dir] = math.max(maxY[dir], rail_signal_data.coordinates.y)
    end

    -- Step 2: Compare Individual Signals to the Min/Max Values
    for _, rail_signal_data in pairs(global.importantrailsignals) do
        local dir = rail_signal_data.direction
        if dir == 0 and rail_signal_data.coordinates.x == minX[dir] then
            if rail_signal_data.state == defines.signal_state.closed then
                global.RHT = global.RHT + 1
            elseif rail_signal_data.state == defines.signal_state.reserved then
                global.RHT = global.RHT - 1
            end
        elseif dir == 2 and rail_signal_data.coordinates.y == minY[dir] then
            if rail_signal_data.state == defines.signal_state.closed then
                global.RHT = global.RHT + 1
            elseif rail_signal_data.state == defines.signal_state.reserved then
                global.RHT = global.RHT - 1
            end
        elseif dir == 4 and rail_signal_data.coordinates.x == maxX[dir] then
            if rail_signal_data.state == defines.signal_state.closed then
                global.RHT = global.RHT + 1
            elseif rail_signal_data.state == defines.signal_state.reserved then
                global.RHT = global.RHT - 1
            end
        elseif dir == 6 and rail_signal_data.coordinates.y == maxY[dir] then
            if rail_signal_data.state == defines.signal_state.closed then
                global.RHT = global.RHT + 1
            elseif rail_signal_data.state == defines.signal_state.reserved then
                global.RHT = global.RHT - 1
            end
        end
    end
end

function check_4ways_or_3ways()
    -- Initialize global.ways to 0
    global.ways = 0
    -- Loop through the four groups by direction
    local groups = {0, 2, 4, 6}  -- Array of desired values

	for _, dir in pairs(groups) do  -- Loops for directions: 0, 2, 4, 6
		local found_non_zero_or_nil = false

		for _, rail_signal_data in pairs(global.importantrailsignals) do
			if rail_signal_data.direction== dir then
				-- If signal_state is not 0 or nil
				if rail_signal_data.state ~= 0 and rail_signal_data.state ~= nil then
					found_non_zero_or_nil = true
					break  -- Breaks from the inner loop as soon as one non-zero/nil is found
				end
			end
		end

		-- If any non-zero/nil signal_state was found in the group, increment global.ways
		if found_non_zero_or_nil then
			global.ways = global.ways + 1
		end
	end
end




function create_schedule(stationName)
    local availableStations = {"Output East", "Output West", "Output North", "Output South"}
    local rand = math.random(1, 100)
    local removeMap = {["Spawner East"] = 1, ["Spawner West"] = 2, ["Spawner North"] = 3, ["Spawner South"] = 4}
    local selectedStation = nil

    table.remove(availableStations, removeMap[stationName] or 0)

    local selectMap = {
        [1] = function() return availableStations[math.random(1, #availableStations)] end,
        [2] = function()
            local options = {["Spawner North"] = {"Output South", "Output East", "Output West"},
                             ["Spawner South"] = {"Output West", "Output North", "Output East"},
                             ["Spawner East"] = {"Output South", "Output West", "Output North"},
                             ["Spawner West"] = {"Output North", "Output East", "Output South"}}
            return rand <= 45 and options[stationName][1] or rand <= 90 and options[stationName][2] or options[stationName][3]
        end,
        [3] = function()
            local options = {["Spawner North"] = {"Output East", "Output West", "Output South"},
                             ["Spawner South"] = {"Output West", "Output East", "Output North"},
                             ["Spawner East"] = {"Output South", "Output North", "Output West"},
                             ["Spawner West"] = {"Output North", "Output South", "Output East"}}
            return rand <= 90 and options[stationName][1] or rand <= 95 and options[stationName][2] or options[stationName][3]
        end
    }

    selectedStation = selectMap[global.current_test]()

    return selectedStation
end

-- Function to calculate test score
function calculate_test_score()
  -- Part 1: Calculate the score
  local score = global.despawned_trains / global.M_value
	if global.current_test == 1 then
	global.set1 = score
	global.set2 = 0
	global.set3 = 0
	global.Average = 0
	global.current_test = 2
	elseif global.current_test == 2 then
	global.set2 = score
	global.current_test = 3
	elseif global.current_test == 3 then
	global.set3 = score
	global.Average = string.format("%.2f", (global.set1 + global.set2 + global.set3) / 3)
	global.current_test = 1
	game.print("global.set1: " .. global.set1 .. ", global.set2: " .. global.set2 .. ", global.set3: " .. global.set3 .. ", global.Average: " .. global.Average)
	log("global.set1: " .. global.set1 .. ", global.set2: " .. global.set2 .. ", global.set3: " .. global.set3 .. ", global.Average: " .. global.Average)
	end
	global.despawned_trains = 0
end

function addFuelToLocomotive(loco)
	if loco ~= nil then
	local fuelInventory = loco.burner.inventory
	fuelInventory.insert({name = "nuclear-fuel", count = 1})  -- Insert 50 units of coal
	end
end

-- Helper function to recursively find and update a label
function update_label(element, label_name, new_caption)
	if not element then return false end  -- Check if element is valid
    if element.name == label_name then
        element.caption = new_caption
        return true
    end
    for _, child in pairs(element.children) do
        if update_label(child, label_name, new_caption) then
            return true
        end
    end
    return false
end


if defines and defines.events and defines.events.on_load then
    script.on_event(defines.events.on_load, function(event)
        -- Destroy and recreate the GUI for each player
        for _, player in pairs(game.players) do
            destroy_GUI(player)
            create_main_frame(player)
        end
    end)
end


-- Function to update labels based on global variables
function update_labels_from_globals()
    for _, player in pairs(game.players) do
        local parent_frame = player.gui.screen.parent_frame
        if parent_frame then  -- Check if parent_frame exists
            
            local horizontal_frame = parent_frame.horizontal_frame
            if horizontal_frame then  -- Check if horizontal_frame exists

                
                local inner_frame2 = horizontal_frame.inner_frame2
                if inner_frame2 then  -- Check if inner_frame2 exists

                    
                    -- Fetch values from global variables
                    local set1_score = string.format("%.2f", global.set1)
                    local set2_score = string.format("%.2f", global.set2)
                    local set3_score = string.format("%.2f", global.set3)
                    local total_score = string.format("%.2f",global.Average)
                    local current_set = global.current_test or "N/A"
                    local test_timer = global.testtimer or 0
                    local tpm_value = string.format("%.2f", global.despawned_trains / (global.testtimer / 60))
                    
                    -- Update labels
                    update_label(inner_frame2, "set1_label", "Set 1: " .. set1_score)
                    update_label(inner_frame2, "set2_label", "Set 2: " .. set2_score)
                    update_label(inner_frame2, "set3_label", "Set 3: " .. set3_score)
                    update_label(inner_frame2, "score_label", "Score: " .. total_score)
                    update_label(inner_frame2, "current_set_label", "Current Set: " .. current_set)
                    update_label(inner_frame2, "current_time_running_label", "Test Timer: " .. test_timer)
                    update_label(inner_frame2, "current_tpm_label", "TPM: " .. tpm_value)
                else
                    log("Debug: inner_frame2 does not exist")
                end
            else
                log("Debug: horizontal_frame does not exist")
            end
        else
            log("Debug: parent_frame does not exist")
        end
    end
end

-- Function to spawn trains at spawner stations
function start_spawning_trains() 
  local spawner_stations = {"Spawner North", "Spawner West", "Spawner East", "Spawner South"}
  for _, station in pairs(spawner_stations) do
    spawnTrainAtStationWithSchedule(station, global.Loco_value, 0, global.Wagons_value, 0)
  end
end



script.on_event(defines.events.on_tick, function(event)
    -- Increment the counter
    global.counter = global.counter + 1
    if global.testbench_running==true then
		if global.current_set == 1 then
			if global.testtimer > 10 and global.testtimer < 60 then
				check_state_and_update_table()
			end
		end
	end
	
    if global.counter >= global.tpmtick and global.testbench_running == true then
        -- Call the function to start spawning trains
        start_spawning_trains()
        
        -- Reset the counter
        global.counter = 0
    end
end)

-- Event handler for every 60th tick
script.on_nth_tick(60, function(event)
    local player = game.players[1]
    local parent_frame = player.gui.screen["parent_frame"]
    local inner_frame1 = parent_frame and parent_frame.horizontal_frame.inner_frame1
	update_labels_from_globals()

    global.sec = global.sec + 1
    update_labels_from_globals()
    
    if global.testbench_running == true then
        if global.despawned_trains > 0 then 
            global.testtimer = global.testtimer + 1
        end
		if global.testtimer == 60 then 
			    if global.importantrailsignals then
					for key, value in pairs(global.importantrailsignals) do
					local description = "Key: " .. tostring(key) .. ", Value: " .. serpent.line(value)
					end
				end
			check_4ways_or_3ways()
			RHT_or_LHT_based_on_signal_state()
			local waysDescription = "Value of global.ways: " .. tostring(global.ways)
			local RHTDescription = "Value of global.RHT: " .. tostring(global.RHT)
			game.print(waysDescription)
			game.print(RHTDescription)
			end
			
        if global.testtimer >= global.M_value * 60 then
            global.testbench_running = false
            delete_all_trains(player.surface)
            global.testtimer = 0
            if global.current_test < 3 then
                global.testbench_running = true
            elseif global.current_test == 3 then
                run_test()
                
                if global.TestRuns_counter == nil then
                    global.TestRuns_counter = 0  -- Initialize it if it's nil
                end
                
                if global.TestRuns_counter == 0 then
                    if inner_frame1 then  -- Check if inner_frame1 is not nil
                        local start_button = inner_frame1.start_button
                        if start_button and start_button.sprite == "stop_button_sprite" then
                            start_button.sprite = "start_button_sprite"
                        end
                    else
                        log("Debug: inner_frame1 is nil")
                    end
                elseif global.TestRuns_counter > 0 then
                    global.testbench_running = true	
                end
            end
			calculate_test_score()
        end
    elseif global.test_running == false then
        global.testtimer = 0
    end
end)


script.on_event(defines.events.on_train_changed_state, function(event)
    local train = event.train
    if train.state == defines.train_state.arrive_station then
        -- Delete all carriages in the train
        for _, carriage in pairs(train.carriages) do
            carriage.destroy()
        end
        global.despawned_trains = global.despawned_trains + 1
        if global.despawned_trains == 1 then 
            global.testtimer = 0
        end
    end
end)




-- Event handler for button clicks
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element
    local surface = player.surface
    local inner_frame1 = player.gui.screen.parent_frame.horizontal_frame.inner_frame1

    if element.name == "reset_values_button" then
        local frame = player.gui.screen["settings_frame"]
        if frame then
            local main_flow = frame["main_flow"]
            if main_flow then
                local settings_flow = main_flow["settings_flow"]
                if settings_flow then
                    local M_slider = settings_flow["M_slider"]
                    local TPM_slider = settings_flow["TPM_slider"]

                    if M_slider and M_slider.valid and M_slider.type == "slider" then
                        M_slider.slider_value = 15
                    end

                    if TPM_slider and TPM_slider.valid and TPM_slider.type == "slider" then
                        TPM_slider.slider_value = 2900 / 100
                    end

                    -- Update global variables
                    global.M_value = 15
                    global.TPM_value = 2900

                    -- Update labels
                    if settings_flow.M_value_label then
                        settings_flow.M_value_label.caption = "15 Min"
                    end

                    if settings_flow.TPM_value_label then
                        settings_flow.TPM_value_label.caption = string.format("%.2f", 2900 / 100)
                    end
                end
            end
        end
    end
	
    if event.element.name == "apply_button" then
        -- Only apply changes if the testbench is not running or is done
        if global.testbench_running == false then
            if global.temp_slider_values then  -- Check if temp_slider_values is not nil
                for key, value in pairs(global.temp_slider_values) do
                    global[key] = value
                end
                -- Clear the temporary table
                global.temp_slider_values = {}
            else
                log("temp_slider_values is nil")
            end
        end
    end
	
 if event.element.name == "apply_button" then
        -- Only apply changes if the testbench is not running or is done
        if global.testbench_running == false then
            for key, value in pairs(global.temp_slider_values) do
                global[key] = value
            end
            -- Clear the temporary table
            global.temp_slider_values = {}
        end
    end

    if element.name == "speed_up_button" then
        if element.sprite == "speed_down_button_sprite" then
            element.sprite = "speed_up_button_sprite"
            if game.speed > 1 then
                game.speed = 1
            end
        elseif element.sprite == "speed_up_button_sprite" then
            element.sprite = "speed_down_button_sprite"
            if game.speed < 200 then
                game.speed = 200
            end
        end
    end
	
	if element.name == "start_button" then
        local start_button = inner_frame1.start_button
		local player = game.players[1]
        if element.sprite == "start_button_sprite" then
            element.sprite = "stop_button_sprite"
			delete_all_trains(player.surface)
			global.current_test = 1
			global.testrunning = true
			global.testtimer = 0
			global.sec = 0
			global.despawned_trains = 0
            global.TestRuns_counter = global.TestRuns_value
			global.tpmtick = 360000/global.TPM_value
			global.set1 = 0
			global.set2 = 0
			global.set3 = 0
			global.Average = 0
			global.output_trainstops = {}
			global.importantrailsignals = {}
			find_Output_trainstops()
			find_railsignals_and_make_groups()
			

            if global.auto_mode == true then
                global.testbench_running = true
            end
        else
            element.sprite = "start_button_sprite"
            global.testbench_running = false
			delete_all_trains(player.surface)
        end
    end

    if element.name == "reset_button" then
        local start_button = inner_frame1.start_button
        if start_button and start_button.valid then
            if start_button.sprite == "stop_button_sprite" then
                start_button.sprite = "start_button_sprite"
                global.testbench_running = false
            end
        end
    end

    if element.name == "auto_button" then
        local auto_button = inner_frame1.auto_button
        if element.sprite == "auto_button_sprite" then
            global.auto_mode = true
            element.sprite = "manual_button_sprite"
        elseif element.sprite == "manual_button_sprite" then
            global.auto_mode = false
            element.sprite = "auto_button_sprite"
        end
    end

    if element.name == "settings_button" then
        if player.gui.screen["settings_frame"] then
            player.gui.screen["settings_frame"].destroy()
        else
            create_settings_frame(player)
        end
    end

    if element.name == "close_settings" then
        if player.gui.screen["settings_frame"] then
            player.gui.screen["settings_frame"].destroy()
        end
    end
end)


-- Initialize global.temp_slider_values if it doesn't exist
if not global.temp_slider_values then
    global.temp_slider_values = {}
end

-- Event handler for slider value change
script.on_event(defines.events.on_gui_value_changed, function(event)
    local player = game.players[event.player_index]
    local element = event.element

    if player.gui.screen["settings_frame"] then
        local frame = player.gui.screen["settings_frame"]
        local main_flow = frame["main_flow"]
        local settings_flow = main_flow["settings_flow"]
        local settings_flow2 = main_flow["settings_flow2"]

        local slider_config = {
            ["M_slider"] = {global_var="M_value", label="M_value_label", flow=settings_flow, index=7, suffix=" Min"},
            ["Loco_slider"] = {global_var="Loco_value", label="Loco_value_label", flow=settings_flow2, index=8},
            ["Wagons_slider"] = {global_var="Wagons_value", label="Wagons_value_label", flow=settings_flow2, index=9},
            ["TPM_slider"] = {global_var="TPM_value", label="TPM_value_label", flow=settings_flow, index=10, scale=100},
            ["TestRuns_slider"] = {global_var="TestRuns_value", label="TestRuns_value_label", flow=settings_flow2, index=11}
        }

        local config = slider_config[element.name]
        if config then
            local value = tonumber(element.slider_value)
            if config.scale then value = math.floor(value * config.scale + 0.5) end

            -- Store the value in the temporary table instead of updating the global variable
            global.temp_slider_values[config.global_var] = value

            local caption_value = config.scale and string.format("%.2f", value / config.scale) or tostring(value)
            if config.suffix then caption_value = caption_value .. config.suffix end

            if config.flow[config.label] then
                config.flow[config.label].caption = caption_value
            end
        end
    end
end)


commands.add_command("print_globals", "Print global variables", function()
    game.print("M_value: " .. tostring(global.M_value))
    game.print("Loco_value: " .. tostring(global.Loco_value))
    game.print("TPM_value: " .. tostring(global.TPM_value))
    game.print("Wagons_value: " .. tostring(global.Wagons_value))
end)
