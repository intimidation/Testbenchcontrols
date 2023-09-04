-- Constants
local COMBINATOR_POSITION = {x=208.5, y=1282.5}

-- Create main frame with buttons and labels
local function create_main_frame(player)
    -- Create outer frame (Standalone Window) in player.gui.screen for draggability
    local outer_frame = player.gui.screen.add{
        type = "frame",
        name = "outer_frame",
        direction = "horizontal",
        style = "frame"
    }
    -- Make the frame draggable
    local dragger = outer_frame.add{type="empty-widget"}
    dragger.style.size = {24, 100}
    dragger.drag_target = outer_frame
	dragger.style = "draggable_space_header"
	
    -- Position the frame at the top of the screen
    outer_frame.location = {x=0, y=500}

    -- Create first inner frame for buttons (Content Frame)
    local inner_frame1 = outer_frame.add{
        type = "frame",
        name = "inner_frame1",
        direction = "vertical",
        style = "frame"
    }

    -- Add sprite-buttons to first inner frame
    inner_frame1.add{type = "sprite-button", name = "start_button", sprite = "start_button_sprite"}
	inner_frame1.add{type = "speed_up_button", name = "speed_up_button", sprite = "speedup_button_sprite" }
    inner_frame1.add{type = "sprite-button", name = "reset_button", sprite = "reset_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "auto_button", sprite = "auto_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "sets_button", sprite = "sets_button_sprite"}
    inner_frame1.add{type = "sprite-button", name = "settings_button", sprite = "settings_button_sprite"}
	inner_frame1.start_button.tooltip = "Start/Stop the test"
	inner_frame1.reset_button.tooltip = "Stops the test and delete trains"
	inner_frame1.auto_button.tooltip = "Switch between Auto and Manual mode"
	inner_frame1.sets_button.tooltip = "Sets configuration in manual mode"
	inner_frame1.settings_button.tooltip = "Open Settings"
	inner_frame1.speed_up_button.tooltip = "Speed up the game"

    -- Create second inner frame for labels (Content Frame)
    local inner_frame2 = outer_frame.add{
        type = "frame",
        name = "inner_frame2",
        direction = "vertical",
        style = "frame"
    }

    -- Add labels to second inner frame
	inner_frame2.add{type = "label", name = "current_time_running_label", caption = "Current Time: 0", style = "label"}
	inner_frame2.add{type = "label", name = "current_tpm_label", caption = "Current TPM: 0", style = "label"}
	inner_frame2.add{type = "label", name = "current_set_label", caption = "Current Set: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set1_label", caption = "Set 1: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set2_label", caption = "Set 2: 0", style = "label"}
    inner_frame2.add{type = "label", name = "set3_label", caption = "Set 3: 0", style = "label"}
    inner_frame2.add{type = "label", name = "score_label", caption = "Score: 0", style = "label"}
end

-- Event handler for game initialization
script.on_init(function()
    global = global or {}
    global.auto_mode = global.auto_mode or true
    global.set_number = global.set_number or 1
    global.reset_signal = global.reset_signal or false
    global.K_value = global.K_value or 2
    global.M_value = global.M_value or 15
	global.pending_resets = global.pending_resets or {}
	global.TPM_value = global.TPM_value or 2900  -- Initialize to 2900 if it doesn't exist
	global.testbench_running = global.testbench_running or false
	global.numberofways = global.numberofways or 4
	global.Wagons_value = global.Wagons_value or 4
	global.Loco_value = global.Loco_value or 2
	global.TestRuns_value = global.TestRuns_value or 1
	global.last_signal_9 = global.last_signal_9 or nil
	global.TestRuns_counter = 0
	

    for i, player in pairs(game.players) do
        if player and player.valid then
            create_main_frame(player)
            game.print("Frame should be created for player: " .. i)  -- Debugging line
        else
            game.print("Player " .. i .. " is not valid.")  -- Debugging lineo
        end
    end
end)

function print_global_variables()
    for key, value in pairs(global) do
        game.print(key .. ": " .. tostring(value))
    end
end

