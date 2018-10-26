---
title: Vera Plugin for Ecobee Thermostats
layout: page
---

## Purpose ##
This plugin will monitor and control your [ecobee][] thermostat(s) through your [Vera][] home controller.  If you have remote sensors connected to your thermostat, they should also be accessible via this plugin.

[ecobee]: http://www.ecobee.com
[vera]: http://www.micasaverde.com

## Features ##

* Monitor thermostat mode, fan mode, current and set point temperatures, humidity level, running states, current event (if any) and current climate.
* If remote sensors are connected to your Ecobee thermostat, they should appear in the plugin as motion, temperature or humidity sensors, depending on what has been made available from the API.
* Change HVAC mode and set indefinite holds for temperature set points and fan mode, and allow the program to resume from these holds.
* Set hold events for comfort settings (formerly called climates) or issue SwitchOccupancy events (for EMS thermostats) to set and monitor an "away" state.
* Perform common functions, such as sending a text message or resuming the program, to an individual thermostat or a group of thermostats.

<figure>
  <img src="images/screen-shot.jpg" alt="Devices in Vera">
  <figcaption>An example of the Ecobee devices shown in Vera (UI5).</figcaption>
</figure>

<figure>
  <img src="images/sensor-devices.jpg" alt="Devices in Vera">
  <figcaption>An example of the Ecobee remote sensor devices shown in Vera (UI5).</figcaption>
</figure>


## How to Use the Plugin ##

First, login to your web portal at [ecobee][] (and switch to the [settings tab][] if you are using the pre-ecobee3 portal).  Familiarize yourself with the portal, and Choose `My Apps` on the left edge of the screen to enable that view.  Leave this browser window open before proceeding to the next step.

[settings tab]: https://www.ecobee.com/home/secure/settings.jsf

### Plugin Authorization with ecobee.com ###

