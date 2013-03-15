local ecobee = require("L_ecobee")
local dkjson = require("L_ecobee_dkjson")
local json = L_ecobee_dkjson

local thermostats = {}

function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function log(...)
  print(...)
end

function logSession(session)
  local line = "[ Session: "
  for k,v in pairs(session) do
    line = line .. k .. "=" .. tostring(v) .. " "
  end
  log(line .. "]")
end

function poll(session)

  log(os.date("Polling at %c..."))

  if not session.auth_token then
    log("Attempting to getPin...")
    local ecobeePin = ecobee.getPin(session)
    if ecobeePin then log("Register this PIN at ecobee.com: " .. ecobeePin) end

  elseif not session.refresh_token then
    log("About to getTokens...")
    ecobee.getTokens(session)

  else
    log("Fetching revisions:")
    local revisions = ecobee.getThermostatSummary(session)
    if revisions then
      local changed = {}
      for k,v in pairs(revisions) do
        -- See if we know if this thermostat's program, hvac mode, settings, configuration or runtime settings have changed
        if not thermostats[k] or thermostats[k].thermostatRev ~= v.thermostatRev or
               thermostats[k].runtimeRev ~= v.runtimeRev then
          log("Thermostat " .. k .. " is new or changed!")
          changed[#changed + 1] = k
        end
      end
        
      -- if any thermostats changed, fetch their full info
      if #changed > 0 then
        log( tostring(#changed) .. " thermostat(s) changed. Fetching:")
        local t = ecobee.getThermostats(session, ecobee.thermostatsOptions(changed))
        if t then
          for k,v in pairs(t) do
            thermostats[k] = v
            thermostats[k].runtimeRev = revisions[k].runtimeRev -- NOTE: adding runtimeRev to table!!!  just for testing
          end
          log(json.encode(thermostats, {indent = true}))

          -- try to send a message to all changed thermostats
          for k,v in pairs(t) do
            local selection = { selectionType = "thermostats", selectionMatch = k }
            local functions = { [1] = ecobee.sendMessageFunction("From my test code.") }
            if ecobee.updateThermostats(session, ecobee.thermostatsUpdateOptions(selection, functions)) then
              log("Successfully sent message!")
            end
          end

        end
      end
    end
  end
end

local session = { app_key = "1CboqiVS4K9lyjeBcQC6tIOLAMoGPVsH", scope = "smartWrite" }

while true do
  poll(session)
  logSession(session)
  sleep(60)
end