-- Destroy GUI
function destroy_GUI(player)
    if player.gui.screen["outer_frame"] then
        player.gui.screen["outer_frame"].destroy()
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
    dragger.style.size = {300, 24}
    dragger.drag_target = frame

    -- Position the frame at the top of the screen
    frame.location = {x=280, y=330}

    -- Add title label to the main frame
    local title_label = frame.add{type="label", name="settings_title_label", caption="Settings"}
    title_label.style.font = "default-large-bold"

    -- Create a flow to hold both sets of sliders and labels
    local main_flow = frame.add{type="flow", name="main_flow", direction="horizontal"}

    -- Create a flow to hold the first set of sliders and labels
    local settings_flow = main_flow.add{type="flow", name="settings_flow", direction="vertical"}

    -- Add K slider and labels
    settings_flow.add{type="label", name="K_label", caption="Time to fill up intersection:"}
    local K_slider = settings_flow.add{type="slider", name="K_slider", minimum_value=1, maximum_value=10, value=global.K_value or 0, value_step=1}
    settings_flow.add{type="label", name="K_value_label", caption=tostring(global.K_value or 1) .. " Min"}

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


	set_signal(6, {type="signal-K", value=global.K_value})
    set_signal(7, {type="signal-M", value=global.M_value})
	set_signal(8, {type="signal-X", value=global.Loco_value_label})
	set_signal(9, {type="signal-Y", value=global.Wagons_value})
    set_signal(10, {type="signal-G", value=global.TPM_value})

	
	
	settings_flow2.add{type="label", name="TestRuns_label", caption="Number of Test Runs:"}
    local TestRuns_slider = settings_flow2.add{type="slider", name="TestRuns_slider", minimum_value=1, maximum_value=100, value=global.TestRuns_value or 1, value_step=1}
    settings_flow2.add{type="label", name="TestRuns_value_label", caption=tostring(global.TestRuns_value or 1)}
	-- Add "Apply" Button to settings_flow2
    settings_flow2.add{type="button", name="apply_button", caption="Apply"}
end
--Testbench functions
-- Function to run a test
function run_test()
	 global.TestRuns_counter = global.TestRuns_counter or 0
    if global.TestRuns_counter > 0 then
        set_signal(1, {type="signal-A", value=1}, true)  -- Start a new run
        global.TestRuns_counter = global.TestRuns_counter - 1  -- Reduce the counter
    end
end



-- Function to check the number of ways trains can go
function check_number_of_ways()
    local directions = {"South all lanes", "West all lanes", "North all lanes", "East all lanes"}
    local no_way_to = {}
    
    for _, surface in pairs(game.surfaces) do
        for _, stop_name in pairs(directions) do
            local can_go = false
            for _, train in pairs(surface.get_trains()) do
                if train.schedule and train.schedule.records then
                    for _, record in pairs(train.schedule.records) do
                        if record.station == stop_name then
                            can_go = true
                            break
                        end
                    end
                end
                if can_go then break end
            end
            if not can_go then
                table.insert(no_way_to, stop_name)
            end
        end
    end
    
    if #no_way_to == 0 then
       global.numberofways = 4
		
    else
        global.numberofways = 3
		return table.concat(no_way_to, ", ")
		
		
    end
end


--Testbench logic

function delete_trains_to_stop(stop_names, skip_first)
    for _, stop_name in pairs(stop_names) do
        local pattern = stop_name  -- Prepare the pattern, could add more specific rules here if needed

        for _, surface in pairs(game.surfaces) do
            for _, train in pairs(surface.get_trains()) do
                if train.schedule and train.schedule.records then
                    for _, record in pairs(train.schedule.records) do
                        if string.find(record.station, pattern) then  -- Look for the pattern in the station name
                            if skip_first and train.manual_mode then
                                -- Skip the first carriage and delete the rest
                                for i = 2, #train.carriages do  -- Start from 2 to skip the first carriage
                                    train.carriages[i].destroy()
                                end
                            elseif not skip_first and not train.manual_mode then
                                -- Delete all carriages
                                for _, carriage in pairs(train.carriages) do
                                    carriage.destroy()
                                end
                            end
                            break  -- Exit the loop for this train's schedule
                        end
                    end
                end
            end
        end
    end
end