Ecobee uses the [OAuth 2.0](http://oauth.net/) framework for authorizing client applications, such as this plugin.  The practical implication of this is that you do not specify your user name and password in the plugin's settings; instead you grant access by entering a four-character PIN in the ecobee web portal when presented with one by the plugin.

Upon installing the ecobee plugin, press the `Get PIN` button on the ecobee device.  The plugin will attempt to connect with the ecobee.com servers and obtain a four-character PIN in order to authorize the plugin to access your ecobee.com account.  This PIN will be displayed on the Vera dashboard on the ecobee device that was created at installation.

<figure>
  <img src="images/register-pin.jpg" alt="ecobee device prompting to register PIN at ecobee.com">
  <figcaption>The PIN is displayed on the ecobee device that was created at installation.</figcaption>
</figure>

Once you see it, you then have ten minutes or less to enter this PIN in the My Apps widget in your ecobee.com web portal.  If the PIN expires, you will have to press the `Get PIN` button again to request a new PIN.

Also, you may want to mark your calendar for next year because this authorization expires after one year.  External events may also invalidate the authorization sooner, which will present you with a "task" message at the top of the Vera UI for you to request a new PIN.

### Choosing which thermostats to monitor and control ###

_If you are a **non-commercial customer**, the default values should work for you and **you can skip this section**.  Otherwise, perform this step now._

<figure>
  <img src="images/advanced-tab.jpg" alt="Advanced tab of the ecobee device">
  <figcaption>If you are an Energy Management System (EMS) commercial customer, you must also set values for three variables on the Advanced tab of the ecobee device.
  </figcaption>
</figure>

The variables are `scope`, `selectionType` and `selectionMatch` and must be set according to the following rules:

| `scope` | `selectionType` | `selectionMatch` | examples              |
|---------|-----------------|:-----------------|:----------------------|
| **ems** | **thermostats**   | comma-separated list of thermostat identifiers (no spaces and 25 identifiers maximum) | 276075669054,276181238912 |
| **ems** | **managementSet** | path to the management set of thermostats (these sets are managed through the ecobee.com EMS Management Portal.) | /Washington/Warren/Floor2<br />/ |

_If you changed the value of the `scope` variable, also completely empty the `auth\_token` field so that the plugin can request a new PIN using the proper account type._

If you are non-commercial customer, these variables must be set like this (a `selectionType` of `registered` is the plugin's default setting):

| `scope` | `selectionType` | `selectionMatch` | examples              |
|---------|-----------------|:-----------------|:----------------------|
| **smartWrite** | **thermostats**   | comma-separated list of thermostat identifiers (no spaces and 25 identifiers maximum) | 276075669054,276181238912 |
| **smartWrite** | **registered** | | (`selectionMatch` is empty)|


_Please make sure that you specify the proper upper- and lowercase letters when entering the above variable values._

After you have entered the PIN in your My Apps widget at ecobee.com, on the next polling cycle the plugin will attempt to retrieve information about the thermostats that you specified in the selection criteria above.  The plugin will create a thermostat, humidistat and home/away switch device for each thermostat it discovers.  It will name each device as it is named in the thermostat itself, or if there is no name, it will name the device using the thermostat's unique identifier.  You can change this name in the Advanced tab of the device.


## Controlling the Precision of Reported Temperatures ##

The Ecobee thermostat internally reports temperatures in tenths of Fahrenheit degrees, but by default the plugin will report whole number degrees (regardless of whether Fahrenheit or Celsius temperature scales are used). You can control this, however, by specifying your preferred rounding precision with a device variable on the main Ecobee device called `TemperaturePrecision` (as of v1.4 of the plugin). The value you provide is the denominator D in the fraction 1/D, the fractional value to which the temperature should be rounded. For example, providing 2 means that temperatures will be rounded to the nearest 1/2 (0.5) of a degree. Providing 10 would round to the nearest tenth (0.10) of a degree.

The default value for `TemperaturePrecision` is 1, meaning only whole degrees are reported by default.

### Notes

* This feature will not allow you to change the setpoint sliders in the user interface to fractional values; that is outside the scope of the plugin.
* Using this feature may cause unwanted side-effects that are outside the scope of the plugin’s control. Please test your configuration thoroughly before determining that a non-1 value is for you.
* This feature is agnostic to whether you display temperatures in Fahrenheit or Celsius, but it may be of more value to Celsius users to set `TemperaturePrecision` to 2 to achieve near-Fahrenheit granularity.

## UPnP Devices ##

This plugin creates four different kinds of devices in Vera.  The ecobee device is the parent device of the other device types, and will create and delete them as they appear and disappear from your ecobee.com account.

### ecobee device ###

Device type: `urn:schemas-ecobee-com:device:Ecobee:1`

Implements these services:

* `urn:ecobee-com:serviceId:Ecobee1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:ecobee-com:serviceId:Ecobee1 | status | `0` when there is no valid access token for ecobee.com, `1` otherwise |
| urn:ecobee-com:serviceId:Ecobee1 | selectionType | Set to `registered`, `thermostats` or `managementSet` per above instructions |
| urn:ecobee-com:serviceId:Ecobee1 | selectionMatch | Set to a list of thermostat IDs or a manangement set node per above instructions |
| urn:ecobee-com:serviceId:Ecobee1 | scope | Set to either `smartWrite` or `ems` per above instructions |

### Thermostat ###

Device type: `urn:schemas-upnp-org:device:HVAC_ZoneThermostat:1`

Implements these services:

* `urn:upnp-org:serviceId:HVAC_FanOperatingMode1`
* `urn:upnp-org:serviceId:HVAC_UserOperatingMode1`
* `urn:upnp-org:serviceId:TemperatureSensor1`
* `urn:upnp-org:serviceId:TemperatureSetpoint1_Heat`
* `urn:upnp-org:serviceId:TemperatureSetpoint1_Cool`
* `urn:micasaverde-com:serviceId:HVAC_OperatingState1`
* `urn:micasaverde-com:serviceId:EnergyMetering1`
* `urn:micasaverde-com:serviceId:HaDevice1`
* `urn:ecobee-com:serviceId:Ecobee1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:upnp-org:serviceId:TemperatureSensor1 | CurrentTemperature | current temperature in Vera's temperature scale |
| urn:upnp-org:serviceId:TemperatureSetpoint1_Heat | CurrentSetpoint | current heat setpoint |
| urn:upnp-org:serviceId:TemperatureSetpoint1_Cool | CurrentSetpoint | current cool setpoint |
| urn:upnp-org:serviceId:HVAC_FanOperatingMode1 | Mode | current fan operating mode |
| urn:upnp-org:serviceId:HVAC_FanOperatingMode1 | FanStatus | `On` or `Off` |
| urn:upnp-org:serviceId:HVAC_UserOperatingMode1 | ModeStatus | HVAC mode |
| urn:micasaverde-com:serviceId:HVAC_OperatingState1 | ModeState | Current running status |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |
| urn:micasaverde-com:serviceId:EnergyMetering1 | UserSuppliedWattage | `0,0,0` |

### Humidistat ###

Device type: `urn:schemas-ecobee-com:device:EcobeeHumidistat:1`

Implements these services:

* `urn:micasaverde-com:serviceId:HumiditySensor1`
* `urn:micasaverde-com:serviceId:HaDevice1`
* `urn:ecobee-com:serviceId:Ecobee1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:micasaverde-com:serviceId:HumiditySensor1 | CurrentLevel | current relative humidity percentage |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |

### House ###

Device type: `urn:schemas-ecobee-com:device:EcobeeHouse:1`

Implements these services:

* `urn:upnp-org:serviceId:SwitchPower1`
* `urn:micasaverde-com:serviceId:HaDevice1`
* `urn:ecobee-com:serviceId:Ecobee1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:upnp-org:serviceId:SwitchPower1 | Status | `1` if home or `0` otherwise |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |
| urn:ecobee-com:serviceId:Ecobee1 | currentClimateRef | The current climate reference, like `home`, `away`, `wakeup` and `sleep`. |
| _The following variables are only set when the device is first created, and are not kept in sync if they are changed.  This is done in order to conserve bandwidth and processing time.  Delete the device if you wish it to be re-created with current values._ |
| urn:ecobee-com:serviceId:Ecobee1 | StreetAddress | The thermostat location street address. |
| urn:ecobee-com:serviceId:Ecobee1 | City | The thermostat location city. |
| urn:ecobee-com:serviceId:Ecobee1 | ProvinceState | The thermostat location state or province. |
| urn:ecobee-com:serviceId:Ecobee1 | Country | The thermostat location country. |
| urn:ecobee-com:serviceId:Ecobee1 | PostalCode | The thermostat location ZIP or Postal code. |
| urn:ecobee-com:serviceId:Ecobee1 | PhoneNumber | The thermostat owner's phone number. |
| urn:ecobee-com:serviceId:Ecobee1 | MapCoordinates | The lat/long geographic coordinates of the thermostat location. |

### Occupancy Sensors ###

If you have remote motion sensors connected to your thermostat, the plugin will create devices in Vera.  Refer to Ecobee for how these devices report motion or occupancy.

Device type: `urn:schemas-micasaverde-com:device:MotionSensor:1`

Implements these services:

* `urn:micasaverde-com:serviceId:SecuritySensor1`
* `urn:micasaverde-com:serviceId:HaDevice1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:micasaverde-com:serviceId:SecuritySensor1 | Tripped | `1` if tripped or `0` otherwise |
| urn:micasaverde-com:serviceId:SecuritySensor1 | Armed | `1` if armed or `0` otherwise |
| urn:micasaverde-com:serviceId:SecuritySensor1 | LastTrip | seconds since the Epoch GMT since device tripped |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |

### Temperature Sensors ###

If you have remote temperature sensors connected to your thermostat, the plugin will create devices in Vera.

Device type: `urn:schemas-micasaverde-com:device:TemperatureSensor:1`

Implements these services:

* `urn:upnp-org:serviceId:TemperatureSensor1`
* `urn:micasaverde-com:serviceId:HaDevice1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:upnp-org:serviceId:TemperatureSensor1 | CurrentTemperature | current temperature or -500 (F) if unknown |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |

### Humidity Sensors ###

If you have remote humidity sensors connected to your thermostat, the plugin will create devices in Vera.

Device type: `urn:schemas-micasaverde-com:device:HumiditySensor:1`

Implements these services:

* `urn:upnp-org:serviceId:HumiditySensor1`
* `urn:micasaverde-com:serviceId:HaDevice1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:upnp-org:serviceId:HumiditySensor1 | CurrentLevel| current relative humidity level (percent) or 0 if unknown |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |


## UPnP Actions ##

In addition to the standard thermostat actions, your Vera automation can also perform the following actions on a specific thermostat.  The main ecobee device also implements these actions, in which case the action is applied to all thermostats that match the `selectionType` and `selectionMatch` you specified above.

### ResumeProgram ###

Remove the active event and resume the thermostat's program, or enter the next event in the stack if one exists.

This action has no parameters.

### SendMessage ###

Send a text message to a thermostat's display screen.  The text message can be up to 500 characters long.

| Parameter   | Direction | Value                         |
|:------------|:----------|:------------------------------|
| MessageText | In        | Up to 500 characters of text. |

### SetClimateHold ###

Set a hold event to the setpoint and fan settings contained within a named climate reference, like `home`, `away`, `wakeup` and `sleep`.

| Parameter      | Direction | Value                         |
|:-----------   -|:----------|:------------------------------|
| HoldClimateRef | In        | The named climate reference.  |


## Notes and Limitations ##

* Works with Vera UI5 1.5.408 or later.    These days, it is only being tested on UI5 1.5.622.  There are issues on UI7 whose solutions are either not possible or not documented.

* Updates to the state of thermostat and humidistat devices can take up to the polling number of seconds (180 by default) to be reflected in the UPnP devices (or as quickly as 5 seconds).

[forum]: http://forum.micasaverde.com/index.php?topic=13836

* The humidistat device currently only implements the humidity sensor service.

## License ##

Copyright &copy; 2013-2016  John W. Cocula and others

Portions of this program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>

The source code repository and issue list can be located at <https://github.com/watou/vera-ecobee>.

House icon copyright [Alexander Moore](http://www.mricons.com/show/iconset:vista-inspirate-icons).

## Questions? Suggestions?  ##

Please contact other users through the [micasaverde.com forum][forum] for questions or suggested improvements.  

## Thanks ##

Thanks to [ecobee][] and their enthusiastic customers, and the helpful contributors on the [Mi Casa Verde forum](http://forum.micasaverde.com).

## Future Plans ##

* See about integrating historical energy usage data into the plugin.
* Report the heating or cooling stage, since ecobee supports multiple heating and cooling stages.
* More automation.
* Monitor and manage ecobee's Smart Plugs as individual `urn:schemas-upnp-org:device:BinaryLight:1` devices when used with Smart thermostats.
* Implement Humidistat functionality to control humidity from Vera and report running state of humidifier and/or dehumidifier.

See and submit more on [Github](https://github.com/watou/vera-ecobee/issues?page=1&state=open).

## History ##

### 2018-10-26    v1.9

Plugin stopped working, most likely due to dropping of support for TLS older than 1.2.

Fixes:

* TLS 1.0 no longer supported [#42](https://github.com/watou/vera-ecobee/issues/42)

### 2017-03-24    v1.8

Fixes and enhancements:

Updated versions after v1.7 have been customized for UI7 and the ecobee3. Though it still should work with UI5 and older ecobee models, the configurations have not been tested.

The plugin is designed to mimic the vera UI7 house modes: "home", "away", "sleep" and "vacation".

The ecobee3 API has the first 3 modes by default. The first additional mode created will be sent by the API as "smart1" mode. The plugin assumes that "smart1" is your vacation mode. Every subsequent mode created on your ecobee will be named "smart2", "smart3" etc... In order for the plugin to function correctly, please make sure that the first mode you created on the ecobee 3 is the vacation comfort setting.

v1.8 changes from v1.7:

* Sleep mode now reflected as "occupied" by the housemode icon
* mode selection in the scene editor
* eliminated the control tab and moved controls to the main device screen
* fixed mode selection on the device control screen
* changed order of the ecobee "comforts settings" to match vera "house modes" order
* edit readme page with instructions for use of the "vacation" comfort setting.

### 2016-04-13    v1.6

Fixes and enhancements:

* Add holdType variable to each thermostat ([#24](https://github.com/watou/vera-ecobee/issues/24))
* Adjust to OAuth2 changes ([#25](https://github.com/watou/vera-ecobee/issues/25))
* Add temperature setpoint for UI7 ([#26](https://github.com/watou/vera-ecobee/issues/26))

### 2016-02-19    v1.5

Fixes:

* Auth tokens are still prematurely discarded ([#23](https://github.com/watou/vera-ecobee/issues/23))

### 2016-01-17    v1.4

Fixes and enhancements:

* Let user choose precision of reported temperatures ([#19](https://github.com/watou/vera-ecobee/issues/19))
* Recognize only the currently running event for currentClimateRef/currentEventType ([#20](https://github.com/watou/vera-ecobee/issues/20))
* Token issue with ecobee API #21 ([#21](https://github.com/watou/vera-ecobee/issues/21))
* Added humidity mode state to humidistat device ([#22](https://github.com/watou/vera-ecobee/issues/22))

### 2015-08-10    v1.3

Fixed:

* Triggers not firing for changes in currentClimateRef ([#17](https://github.com/watou/vera-ecobee/issues/17))
* Auth token discarded too eagerly ([#18](https://github.com/watou/vera-ecobee/issues/18))

### 2015-06-09    v1.2

Fixes and enhancements:

* Point to official api.ecobee.com endpoints ([#11](https://github.com/watou/vera-ecobee/issues/11))
* Repoint external icon references to http://watou.github.io/vera-ecobee/icons/*.png ([#12](https://github.com/watou/vera-ecobee/issues/12))
* Map home/away buttons to set hold for named climates for non-EMS thermostats ([#13](https://github.com/watou/vera-ecobee/issues/13))
* Add temperature, humidity and/or motion devices for remote sensors ([#14](https://github.com/watou/vera-ecobee/issues/14))
* Change min poll frequency to 3 minutes per API docs ([#16](https://github.com/watou/vera-ecobee/issues/16))

### 2015-05-29    v1.1

Fixed:

* Removed bad Vera version checking code so it works on UI7. ([#7](https://github.com/watou/vera-ecobee/issues/7))
* Removed situation where when Vera loses our device variables, we try to refresh our tokens with stale tokens

### 2014-06-13    v1.0

Enhancements:

* Made possible by a recent update to the Ecobee API, the thermostat device now reports the current running state of equipment connected to the thermostat, through the `ModeState` variable. There is a new automation trigger that will run a scene based on the various possible values for `ModeState`.
* The Vera web UI now shows the current running state on the thermostat's dashboard, under the fan options (see the screenshot at the top of this page).
* The `FanStatus` now correctly reports `On` or `Off` depending on whether the fan is currently running.

### 2014-01-16    v0.9

Fixed:

* GetModeTarget always returns AutoChangeOver ([#4](https://github.com/watou/vera-ecobee/issues/4))
* Remove all code/doc for multiple app instance restrictions ([#5](https://github.com/watou/vera-ecobee/issues/5))
* Do not forget tokens on API "auth" errors, only on refresh request ([#6](https://github.com/watou/vera-ecobee/issues/6))

### 2013-06-17    v0.8
  
* Worked around file name clash on service ID `urn:upnp-org:serviceId:HouseStatus1`.

### 2013-05-31    v0.7

* Now require users to request a PIN from ecobee.com by pressing the `Get PIN` button on the ecobee device on the Vera dashboard.
