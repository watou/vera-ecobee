module("L_ecobee",package.seeall)

--[[

 ecobee thermostat API in Lua

 Copyright (C) 2013  John W. Cocula and others

 Based in part on the example API code published by ecobee.

 When distributed in encrypted form, this file's contents are
 a proprietary and confidential trade secret of John W. Cocula.
 However its use is licensed at no cost for the sole permitted
 use of running unmodified on users' systems. This file is
 distributed in this encrypted form when it contains an
 application key issued by ecobee.  This application key is for
 the sole use of this plugin and it is a violation of this
 license to use the application key in other ways.

 When distributed in unencrypted source form without said
 application key embedded herein, this program is free software: you
 can redistribute it and/or modify it under the terms of the GNU General
 Public License as published by the Free Software Foundation, either 
 version 3 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

local https = require "ssl.https"
local dkjson = require("L_ecobee_dkjson")
local json = L_ecobee_dkjson
local ltn12 = require "ltn12"

local API_ROOT = '/api/1/'
local COOL_OFF = 4000
local HEAT_OFF = -5002
local MAX_ID_LIST_LEN = 25

local version = "1.0"

--[[
URL encoding (from Roberto Ierusalimschy's book "Programming in Lua" 2nd ed.)
]]--
local function escape(s)
  s = string.gsub(s, "[&=+%%%c]", function(c) return string.format("%%%02X", string.byte(c)) end)
  s = string.gsub(s, " ", "+")
  return s
end

local function stringify(t)
  local b = {}
  for k,v in pairs(t) do
    b[#b + 1] = (k .. "=" .. escape(v))
  end
  return table.concat(b, "&")
end

local AUTH_ERRORS = 
{
  invalid_request = "The request is malformed. Check parameters.",
  invalid_client = "Authentication error, invalid authentication method, lack of credentials, etc.",
  invalid_grant = "The authorization grant, token or credentails are expired or invalid.",
  unauthorized_client = "The authenticated client is not authorized to use this authorization grant type.",
  unsupported_grant_type = "The authorization grant type is not supported by the authorization server.",
  invalid_scope = "The requested scope is invalid, unknown, malformed, or exceeds the scope granted by the resource owner.",
  not_supported = "HTTP method not supported for this request.",
  account_locked = "Account is temporarely locked.",
  account_disabled = "Account is disabled.",
  authorization_pending = "Waiting for user to authorize application.",
  authorization_expired = "The authorization has expired waiting for user to authorize.",
  slow_down = "Slow down polling to the requested interval." 
}
function isAuthError(errmsg)
  return AUTH_ERRORS[errmsg]
end

--[[

All calls below accept as their first argument a 'session' table containing these possible values:

* api_key
* scope
* auth_token
* access_token
* token_type
* refresh_token
* http_status
* error
* error_description

]]--

--[[
Generic request code handles get and post requests
Must specify options.url and dataString

Returns the possibly JSON-parsed table or string (or nil)
--]]
local function makeRequest(session, options, dataString)
  options.host = "www.ecobee.com"
  options.port = "443"
  local res = {}
  options.sink = ltn12.sink.table(res)
  options.method = options.method or "GET"
  options.headers = options.headers or {}
  options.headers["User-Agent"] = "ecobee-lua-api/" .. version
  options.headers["Content-Type"] = options.headers["Content-Type"] or "application/json;charset=UTF-8"
  options.protocol = "sslv3"
  local errmsg

  if options.method == "POST" then
    options.headers["Content-Length"] = string.len(dataString)
    options.source = ltn12.source.string(dataString)
  else
    options.url = options.url .. "?" .. dataString
  end

  if session.log then
    session.log:write(">>> ", os.date(), "\n")
    for k,v in pairs(options.headers) do session.log:write(k, " ", v, "\n") end
    session.log:write(os.date(), " >>> ", options.method, " ", options.url, "\n")
    if options.method == "POST" then
      session.log:write(dataString, "\n")
    end
  end

  local one, code, headers, errmsg = https.request(options)

  res = table.concat(res)

  if session.log then
    session.log:write("<<< ", tostring(code), " ", tostring(errmsg), "\n")
    session.log:write(tostring(res), "\n")
    session.log:flush()
  end

  if options.headers.Accept == 'application/json' then
    local nc, parsed
    parsed, nc, errmsg = json.decode(res)
    if parsed then res = parsed end
  end

  -- extract the most specific error information and put it in the session
  if code ~= 200 then
    if type(res) == "table" then
      if res.status and res.status.code then
        session.error = tostring(res.status.code)
        session.error_description = res.status.message
      else
        session.error = res.error
        session.error_description = res.error_description or res.error_descripton
      end
    else
      session.error = tostring(code)
      session.error_description = errmsg
    end
  else
    session.error = nil
    session.error_description = nil
    return res
  end
end

--[[
Get a new pin for an application.

Expects these values on call:
* session.scope

Returns ecobeePin and sets these values on success:
* session.auth_token
]]--
function getPin(session)
  local options = { url = "/home/authorize", headers = { Accept = "application/json" } }
  local data = { response_type = "ecobeePin", scope = session.scope, client_id = "M2Fo9WiCIrQUZoC5EbckbjmttWLUVcgU" }
  local res = makeRequest(session, options, stringify(data))

  if res and res.ecobeePin and res.code then
    session.auth_token = res.code
    return res.ecobeePin
  end
end

--[[
Use an auth_token to get a new set of tokens from the server.

Expects these values on call:
* session.auth_token

Sets and returns these values on success:
* session.access_token
* session.token_type
* session.refresh_token
* session.scope
]]--
function getTokens(session)
  local options = { url = "/home/token", method = "POST",
                    headers = { Accept = "application/json", ["Content-Type"] = "application/x-www-form-urlencoded" } }
  local data = { grant_type = "ecobeePin", code = session.auth_token, client_id = "M2Fo9WiCIrQUZoC5EbckbjmttWLUVcgU" }
  local res = makeRequest(session, options, stringify(data))
  
  if res and res.access_token and res.token_type and res.refresh_token and res.scope then
    session.access_token  = res.access_token
    session.token_type    = res.token_type
    session.refresh_token = res.refresh_token
    session.scope         = res.scope
    return session.access_token, session.token_type, session.refresh_token, session.scope
  end
end

--[[
Use a refresh token to get a new set of tokens from the server.

Expects these values on call:
* session.refresh_token

Sets and returns these values on success:
* session.access_token
* session.token_type
* session.refresh_token
* session.scope
]]--
local function refreshTokens(session)
  local options = { url = "/home/token", method = "POST",
                    headers = { Accept = "application/json", ["Content-Type"] = "application/x-www-form-urlencoded" } }
  local data = { grant_type = "refresh_token", code = session.refresh_token, client_id = "M2Fo9WiCIrQUZoC5EbckbjmttWLUVcgU" }
  local res = makeRequest(session, options, stringify(data))
  
  if res and res.access_token and res.token_type and res.refresh_token and res.scope then
    session.access_token  = res.access_token
    session.token_type    = res.token_type
    session.refresh_token = res.refresh_token
    session.scope         = res.scope
    return session.access_token, session.token_type, session.refresh_token, session.scope
  end
end

local ID_PAGE_SIZE = 25

--[[
Get the summary for the thermostats associated with this account.
All options are passed in the thermostatSummaryOptions table.

Expects these values on call:
* session.access_token
* session.token_type
(If it is to be retried if the access_token expired:)
* session.refresh_token

Returns these values on success:
* revisions table
]]--
function getThermostatSummary(session, thermostatSummaryOptions, revisions)

  thermostatSummaryOptions = thermostatSummaryOptions or selectionObject("registered", "")

  if type(thermostatSummaryOptions.selection.selectionMatch) == "table" then

    -- chunk the thermostat IDs into batches of 25 by calling ourselves
    -- recursively but passing stringified chunks of IDs

    local ids = thermostatSummaryOptions.selection.selectionMatch
    revisions = revisions or {}
    for i=1,#ids,ID_PAGE_SIZE do
      j = math.min(#ids, (i+ID_PAGE_SIZE)-1)
      thermostatSummaryOptions.selection.selectionMatch = table.concat(ids, ",", i, j)
      if not getThermostatSummary(session, thermostatSummaryOptions, revisions) then
        revisions = nil
        break
      end
    end
    thermostatSummaryOptions.selection.selectionMatch = ids
    return revisions

  else

    local jsonOptions = json.encode(thermostatSummaryOptions)
    local options = { url = "/home" .. API_ROOT .. "thermostatSummary", method = "GET",
                      headers = { Accept = "application/json", Authorization = session.token_type .. ' ' .. session.access_token } }

    local res = makeRequest(session, options, stringify{ json = jsonOptions, token = session.access_token })

    -- try again if the access_token expired
    if session.error == "14" and session.refresh_token and refreshTokens(session) then
      options = { url = "/home" .. API_ROOT .. "thermostatSummary", method = "GET",
                  headers = { Accept = "application/json", Authorization = session.token_type .. ' ' .. session.access_token } }
      res = makeRequest(session, options, stringify{ json = jsonOptions, token = session.access_token })
    end

    if not session.error and res.revisionList then
      -- replace colon-separated lists with table of tables to hide formatting from API user
      revisions = revisions or {}
      for i,v in ipairs(res.revisionList) do
        local identifier,name,connected,thermostatRev,alertsRev,runtimeRev = string.match(v, "(.-):(.-):(.-):(.-):(.-):(.-)$")
        revisions[identifier] = { name = name, connected = (connected == "true"),
                                  thermostatRev = thermostatRev, alertsRev = alertsRev, runtimeRev = runtimeRev }
      end
      return revisions
    end

  end
end

--[[
Gets thermostats defined by the thermostatsOptions object.

Expects these values on call:
* session.access_token
* session.token_type
(If it is to be retried if the access_token expired:)
* session.refresh_token

Returns these values on success:
* thermostats table
]]--
function getThermostats(session, thermostatsOptions, thermostats)

  if type(thermostatsOptions.selection.selectionMatch) == "table" then

    -- chunk the thermostat IDs into batches of 25 by calling ourselves
    -- recursively but passing stringified chunks of IDs

    local ids = thermostatsOptions.selection.selectionMatch
    thermostats = thermostats or {}
    for i=1,#ids,ID_PAGE_SIZE do
      j = math.min(#ids, (i+ID_PAGE_SIZE)-1)
      thermostatsOptions.selection.selectionMatch = table.concat(ids, ",", i, j)
      if not getThermostats(session, thermostatsOptions, thermostats) then
        thermostats = nil
        break
      end
    end
    thermostatsOptions.selection.selectionMatch = ids
    return thermostats

  else

    local page = 0
    local totalPages = 1

    repeat
      page = page + 1

      if page > 1 then
        thermostatsOptions.page = { page = page }
      end

      local jsonOptions = json.encode(thermostatsOptions)

      local options = { url = "/home" .. API_ROOT .. 'thermostat', method = "GET",
                        headers = { Accept = "application/json", Authorization = session.token_type .. ' ' .. session.access_token } }

      local res = makeRequest(session, options, stringify{ json = jsonOptions, token = session.access_token })

      -- try again if the access_token expired
      if session.error == "14" and session.refresh_token and refreshTokens(session) then
        options = { url = "/home" .. API_ROOT .. 'thermostat', method = "GET",
                    headers = { Accept = "application/json", Authorization = session.token_type .. ' ' .. session.access_token } }
        res = makeRequest(session, options, stringify{ json = jsonOptions, token = session.access_token })
      end

      if not session.error and res.thermostatList then
        thermostats = thermostats or {}
        for i,v in ipairs(res.thermostatList) do
          thermostats[v.identifier] = v
        end
        if res.page and res.page.totalPages then
          totalPages = res.page.totalPages
        end
      else
        thermostats = nil
        break
      end
    until page >= totalPages

    thermostatsOptions.page = nil
    return thermostats

  end
end

--[[
Update thermostats based on the thermostatsUpdateOptions object
Many common update actions have an associated function which are passed in an array
so that multiple updates can be completed at one time. 
Updates are completed in the order they appear in the functions array.

Expects these values on call:
* session.access_token
* session.token_type
(If it is to be retried if the access_token expired:)
* session.refresh_token

Returns these values on success:
* true if no error
]]--
function updateThermostats(session, thermostatsUpdateOptions)

  local options = { url = "/home" .. API_ROOT .. "thermostat?json=true&token=" .. session.access_token,
                    method = "POST",
                    headers = { Accept = "application/json",
                                Authorization = session.token_type .. " " .. session.access_token,
                                ["Content-Type"] = "application/json" } }

  local body = json.encode(thermostatsUpdateOptions)
  local res = makeRequest(session, options, body)
  
  -- try again if the access_token expired
  if session.error == "14" and session.refresh_token and refreshTokens(session) then
    options.url = "/home" .. API_ROOT .. "thermostat?json=true&token=" .. session.access_token
    options.headers.Authorization = session.token_type .. ' ' .. session.access_token
    res = makeRequest(session, options, body)
  end

  return not session.error
end

-- convenience functions

local THERM_OPTIONS = {
  runtime = "includeRuntime",
  extendedRuntime = "includeExtendedRuntime",
  electricity = "includeElectricity",
  settings = "includeSettings",
  location = "includeLocation",
  program = "includeProgram",
  events = "includeEvents",
  devices = "includeDevice",
  technician = "includeTechnician",
  utility = "includeUtility",
  management = "includeManagement",
  alerts = "includeAlerts",
  weather = "includeWeather"
}

--[[
Default options for getThermostats function when using includes

selectionMatch can be a table of thermostat IDs, and it will be converted to
a comma-separated list right before transmission
]]--
function selectionObject(selectionType, selectionMatch, includes)

  local options = { selection = { selectionType=selectionType, selectionMatch=selectionMatch } }

  if includes then
    for k,v in pairs(includes) do
      options.selection[ THERM_OPTIONS[k] ] = v
    end
  end

  return options
end

-- get the hierarchy for EMS thermostats based on the node passed in
-- default node is the root level. EMS Only.
function managementSet(node)
  return selectionObject("managementSet", node or "/")
end

--[[
Default options for getThermostats function

function thermostatsOptions(thermostat_ids,
                            includeEvents,
                            includeProgram,
                            includeSettings,
                            includeRuntime,
                            includeAlerts,
                            includeWeather)

  if type(thermostat_ids) == "table" then
    thermostat_ids = table.concat(thermostat_ids, ",")
  end

  includeEvents   = includeEvents or true
  includeProgram  = includeProgram or true
  includeSettings = includeSettings or true
  includeRuntime  = includeRuntime or true
  includeAlerts   = includeAlerts or false
  includeWeather  = includeWeather or false

  return { selection = { 
    selectionType   = "thermostats",
    selectionMatch  = thermostat_ids,
    includeEvents   = includeEvents,
    includeProgram  = includeProgram,
    includeSettings = includeSettings,
    includeRuntime  = includeRuntime,
    includeAlerts   = includeAlerts,
    includeWeather  = includeWeather } }
end
]]--

--[[
Update options that control how the thermostats update call behaves
]]--
function thermostatsUpdateOptions(selection, functions, thermostat)
  return { selection = selection, functions = functions, thermostat = thermostat }
end

function createVacationFunction(coolHoldTemp, heatHoldTemp)
  return { ["type"] = "createVacation",
           params = { coolHoldTemp=coolHoldTemp, heatHoldTemp=heatHoldTemp } }
end

-- Function passed to the updateThermostats call to resume a program.
function resumeProgramFunction()
  return { ["type"] = "resumeProgram" }
end

-- Function passed to the updateThermostats call to send a message to the thermostat
function sendMessageFunction(text)
  return { ["type"]  = "sendMessage",
           params = { text = text } }
end

-- Function passed to the updateThermostats call to acknowledge an alert
-- Values for acknowledge_type: accept, decline, defer, unacknowledged.
function acknowledgeFunction(thermostat_id, acknowledge_ref, acknowledge_type, remind_later)
  return { ["type"] = "acknowledge",
           params = { thermostatIdentifier = thermostat_id,
                      ackRef = acknowledge_ref,
                      ackType = acknowledge_type,
                      remindMeLater = remind_later } }
end

-- Function passed to the updateThermostats set the occupied state of the thermostat
-- EMS only.
-- hold_type valid values: dateTime, nextTransition, indefinite, holdHours
function setOccupiedFunction(is_occupied, hold_type)
  return { ["type"] = "setOccupied",
           params = { occupied = is_occupied,
                      holdType = hold_type } }
end

-- Function passed to the thermostatsUpdate call to set a temperature hold. Need to pass both
-- temperature params.
-- holdType valid values: dateTime, nextTransition, indefinite, holdHours
function setHoldFunction(coolHoldTemp, heatHoldTemp, holdType, holdHours)
  return { ["type"] = "setHold",
           params = { coolHoldTemp = coolHoldTemp, heatHoldTemp = heatHoldTemp,
                      holdType = holdType, holdHours = holdHours } }
end

-- Object that represents a climate.
function climateObject(climate_data)
	return { name = climate_data.name,
           climateRef = climate_data.climateRef,
           isOccupied = climate_data.isOccupied,
           coolFan = climate_data.coolFan,
           heatFan = climate_data.heatFan,
           vent = climate_data.vent,
           ventilatorMinOnTime = climate_data.ventilatorMinOnTime,
           owner = climate_data.owner,
           ["type"] = climate_data["type"],
           coolTemp = climate_data.coolTemp,
           heatTemp = climate_data.heatTemp }
end

--[[
TBD

/**
 * Represents a program and various actions that can be performed on one
 */
ecobee.ProgramObject = function(schedule_object, climates_array) {
	return {
			schedule : schedule_object,
			climates : climates_array,
			getProgram : function() {
				return {
					schedule : this.schedule.schedule,
					climates : this.climates
				};
			},
			validate : function() {
				var climateHash = {},
					climateIndex,
					dayIndex,
					timeIndex;

				for(climateIndex in this.climates) {
					if(climateHash[this.climates[climateIndex].climateRef]) {
						throw new Error('duplicate climate refs exist: ' + this.climates[climateIndex].climateRef);
					}
					climateHash[this.climates[climateIndex].climateRef] = true;
				}

				for(dayIndex in schedule) {
					for(timeIndex in shedule[dayIndex]) {
						if(!climateHash[schedule[dayIndex][timeIndex] ]) {
							throw new Error('invalid program. ' + schedule[dayIndex][timeIndex] + ' climate does not exist');
						}
					}
				}

				return true;
			}
	}
}
/**
 * holds the schedule that goes with a program. Each item in the schedule array is a string climateRef that points 
 * to a climate obnject
 */
ecobee.ScheduleObject = function(scheduleArray) {
	
	return {schedule : scheduleArray || [
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null],
						[null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]
						],
			getSchedule : function() {
				return this.schedule;
			},
			updateScheduleNode : function(dayIndex, timeIndex, climateRef) {

				this.schedule[dayIndex][timeIndex] = climateRef;	
			},
			getScheduleNode : function(dayIndex, timeIndex) {
				return this.shedule[dayIndex][timeIndex];
			} 
		  };
};

]]--