function update_trains_with_one_carriage(Loco_value, Wagons_value)
    local trains_to_update = {}  -- Table to hold the trains that need to be updated
    
    -- Scan all trains on all surfaces
    for _, surface in pairs(game.surfaces) do
        for _, train in pairs(surface.get_trains()) do
            if train.schedule and train.schedule.records then
                for _, record in pairs(train.schedule.records) do
                    if #train.carriages == 1 then  -- Only front carriage is left
                        table.insert(trains_to_update, train)  -- Add the train to the list
                        break  -- Exit the loop for this train's schedule
                    end
                end
            end
        end
    end
    
    -- Update the trains by adding locomotives and wagons
    for _, train in pairs(trains_to_update) do
        -- Add locomotives
        for i = 1, Loco_value do
            surface.create_entity{
                name = "locomotive",
                position = train.front_stock.position,
                direction = train.front_stock.direction,
                force = train.force,
                raise_built = true
            }
        end
        -- Add wagons
        for i = 1, Wagons_value do
            surface.create_entity{
                name = "cargo-wagon",
                position = train.back_stock.position,
                direction = train.back_stock.direction,
                force = train.force,
                raise_built = true
            }
        end
    end
end



-- Function to set a signal at a given index in a Constant Combinator
function set_signal(index, signal, reset_next_tick)
    local surface = game.surfaces[1]
    local combinator = surface.find_entity("constant-combinator", COMBINATOR_POSITION)

    global.pending_resets = global.pending_resets or {}  -- Safeguard

    if reset_next_tick then
        table.insert(global.pending_resets, {index = index, tick = game.tick + 1})
    end

    if combinator and combinator.valid then
        local control_behavior = combinator.get_or_create_control_behavior()

        if signal then
            control_behavior.set_signal(index, {signal = {type="virtual", name=signal.type}, count = signal.value or 1})
        else
            control_behavior.set_signal(index, nil)
        end
    end
end

-- Helper function to recursively find and update a label
function update_label(element, label_name, new_caption)
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

-- Function to update labels based on signals from a medium electric pole
function update_labels_from_pole()
	for _, player in pairs(game.players) do
		local outer_frame = player.gui.screen.outer_frame
		if outer_frame then  -- Check if outer_frame exists
			local inner_frame2 = outer_frame.inner_frame2
			if inner_frame2 then  -- Check if inner_frame2 exists
				if signals then
					local signal_4 = signals["signal_4"] or 0
					local signal_6 = signals["signal_6"] or 0
					local signal_8 = signals["signal_8"] or 0
					local signal_9 = signals["signal_9"] or 0
					
                        
					update_label(inner_frame2, "set1_label", "Set 1: " .. signal_4)
					update_label(inner_frame2, "set2_label", "Set 2: " .. signal_6)
					update_label(inner_frame2, "set3_label", "Set 3: " .. signal_8)
					update_label(inner_frame2, "score_label", "Score: " .. signal_9)
				end
              
                
            end
        end
    end
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

