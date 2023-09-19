
function create_main_frame(player)
    -- 1. Window Creation:
    local window = player.gui.screen.add{
        type = "frame",
        name = "new_window",
        caption = "",  -- Empty caption since we'll be adding a custom titlebar
        direction = "vertical"
    }
    window.auto_center = true  -- Center the window on the screen

    -- 2. Titlebar:
    local titlebar_flow = window.add{
        type = "flow",
        direction = "horizontal",
        name = "titlebar_flow"
    }
    titlebar_flow.drag_target = window

    -- Drag handle for the titlebar
    local drag_handle = titlebar_flow.add{
        type = "empty-widget",
        style = "draggable_space_header",
        ignored_by_interaction = true
    }
    drag_handle.style.horizontally_stretchable = true
    drag_handle.style.height = 24
    drag_handle.style.right_margin = 4

    -- Title text
    local title_label = titlebar_flow.add{
        type = "label",
        caption = "Control Panel",
        style = "frame_title",
        ignored_by_interaction = true
    }

    -- Spacer to push the close button to the right
    local spacer = titlebar_flow.add{
        type = "empty-widget",
        style = "draggable_space_header"
    }
    spacer.style.horizontally_stretchable = true
		-- Settings button (before the close button)
	local settings_button = titlebar_flow.add{
		type = "sprite-button",
		style = "frame_action_button",
		name = "settings_button"
	}

	local close_button = titlebar_flow.add{
    type = "sprite-button",
    sprite = "utility/close_white",
    style = "frame_action_button",
    name = "close_button"
	}

    -- 3. Content Frame:

	local padded_content_frame = window.add{
		type = "frame",
		direction = "vertical",
		style = "inside_shallow_frame_with_padding",
		name = "padded_content_frame"
	}

	local content_flow = padded_content_frame.add{
		type = "flow",
		direction = "horizontal",
		name = "content_flow"
	}

    -- Vertical flow for existing labels
    local existing_labels_flow = content_flow.add{
        type = "flow",
        direction = "vertical",
        name = "existing_labels_flow"
    }

	local info_labels = {
		"Timerunning 0sec 0min", "Set: 1", "tpm", "set 1:", "set 2:", "set 3:", "score:"
	}
	for index, label in pairs(info_labels) do
		existing_labels_flow.add{
			type = "label",
			caption = label,
			name = "label_" .. index  -- Assign a unique name to each label
		}
	end

    -- Vertical flow for new labels with orange text
	local new_labels_flow = content_flow.add{
		type = "flow",
		direction = "vertical",
		name = "new_labels_flow"
	}

	local new_labels_values = {
		{description = "Train", value = global.Loco_value .. " - " .. global.Wagons_value},
		{description = "Ways", value = global.Ways},
		{description = "Testtime:", value = global.M_value}
	}

	for _, pair in pairs(new_labels_values) do
		local label_flow = new_labels_flow.add{
			type = "flow",
			direction = "horizontal"
		}
		
		-- Description label
		label_flow.add{
			type = "label",
			caption = pair.description
		}
		
		-- Value label with orange text
		local value_label = label_flow.add{
			type = "label",
			caption = tostring(pair.value)
		}
		value_label.style.font_color = {r = 1, g = 0.5, b = 0}  -- Orange color
	end
	
    -- 4. Dialog Row:
    local dialog_row = window.add{
        type = "flow",
        direction = "horizontal",
        name = "dialog_row"
    }

    -- Back button (leftmost side)
    local speed_button = dialog_row.add{
        type = "button",
        name = "speed_button",
        caption = "Speed",
        style = "button"  -- Factorio's back button style
    }

    -- Spacer to push the Confirm button to the right
    local spacer = dialog_row.add{
        type = "empty-widget",
        style = "draggable_space_header"
    }
    spacer.style.horizontally_stretchable = true

    -- Confirm button (rightmost side)
    local confirm_button = dialog_row.add{
        type = "button",
        name = "start_button",
        caption = "Start/Stop",
        style = "confirm_button"  -- Factorio's confirm button style
    }
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
	global.TPM_value = global.TPM_value or 2900
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
	global.tpmtick = global.tpmtick or 0
	global.temp_values = {
    locomotives = global.Loco_value,
    wagons = global.Wagons_value,
    tpm = global.TPM_value,
    test_runs = global.TestRuns_value
	}
	
	

    for i, player in pairs(game.players) do
        if player and player.valid then
            destroy_GUI(player)  -- Pass player as an argument
            create_main_frame(player)
		end
    end
