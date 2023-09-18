function spawnTrainAtStationWithSchedule(stationName, numFrontLoco, numBackLoco, numCargoWagons, numFluidWagons)
  -- Convert to numbers, default to 0 if nil
  numFrontLoco = numFrontLoco or 0
  numBackLoco = numBackLoco or 0
  numCargoWagons = numCargoWagons or 0
  numFluidWagons = numFluidWagons or 0

  -- Find the train stops by name
  local surface = game.surfaces[1]
  local stations = game.get_train_stops{name = stationName}
  local createEntity = surface.create_entity

  if #stations == 0 then
    log("No station found with the name: " .. stationName)
    return
  end

  for _, station in pairs(stations) do
    local connectedRail = station.connected_rail
    local stationDirection = station.direction
    local delta = {x = 0, y = 0}

    if stationDirection == 0 then
      delta.y = 7
    elseif stationDirection == 2 then
      delta.x = -7
    elseif stationDirection == 4 then
      delta.y = -7
    elseif stationDirection == 6 then
      delta.x = 7
    end

    if connectedRail and connectedRail.trains_in_block == 0 then
      local lastPosition = connectedRail.position
      local components = {}

      for i = 1, numFrontLoco do
        table.insert(components, "locomotive")
      end
      for i = 1, numCargoWagons do
        table.insert(components, "cargo-wagon")
      end
      for i = 1, numFluidWagons do
        table.insert(components, "fluid-wagon")
      end
      for i = 1, numBackLoco do
        table.insert(components, "locomotive")
      end

      local firstFrontLoco
      for _, component in ipairs(components) do
        local direction = stationDirection
        if component == "locomotive" and not firstFrontLoco then
          firstFrontLoco = createEntity{
            name = component,
            position = lastPosition,
            direction = direction,
            force = "player"
          }
          addFuelToLocomotive(firstFrontLoco)
        else
          if component == "locomotive" then
            direction = (stationDirection + 4) % 8
          end
          local entity = createEntity{
            name = component,
            position = lastPosition,
            direction = direction,
            force = "player"
          }
          if component == "locomotive" then
            addFuelToLocomotive(entity)
          end
        end
        lastPosition = {x = lastPosition.x + delta.x, y = lastPosition.y + delta.y}
      end

      local schedule = create_schedule(stationName)
      if schedule then
        local train = firstFrontLoco.train
        train.schedule = {current = 1, records = {{station = schedule}}}
        train.manual_mode = false
        train.speed = 290
      else
        log("No schedule found with the name: " .. scheduleName)
      end
    end
  end
end