-- Event handler for game tick
script.on_event(defines.events.on_tick, function(event)
    local surface = game.surfaces[1]
    local pole = surface.find_entity("medium-electric-pole", {x=208.5, y=1280.5})
    local signals = {}
    
    if event.tick % 30 == 0 then
        if pole then
            local signal_arr = pole.get_merged_signals(defines.circuit_connector_id.electric_pole)
            if signal_arr then
                for _, signal in pairs(signal_arr) do
                    signals[signal.signal.name] = signal.count
                end
            end
            
            local current_signal_P = signals['signal-P'] or 0
            local signal_P_changed = (current_signal_P ~= global.last_signal_P)
            if signal_P_changed then
                delete_trains_to_stop({"all lanes", "output"}, false)
            end
            global.last_signal_P = current_signal_P
            
            for _, player in pairs(game.players) do  
                local inner_frame1 = player.gui.screen.outer_frame.inner_frame1
                local start_button = inner_frame1.start_button
                local auto_button = inner_frame1.auto_button
                
                if start_button and start_button.valid then
                    if signals['signal-J'] == 0 or signals['signal-J'] == nil then
                        global.testbench_running = false
                        start_button.sprite = "start_button_sprite"
                    elseif signals['signal-J'] == 1 then
                        global.testbench_running = true
                        start_button.sprite = "stop_button_sprite"
                    end
                end
                
                if auto_button and auto_button.valid then
                    if signals['signal-1'] == 0 or signals['signal-1'] == nil then
                        global.auto_mode = false
                        auto_button.sprite = "manual_button_sprite"
                    elseif signals['signal-1'] == 1 then
                        global.auto_mode = true
                        auto_button.sprite = "auto_button_sprite"
                    end
                end
            end
            
            local current_signal_9 = signals["signal-9"]
            if global.last_signal_9 ~= current_signal_9 and signals["signal-9"] ~= nil then
                game.print(
                    "Set1: " .. string.format("%.2f", (signals["signal-4"] or 0) / 100) ..
                    ", Set2: " .. string.format("%.2f", (signals["signal-6"] or 0) / 100) ..
                    ", Set3: " .. string.format("%.2f", (signals["signal-8"] or 0) / 100) ..
                    ", Score: " .. string.format("%.2f", current_signal_9 / 100)
                )
            end
            
            global.last_signal_9 = current_signal_9
            
            local current_signal_J = signals['signal-J']
            if global.last_signal_J == 1 and current_signal_J == nil then
                run_test()
            end
            global.last_signal_J = current_signal_J
        end
        
        for _, player in pairs(game.players) do  
            local inner_frame2 = player.gui.screen.outer_frame.inner_frame2
            if inner_frame2 then
                local set1_value = (signals["signal-4"] or 0) / 100
				local set2_value = (signals["signal-6"] or 0) / 100
				local set3_value = (signals["signal-8"] or 0) / 100
				local score_value = (signals["signal-9"] or 0) / 100
				local current_time_value = (signals["signal_0"] or 0) / 100
				local current_tpm_value = (signals["signal_2"] or 0) / 100
				local current_set_value = (signals["signal_Z"] or 0) / 100

				inner_frame2.set1_label.caption = "Set 1: " .. string.format("%.2f", set1_value)
				inner_frame2.set2_label.caption = "Set 2: " .. string.format("%.2f", set2_value)
				inner_frame2.set3_label.caption = "Set 3: " .. string.format("%.2f", set3_value)
				inner_frame2.score_label.caption = "Score: " .. string.format("%.2f", score_value)
				inner_frame2.current_time_running_label.caption = "Current Time: " .. string.format("%.2f", current_time_value)
				inner_frame2.current_tpm_label.caption = "Current TPM: " .. string.format("%.2f", current_tpm_value)
				inner_frame2.current_set_label.caption = "Current Set: " .. string.format("%.2f", current_set_value)

            end
        end
    end
    
    if global.pending_resets then
        for i, pending_reset in pairs(global.pending_resets) do
            if event.tick >= pending_reset.tick then
                set_signal(pending_reset.index, nil)
                table.remove(global.pending_resets, i)
            end
        end
    end
end)