end)

script.on_init(function()
    global.temp_slider_values = global.temp_slider_values or {}
end)

function destroy_GUI(player)
    if player.gui.screen["new_window"] then
        player.gui.screen["new_window"].destroy()
    end
    if player.gui.screen["parent_frame"] then
        player.gui.screen["parent_frame"].destroy()
    end
end

function read_signal_state_at_coordinates(x, y)
    local signal_entity = game.surfaces[1].find_entity("rail-signal", {x, y})
    local state_description = nil  -- Initialize state_description to nil

    if signal_entity then
        local state_enum = signal_entity.signal_state

        if state_enum == defines.signal_state.closed then
            state_description = "Closed (Red)"
        elseif state_enum == defines.signal_state.reserved then
            state_description = "Reserved (Orange)"
        -- Only set to "Open (Green)" if not previously reserved
        elseif state_enum == defines.signal_state.open and state_description ~= "Reserved (Orange)" then
            state_description = "Open (Green)"
        end

        return state_description
    end
end

function reset_temp_values()
    global.temp_values.locomotives = global.locomotives
    global.temp_values.wagons = global.wagons
    global.temp_values.tpm = global.tpm
    global.temp_values.test_runs = global.test_runs
end

function close_settings_window(player)
    if player.gui.screen.settings_window then
        player.gui.screen.settings_window.destroy()
    end
    reset_temp_values()
end

function create_settings_frame(player)
    -- 1. Window Creation:
    local window = player.gui.screen.add{
        type = "frame",
        name = "settings_window",
        direction = "vertical"
    }
    window.auto_center = true  -- Center the window on the screen

    -- 2. Titlebar:
    local titlebar_flow = window.add{
        type = "flow",
        direction = "horizontal",
        name = "titlebar_flow"
    }
    titlebar_flow.drag_target = window

    -- Title text
    local title_label = titlebar_flow.add{
        type = "label",
        caption = "Settings",
        style = "frame_title",
        ignored_by_interaction = true
    }

    -- Drag handle for the titlebar
    local drag_handle = titlebar_flow.add{
        type = "empty-widget",
        style = "draggable_space_header",
        ignored_by_interaction = true
    }
    drag_handle.style.horizontally_stretchable = true
    drag_handle.style.height = 24
    drag_handle.style.right_margin = 4

    -- Spacer to push the close button to the right
    local title_spacer = titlebar_flow.add{
        type = "empty-widget",
        style = "draggable_space_header"
    }
    title_spacer.style.horizontally_stretchable = true

    local close_button = titlebar_flow.add{
        type = "sprite-button",
        sprite = "utility/close_white",
        style = "frame_action_button",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black"
    }

    -- 3. Content Frame:
    local content_frame = window.add{
        type = "frame",
        name = "content_frame",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }

    -- Sliders and their corresponding texts
    local sliders = {
        {name="locomotives_slider", caption="Locomotives:", min=1, max=10, value=global.Loco_value},
        {name="wagons_slider", caption="Wagons:", min=0, max=12, value=global.Wagons_value},
        {name="tpm_slider", caption="Train per min goal:", min=1, max=33, value = global.TPM_value / 100},
        {name="test_runs_slider", caption="Number of Tests Runs:", min=1, max=20, value=global.TestRuns_value}
    }

    for _, slider in pairs(sliders) do
        local slider_flow = content_frame.add{
            type = "flow",
            direction = "horizontal",
            name = slider.name .. "_flow"
        }
        local slider_element = slider_flow.add{
            type = "slider",
            name = slider.name,
            minimum_value = slider.min,
            maximum_value = slider.max,
            value = slider.value
        }

        slider_flow.add{
            type = "label",
            caption = slider.caption
        }

        -- Add a label to display the current value of the slider
        slider_flow.add{
            type = "label",
            name = slider.name .. "_value_label",
            caption = tostring(slider.value)
        }
    end

    -- Dropdown
    local dropdown = content_frame.add{
        type = "drop-down",
        items = {"Short(15min)", "Medium(90min)", "Long(240min)"}
    }

    -- 4. Dialog Row:
    local dialog_row = window.add{
        type = "flow",
        direction = "horizontal",
        name = "dialog_row"
    }

    -- Back button (leftmost side)
    local back_button = dialog_row.add{
        type = "button",
        name = "back_button",
        caption = "Back",
        style = "back_button"
    }

    -- Spacer to push the Confirm button to the right
    local dialog_spacer = dialog_row.add{
        type = "empty-widget",
        style = "draggable_space_header"
    }
    dialog_spacer.style.horizontally_stretchable = true

    -- Confirm button (rightmost side)
    local confirm_button = dialog_row.add{
        type = "button",
        name = "confirm_button_settings",
        caption = "Confirm",
        style = "confirm_button"  -- Factorio's confirm button style
    }
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