-- Event handler for button clicks
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.players[event.player_index]
    local element = event.element
    local surface = player.surface
	local inner_frame1 = player.gui.screen.outer_frame.inner_frame1
	    if element.name == "reset_values_button" then
        local frame = player.gui.screen["settings_frame"]
        if frame then
            local main_flow = frame["main_flow"]
            if main_flow then
                local settings_flow = main_flow["settings_flow"]
                if settings_flow then
                    local K_slider = settings_flow["K_slider"]
                    local M_slider = settings_flow["M_slider"]
                    local TPM_slider = settings_flow["TPM_slider"]

                    if K_slider and K_slider.valid and K_slider.type == "slider" then
                        K_slider.slider_value = 2
                    end

                    if M_slider and M_slider.valid and M_slider.type == "slider" then
                        M_slider.slider_value = 15
                    end

                    if TPM_slider and TPM_slider.valid and TPM_slider.type == "slider" then
                        TPM_slider.slider_value = 2900 / 100
                    end

                    -- Update global variables
                    global.K_value = 2
                    global.M_value = 15
                    global.TPM_value = 2900
					-- Send the new global values to the local combinator
                    set_signal(6, {type="signal-K", value=global.K_value})
                    set_signal(7, {type="signal-M", value=global.M_value})
                    set_signal(10, {type="signal-G", value=global.TPM_value})

                    -- Update labels
                    if settings_flow.K_value_label then
                        settings_flow.K_value_label.caption = "2 Min"
                    end

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
	if element.name == "speed_up_button" then
		if game.speed > 1 then
		game.speed = 1
		elseif game.speed < 20 then
		game.speed = 20
		end
	end
	if element.name == "apply_button" then
		delete_trains_to_stop({"all lanes", "output"}, true)
		
    -- Add logic to add loco and wagons based on slider values
    -- ... (your logic to add loco and wagons)
	end

    if element.name == "start_button" then
		local start_button = inner_frame1.start_button
        if element.sprite == "stop_button_sprite" then
            element.sprite = "start_button_sprite"
			global.TestRuns_counter = global.TestRuns_value
			if global.auto_mode == true then
				global.testbenchrunning = true
				run_test()
			end
        else
            element.sprite = "stop_button_sprite"
			global.testbenchrunning = false 
			set_signal(1, {type="signal-A", value=1}, true)
        end
        
		
	end
	
    if element.name == "reset_button" then
		local start_button = inner_frame1.start_button 
		if start_button and start_button.valid then
			if start_button.sprite == "stop_button_sprite" then
				start_button.sprite = "start_button_sprite"
				set_signal(1, {type="signal-A", value=1}, true)  -- Send the signal
			end
			
		end
            -- Schedule delete_trains_to_stop() to run after 20 ticks
        local tick_to_schedule = game.tick + 20
        script.on_nth_tick(tick_to_schedule, function()
            delete_trains_to_stop({"all lanes", "output"}, false)  -- Delete spawned trainse
            script.on_nth_tick(tick_to_schedule, nil)  -- Unregister the one-time event
        end)
	end
	
	

    if element.name == "auto_button" then
		local auto_button = inner_frame1.auto_button
		if element.sprite == "auto_button_sprite" then
			global.auto_mode = true  -- Explicitly turn off auto_mode
			element.sprite = "manual_button_sprite"
		elseif element.sprite == "manual_button_sprite" then
			global.auto_mode = false  -- Explicitly turn off auto_mode
			element.sprite = "auto_button_sprite"
		end
	set_signal(2, {type="signal-B", value=1}, true)
	end

    if element.name == "sets_button" then
		set_signal(3, {type="signal-C", value=1}, true)
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
            ["K_slider"] = {global_var="K_value", label="K_value_label", signal="signal-K", flow=settings_flow, index=6, suffix=" Min"},
            ["M_slider"] = {global_var="M_value", label="M_value_label", signal="signal-M", flow=settings_flow, index=7, suffix=" Min"},
            ["Loco_slider"] = {global_var="Loco_value", label="Loco_value_label", signal="signal-X", flow=settings_flow2, index=8},
            ["Wagons_slider"] = {global_var="Wagons_value", label="Wagons_value_label", signal="signal-Y", flow=settings_flow2, index=9},
            ["TPM_slider"] = {global_var="TPM_value", label="TPM_value_label", signal="signal-G", flow=settings_flow, index=10, scale=100},
            ["TestRuns_slider"] = {global_var="TestRuns_value", label="TestRuns_value_label", flow=settings_flow2, index=11}
        }

        local config = slider_config[element.name]
        if config then
            local value = tonumber(element.slider_value)
            if config.scale then value = math.floor(value * config.scale + 0.5) end
            global[config.global_var] = value  -- Updating the global variable

            local caption_value = config.scale and string.format("%.2f", value / config.scale) or tostring(value)
            if config.suffix then caption_value = caption_value .. config.suffix end

            if config.flow[config.label] then
                config.flow[config.label].caption = caption_value
            end
			if config.signal then
				set_signal(config.index, {type=config.signal, value=value})
			end
        end
    end
end)

commands.add_command("print_globals", "Print global variables", function()
    game.print("K_value: " .. tostring(global.K_value))
    game.print("M_value: " .. tostring(global.M_value))
    game.print("Loco_value: " .. tostring(global.Loco_value))
    game.print("TPM_value: " .. tostring(global.TPM_value))
    game.print("Wagons_value: " .. tostring(global.Wagons_value))
end)