function delete_all_trains(surface)
  for _, train in pairs(surface.get_trains()) do
    for _, carriage in pairs(train.carriages) do
      carriage.destroy()
    end
  end
end


function oppositeDirection(direction)
  return (direction + 4) % 8
end

function sliderchange()
	global.temp_values[slider.name] = event.element.value
end

local spawnPositions = {}

function populateSpawnPositions()
    spawnPositions = {}

    -- Get all train stops in the game
    local allStations = game.get_train_stops()

    for _, station in pairs(allStations) do
        local stationName = station.backer_name  -- Get the name of the station
        local connectedRail = station.connected_rail  -- Get the connected rail

        -- Initialize the table for this station name if it doesn't exist
        if not spawnPositions[stationName] then
            spawnPositions[stationName] = {}
        end

        -- Store the position of the connected rail and the direction of the station
        if connectedRail then
            table.insert(spawnPositions[stationName], {
                position = connectedRail.position,
                direction = station.direction
            })
        end
    end
end



function spawnTrainAtStationWithSchedule(stationName)
    if not trainComponents then
        log("Train components not initialized. Call initializeTrainComponents first.")
        return
    end
    local spawnData = spawnPositions[stationName]
    if not spawnData or #spawnData == 0 then
        return
    end
    local surface = game.surfaces[1]
    local createEntity = surface.create_entity
    local deltaMap = {
        [0] = {x = 0, y = 7},
        [2] = {x = -7, y = 0},
        [4] = {x = 0, y = -7},
        [6] = {x = 7, y = 0}
    }

    for _, data in pairs(spawnData) do
        local position = data.position
        local direction = data.direction
        local connectedRail = surface.find_entity("straight-rail", position)
        local delta = deltaMap[direction] or {x = 0, y = 0}

        if connectedRail and connectedRail.trains_in_block == 0 then
            local lastPosition = connectedRail.position
            local firstFrontLoco

            for _, component in ipairs(trainComponents) do
                local entity = createEntity{
                    name = component,
                    position = lastPosition,
                    direction = direction,
                    force = "player"
                }
                if component == "locomotive" then
                    addFuelToLocomotive(entity)
                    if not firstFrontLoco then
                        firstFrontLoco = entity
                    end
                end
                lastPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
            end

            local schedule = create_schedule(stationName)
            if schedule and firstFrontLoco then
                local train = firstFrontLoco.train
                train.schedule = {current = 1, records = {{station = schedule}}}
                train.manual_mode = false
                train.speed = 290
            elseif not schedule then
                log("No schedule found with the name: " .. scheduleName)
            end
        end
    end
end


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
            local x = signal.position.x
            local y = signal.position.y
            local state_description = read_signal_state_at_coordinates(x, y)

            -- Convert state description back to the corresponding enum value
            local signal_state = nil
            if state_description == "Closed (Red)" then
                signal_state = "closed"
            elseif state_description == "Reserved (Orange)" then
                signal_state = "reserved"
            else
                signal_state = "open"
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
	local importantrailsignals = global.importantrailsignals

    for _, rail_signal_data in pairs(importantrailsignals) do
        local x = rail_signal_data.coordinates.x
        local y = rail_signal_data.coordinates.y
        local state_description = read_signal_state_at_coordinates(x, y)
        local newState = rail_signal_data.state  -- Default to unchanged state
        if state_description == "Closed (Red)" then
            newState = "closed"
        elseif state_description == "Reserved (Orange)" then
            newState = "reserved"
        elseif state_description == "Open (Green)" and rail_signal_data.state ~= "reserved" and rail_signal_data.state ~= "closed" then
            newState = "open"
        end

        rail_signal_data.state = newState

        table.insert(updated_signals, rail_signal_data)
    end

    global.importantrailsignals = updated_signals
end


function RHT_or_LHT_based_on_signal_state()
    global.RHT = 0

    -- Sort signals based on their coordinates for each direction
    local sortedSignals = {
        [0] = {},  -- North
        [2] = {},  -- East
        [4] = {},  -- South
        [6] = {}   -- West
    }

    for _, rail_signal_data in pairs(global.importantrailsignals) do
        table.insert(sortedSignals[rail_signal_data.direction], rail_signal_data)
    end

    -- Sort each direction's signals based on their coordinates
    table.sort(sortedSignals[0], function(a, b) return a.coordinates.x < b.coordinates.x end)  -- North
    table.sort(sortedSignals[2], function(a, b) return a.coordinates.y < b.coordinates.y end)  -- East
    table.sort(sortedSignals[4], function(a, b) return a.coordinates.x > b.coordinates.x end)  -- South
    table.sort(sortedSignals[6], function(a, b) return a.coordinates.y > b.coordinates.y end)  -- West

    -- Determine RHT or LHT based on the first signal that is either "reserved" or "closed"
    for dir, signals in pairs(sortedSignals) do
        for _, rail_signal_data in ipairs(signals) do
            if rail_signal_data.state == "closed" or rail_signal_data.state == "reserved" then
                if dir == 0 and rail_signal_data.state == "closed" then
                    global.RHT = global.RHT + 1
                elseif dir == 0 and rail_signal_data.state == "reserved" then
                    global.RHT = global.RHT - 1
                elseif dir == 2 and rail_signal_data.state == "closed" then
                    global.RHT = global.RHT + 1
                elseif dir == 2 and rail_signal_data.state == "reserved" then
                    global.RHT = global.RHT - 1
                elseif dir == 4 and rail_signal_data.state == "closed" then
                    global.RHT = global.RHT + 1
                elseif dir == 4 and rail_signal_data.state == "reserved" then
                    global.RHT = global.RHT - 1
                elseif dir == 6 and rail_signal_data.state == "closed" then
                    global.RHT = global.RHT + 1
                elseif dir == 6 and rail_signal_data.state == "reserved" then
                    global.RHT = global.RHT - 1
                end
				if global.RHT <0 then 
					global.trafficType = 2
				end
                break
            end
        end
    end
end

function check_4ways_or_3ways()
    global.ways = 0
	
    local groups = {0, 2, 4, 6}
    for _, dir in pairs(groups) do
        local found_not_open = false

        for _, rail_signal_data in pairs(global.importantrailsignals) do
            if rail_signal_data.direction == dir then
				log("Checking rail signal at direction " .. dir .. " with state " .. rail_signal_data.state)

                if rail_signal_data.state ~= "open" then
                    found_not_open = true
                    break
                end
            end
        end
        if found_not_open then
            global.ways = global.ways + 1
        end
    end
end


function create_schedule(stationName)
    local rand = math.random(1, 1000)
    local trafficType = global.trafficType or 1  -- Default to 1 (RHT) if nil
    local trafficTypeStr = (trafficType == 1) and "RHT" or "LHT"

    local function getOutputForRand(randValue, outputs)
        if randValue <= 475 then
            return outputs[1]
        elseif randValue <= 900 or randValue <= 950 then
            return outputs[2]
        else
            return outputs[3]
        end
    end

    local function getStationOutput(trafficType, testType, station)
        local commonMap = {
            ["Spawner North"] = {"Output East", "Output West", "Output South"},
            ["Spawner South"] = {"Output East", "Output West", "Output North"},
            ["Spawner East"]  = {"Output North", "Output West", "Output South"},
            ["Spawner West"]  = {"Output North", "Output East", "Output South"}
        }

        if testType == 1 then
            return commonMap[station]
        end

        local rhtMap = {
            ["Spawner North"] = {"Output South", "Output East", "Output West"},
            ["Spawner South"] = {"Output North", "Output West", "Output East"},
            ["Spawner East"] = {"Output West", "Output South", "Output North"},
            ["Spawner West"] = {"Output East", "Output North", "Output South"}
        }

        local lhtMap = {
            ["Spawner North"] = {"Output South", "Output West", "Output East"},
            ["Spawner South"] = {"Output North", "Output East", "Output West"},
            ["Spawner East"] = {"Output West", "Output North", "Output South"},
            ["Spawner West"] = {"Output East", "Output South", "Output North"}
        }

        local selectedMap = (trafficType == "RHT") and rhtMap or lhtMap
        return getOutputForRand(rand, selectedMap[station])
    end

    local selectedStation = getStationOutput(trafficTypeStr, global.current_test, stationName)
	
    if type(selectedStation) == "table" then
        return selectedStation[math.random(#selectedStation)]
    else
        return selectedStation
    end
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
	game.print("Set1: " .. global.set1 .. ", Set2: " .. global.set2 .. ", Set3: " .. global.set3 .. ", Average: " .. global.Average)
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



function update_labels_from_globals()
    for _, player in pairs(game.players) do
        local window = player.gui.screen.new_window
        if window then
            local padded_content_frame = window.padded_content_frame
            if padded_content_frame then
                local content_flow = padded_content_frame.content_flow
                if content_flow then
					local existing_labels_flow = content_flow.existing_labels_flow
					if existing_labels_flow then
						-- Fetch values from global variables
						local set1_score = string.format("%.2f", global.set1)
						local set2_score = string.format("%.2f", global.set2)
						local set3_score = string.format("%.2f", global.set3)
						local total_score = string.format("%.2f", global.Average)
						local current_set = global.current_test or "N/A"
						local tpm_value = string.format("%.2f", global.despawned_trains / (global.testtimer))

						
						-- Update labels
						update_label(existing_labels_flow, "label_1", string.format("Timerunning: %d min.", global.testtimer))
						update_label(existing_labels_flow, "label_2", "Set: " .. current_set)
						update_label(existing_labels_flow, "label_3", "tpm: " .. tpm_value)
						update_label(existing_labels_flow, "label_4", "set 1: " .. set1_score)
						update_label(existing_labels_flow, "label_5", "set 2: " .. set2_score)
						update_label(existing_labels_flow, "label_6", "set 3: " .. set3_score)
						update_label(existing_labels_flow, "label_7", "score: " .. total_score)
					else
					end
				end
            end
        else
            log("cant find new_window")
        end
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


-- Function to spawn trains at spawner stations

function start_spawning_trains()
    local spawner_stations = {"Spawner North", "Spawner West", "Spawner East", "Spawner South"}
    
    -- Cache global values as local variables
    local locoValue = global.Loco_value
    local wagonsValue = global.Wagons_value

    -- Initialize train components based on the cached values
    trainComponents = {}
    for _ = 1, locoValue do table.insert(trainComponents, "locomotive") end
    for _ = 1, wagonsValue do table.insert(trainComponents, "cargo-wagon") end

    -- Now spawn the trains
    for _, station in pairs(spawner_stations) do
        spawnTrainAtStationWithSchedule(station)
    end
end

function delete_trains_with_no_path(surface)
    -- Iterate through all trains on the given surface
    for _, train in pairs(surface.get_trains()) do
        -- Check if the train's pathfinding status is "no path"
        if train.state == defines.train_state.no_path then
            -- Delete each train car in the train
            for _, car in pairs(train.carriages) do
                car.destroy()
            end
        end
    end
end

function createDialogWindow(player)
    local window = player.gui.screen.add{
        type = "frame",
        direction = "vertical",
        style = "frame"  -- Using the default frame style
    }
    window.auto_center = true

    -- Titlebar
    local titlebar = window.add{type="flow", direction="horizontal"}
    titlebar.drag_target = window  -- Make the titlebar the drag target

    -- Add drag handle
    local drag_handle = titlebar.add{type="empty-widget", style="draggable_space_header"}
    drag_handle.style.horizontally_stretchable = true
    drag_handle.style.height = 24
    drag_handle.style.right_margin = 4
    drag_handle.ignored_by_interaction = true

    -- Add title to the titlebar
    local title = titlebar.add{type="label", caption="Results", style="frame_title"}
    title.ignored_by_interaction = true

    -- Content frame
    local content_frame = window.add{type="frame", style="inside_shallow_frame_with_padding"}

    -- First row
    local first_row = content_frame.add{type="flow", direction="vertical"}
    first_row.add{type = "label", caption = "Set 1: " .. string.format("%.2f", global.set1)}
    first_row.add{type = "label", caption = "Set 2: " .. string.format("%.2f", global.set2)}
    first_row.add{type = "label", caption = "Set 3: " .. string.format("%.2f", global.set3)}
    first_row.add{type = "label", caption = "Score: " .. string.format("%.2f", global.Average)}

    -- Second row
    local second_row = content_frame.add{type="flow", direction="vertical"}
    second_row.add{type = "label", caption = tostring(global.ways) .. " Way"}
    local trafficType = global.trafficType or 1  -- Default to 1 (RHT) if nil
    local trafficTypeStr = (trafficType == 1) and "RHT" or "LHT"
    second_row.add{type = "label", caption = trafficTypeStr}
    local formatted_TPM_string = string.format("%.2f", global.TPM_value / 100)
    second_row.add{type = "label", caption = "TPM: " .. formatted_TPM_string}
    second_row.add{type = "label", caption = "Test Time: " .. tostring(global.M_value) .. " min"}
    second_row.add{type = "label", caption = "Train: " .. tostring(global.Loco_value) .. "-" .. tostring(global.Wagons_value)}

    -- Dialog Row (Buttons at the bottom)
    local dialog_row = window.add{type="flow", direction="horizontal"}
    dialog_row.style.horizontal_align = "right"
    local confirm_button = dialog_row.add{type="button", caption="OK", style="confirm_button"}
    confirm_button.name = "dialog_confirm_button"

    return window
end


function setSpeedAndPause()
    game.speed = 1
end

script.on_nth_tick(10, function(event)
	if not global.testbench_running then
       		return
    	end
	local counter = local counter or 0
	global.tpmtick = global.tpmtick or 0
	local trainComponents = nil
	local counter = local counter + 10

  	if global.current_set == 1 and global.despawned_trains > 0 and gloal.testtimer == 1
        check_state_and_update_table()
	end

   	if local.counter >= global.tpmtick then
        start_spawning_trains()
        local counter = 0
	end
end)


-- Function to handle test timer logic
local function handle_test_timer()
    if global.despawned_trains > 0 then 
        global.testtimer = global.testtimer + 1
    end
end


local function handle_testbench(player)
    if global.testtimer == 1 then 
        if global.importantrailsignals then
            for key, value in pairs(global.importantrailsignals) do
                local description = "Key: " .. tostring(key) .. ", Value: " .. serpent.line(value)
            end
        end
        check_4ways_or_3ways()
        RHT_or_LHT_based_on_signal_state()
        local waysDescription = "Ways: " .. tostring(global.ways)
        local RHTDescription = ""

        if global.RHT > 0 then
            RHTDescription = "RHT"
        elseif global.RHT < 0 then
            RHTDescription = "LHT"
        else
            RHTDescription = "Value of global.RHT is 0"
        end
    end

    if global.testtimer >= global.M_value then
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
            if global.TestRuns_counter > 0 then
                global.testbench_running = true	
            elseif global.TestRuns_counter == 0 then
                for _, player in pairs(game.players) do
                    createDialogWindow(player)
                end
                setSpeedAndPause()

            end
        end
	calculate_test_score()
    end
end


script.on_nth_tick(3600, function(event)
  if not global.testbench_running then
   return
  end
    local player = game.players[1]
    local parent_frame = player.gui.screen["parent_frame"]
    local inner_frame1 = parent_frame and parent_frame.vertical_frame.inner_frame1
	

    -- Ensure global variables are initialized
    global.testtimer = global.testtimer or 0
	update_labels_from_globals()

    -- Early exit if testbench is not running and test is not running

    handle_test_timer()
    handle_testbench(player)
end)

local function destroy_carriages(train)
    for _, carriage in pairs(train.carriages) do
        carriage.destroy()
    end
end

script.on_event(defines.events.on_train_changed_state, function(event)
    local train = event.train
    
    -- Early exit if the train state is not one of the states we're interested in
    if train.state ~= defines.train_state.arrive_station and train.state ~= defines.train_state.no_path then
        return
    end

    -- Ensure global variables are initialized
    global.despawned_trains = global.despawned_trains or 0
    global.testtimer = global.testtimer or 0

    if train.state == defines.train_state.arrive_station then
        destroy_carriages(train)
        global.despawned_trains = global.despawned_trains + 1
        if global.despawned_trains == 1 then 
            global.testtimer = 0
        end
    elseif train.state == defines.train_state.no_path and global.testtimer < 30 then
        destroy_carriages(train)
    end
end)

-- Event handler for button clicks
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element
	
    local parent_frame = player.gui.screen.parent_frame
    local vertical_frame = parent_frame and parent_frame.vertical_frame
    local inner_frame1 = vertical_frame and vertical_frame.inner_frame1

    if element and element.valid then
        if element.name == "settings_close_button" then
            if player.gui.screen["settings_window"] then
                player.gui.screen["settings_window"].destroy()
            end
        end

        if element.name == "apply_button" then
            -- Only apply changes if the testbench is not running or is done
            if global.testbench_running == false then
                for key, value in pairs(global.temp_slider_values) do
                    global[key] = value
                end
                -- Clear the temporary table
                global.temp_slider_values = {}
            end
        end

        if element.name == "speed_button" then
			if game.speed == 1 then
				game.speed = 200
			elseif game.speed ~=1 then
				game.speed = 1
			end
        end

        if element.name == "start_button" then
            if global.testbench_running == false then
				local player = game.players[1]
				delete_all_trains(player.surface)
				populateSpawnPositions()
				global.current_test = 1
				global.trafficType = 1
				global.testrunning = true
				global.testbench_running = true
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
				
            elseif global.testbench_running == true then
                delete_all_trains(player.surface)
				global.testbench_running = false
            end
        end

        if element.name == "settings_button" then
            if player.gui.screen["settings_window"] then
                player.gui.screen["settings_window"].destroy()
            else
                create_settings_frame(player)
            end
        end
		
        if element and element.valid and element.name == "dialog_confirm_button" then
            -- If the "Confirm" button was clicked, destroy the window
            local window = element.parent.parent  -- The parent of the button's parent (dialog_row) is the main window frame
            if window and window.valid then
                window.destroy()
            end
        end
    
		if element.name == "confirm_button_settings" then
			for key, value in pairs(global.temp_slider_values) do
				global[key] = value
			end
			log("Debug: temp_slider_values contents: " .. serpent.block(global.temp_slider_values))
		end

		
		
	end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local player = game.players[event.player_index]
    local element = event.element

    if player.gui.screen["settings_window"] then
        local frame = player.gui.screen["settings_window"]

        -- Check if main_flow exists
        if frame and frame["main_flow"] then
            local main_flow = frame["main_flow"]
            local settings_flow = main_flow["settings_flow"]

            if element.name == "M_dropdown" and settings_flow then
                local dropdown_values = {15, 90, 240}
                local selected_value = dropdown_values[element.selected_index]
                global.temp_slider_values = global.temp_slider_values or {}
                global.temp_slider_values["M_value"] = selected_value
                local caption_value = tostring(selected_value) .. " Min"
                if settings_flow["M_value_label"] then
                    settings_flow["M_value_label"].caption = caption_value
                else
                    log("Debug: M_value_label does not exist")
                end
            end
        else
            log("Debug: main_flow does not exist")
        end
    else
        log("Debug: settings_frame does not exist")
    end
end)


-- Event handler for GUI value changes
-- Event handler for GUI value changes
script.on_event(defines.events.on_gui_value_changed, function(event)
    local player = game.players[event.player_index]
    local element = event.element
    local value = element.slider_value
    if not value then
        log("Debug: Slider value is nil for " .. element.name)
        return
    end

    if player.gui.screen["settings_window"] then
        local frame = player.gui.screen["settings_window"]
        
        if not frame["content_frame"] then
            log("Debug: content_frame does not exist")
            return
        end

        local content_frame = frame["content_frame"]

        local slider_config = {
            ["locomotives_slider"] = {global_var="locomotives", label="locomotives_value_label"},
            ["wagons_slider"] = {global_var="wagons", label="wagons_value_label"},
            ["tpm_slider"] = {global_var="tpm", label="tpm_value_label"},
            ["test_runs_slider"] = {global_var="test_runs", label="test_runs_value_label"}
        }

        local config = slider_config[element.name]
        if config then
            -- Update the temp_slider_values
            global.temp_slider_values[config.global_var] = element.slider_value

            -- Update the label caption
            local flow = content_frame[element.name .. "_flow"]
            if flow then
                local label = flow[element.name .. "_value_label"]
                if label then
                    label.caption = tostring(value)
                else
                    log("Debug: Label does not exist for " .. element.name)
                end
            else
                log("Debug: Flow does not exist for " .. element.name)
            end
        end
    end
end)
