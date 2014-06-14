<!--	Vera Plugin for ecobee Thermostats	-->


![Devices in Vera](http://cocu.la/vera/ecobee/images/shot5.jpg)

## Purpose ##
This plugin will monitor and control your [ecobee][] thermostat(s) through your [Vera][] home controller.

[ecobee]: http://www.ecobee.com
[vera]: http://www.micasaverde.com

## Features ##

* Monitor thermostat mode, fan mode, current and set point temperatures, humidity level, running states, current event (if any) and current climate.
* Change HVAC mode and set indefinite holds for temperature set points and fan mode, and allow the program to resume from these holds.
* Use a QuickSave-like hold event (for Smart thermostats) or SwitchOccupancy event (for EMS thermostats) to set and monitor an "away" state.
* Perform common functions, such as sending a text message or resuming the program, to an individual thermostat or a group of thermostats.

## How to Use the Plugin ##

First, login to your web portal at [ecobee][] and switch to the [settings tab][].  Familiarize yourself with the portal, and Choose `My Apps` on the left edge of the screen to enable that view.  Leave this browser window open before proceeding to the next step.

[settings tab]: https://www.ecobee.com/home/secure/settings.jsf

### Plugin Authorization with ecobee.com ###

Ecobee uses the [OAuth 2.0](http://oauth.net/) framework for authorizing client applications, such as this plugin.  The practical implication of this is that you do not specify your user name and password in the plugin's settings; instead you grant access by entering a four-character PIN in the ecobee web portal when presented with one by the plugin.

Upon installing the ecobee plugin, press the `Get PIN` button on the ecobee device.  The plugin will attempt to connect with the ecobee.com servers and obtain a four-character PIN in order to authorize the plugin to access your ecobee.com account.  This PIN will be displayed on the Vera dashboard on the ecobee device that was created at installation.

![ecobee device prompting to register PIN at ecobee.com](http://cocu.la/vera/ecobee/images/shot4b.jpg)

Once you see it, you then have ten minutes or less to enter this PIN in the My Apps widget in your ecobee.com web portal.  If the PIN expires, you will have to press the `Get PIN` button again to request a new PIN.

Also, you may want to mark your calendar for next year because this authorization expires after one year.  External events may also invalidate the authorization sooner, which will present you with a "task" message at the top of the Vera UI for you to request a new PIN.

### Choosing which thermostats to monitor and control ###

_If you are a **non-commercial customer**, the default values should work for you and **you can skip this section**.  Otherwise, perform this step now._

If you are an Energy Management System (EMS) commercial customer, you must also set values for three variables on the Advanced tab of the ecobee device.

![Advanced tab of the ecobee device](http://cocu.la/vera/ecobee/images/shot2a.jpg)

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

* `urn:upnp-org:serviceId:HouseStatus1`
* `urn:upnp-org:serviceId:SwitchPower1`
* `urn:micasaverde-com:serviceId:HaDevice1`
* `urn:ecobee-com:serviceId:Ecobee1`

Variables:

| Service ID | Variable | Value |
|:-----------|:---------|:------|
| urn:upnp-org:serviceId:HouseStatus1 | OccupancyState | `Occupied` or `Unoccupied` |
| urn:upnp-org:serviceId:SwitchPower1 | Status | `0` if unoccupied or `1` if occupied |
| urn:micasaverde-com:serviceId:HaDevice1 | LastUpdate | seconds since the Epoch GMT since device updated |
| urn:micasaverde-com:serviceId:HaDevice1 | CommFailure | `0` if connected, `1` if not |
| _The following variables are only set when the device is first created, and are not kept in sync if they are changed.  This is done in order to conserve bandwidth and processing time.  Delete the device if you wish it to be re-created with current values._ |
| urn:ecobee-com:serviceId:Ecobee1 | StreetAddress | The thermostat location street address. |
| urn:ecobee-com:serviceId:Ecobee1 | City | The thermostat location city. |
| urn:ecobee-com:serviceId:Ecobee1 | ProvinceState | The thermostat location state or province. |
| urn:ecobee-com:serviceId:Ecobee1 | Country | The thermostat location country. |
| urn:ecobee-com:serviceId:Ecobee1 | PostalCode | The thermostat location ZIP or Postal code. |
| urn:ecobee-com:serviceId:Ecobee1 | PhoneNumber | The thermostat owner's phone number. |
| urn:ecobee-com:serviceId:Ecobee1 | MapCoordinates | The lat/long geographic coordinates of the thermostat location. |


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


## Notes and Limitations ##

* Works with Vera UI5 1.5.408 or later.    These days, it is only being tested on UI5 1.5.622.

* Updates to the state of thermostat and humidistat devices can take up to the polling number of seconds (60 by default) to be reflected in the UPnP devices (or as quickly as 5 seconds).

[me]: http://forum.micasaverde.com/index.php?action=profile;u=19018

* The humidistat device currently only implements the humidity sensor service.

## License ##

Copyright &copy; 2013-2014  John W. Cocula and others

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>

The source code repository and issue list can be located at <https://github.com/watou/vera-ecobee-thermostat>.

House icon copyright [Alexander Moore](http://www.mricons.com/show/iconset:vista-inspirate-icons).

## Feedback  ##

Please contact me through the [micasaverde.com forum][me].  All tips are gratefully accepted!

<div  style="text-align:center">
<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="QUZULJ2GPLY7L">
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
</div>

## Thanks ##

Thanks to [ecobee][] and their enthusiastic customers, and the helpful contributors on the [Mi Casa Verde forum](http://forum.micasaverde.com).

## Future Plans ##

* See about integrating historical energy usage data into the plugin.
* Report the heating or cooling stage, since ecobee supports multiple heating and cooling stages.
* More automation.
* Monitor and manage ecobee's Smart Plugs as individual `urn:schemas-upnp-org:device:BinaryLight:1` devices when used with Smart thermostats.
* Implement Humidistat functionality to control humidity from Vera and report running state of humidifier and/or dehumidifier.

See and submit more on [Github](https://github.com/watou/vera-ecobee-thermostat/issues?page=1&state=open).

## History ##

### 2014-06-13    v1.0

Enhancements:

* Made possible by a recent update to the Ecobee API, the thermostat device now reports the current running state of equipment connected to the thermostat, through the `ModeState` variable. There is a new automation trigger that will run a scene based on the various possible values for `ModeState`.
* The Vera web UI now shows the current running state on the thermostat's dashboard, under the fan options (see the screenshot at the top of this page).
* The `FanStatus` now correctly reports `On` or `Off` depending on whether the fan is currently running.

### 2014-01-16    v0.9

Fixed:

* GetModeTarget always returns AutoChangeOver ([#4](https://github.com/watou/vera-ecobee-thermostat/issues/4))
* Remove all code/doc for multiple app instance restrictions ([#5](https://github.com/watou/vera-ecobee-thermostat/issues/5))
* Do not forget tokens on API "auth" errors, only on refresh request ([#6](https://github.com/watou/vera-ecobee-thermostat/issues/6))

### 2013-06-17    v0.8
  
* Worked around file name clash on service ID `urn:upnp-org:serviceId:HouseStatus1`.

### 2013-05-31    v0.7

* Now require users to request a PIN from ecobee.com by pressing the `Get PIN` button on the ecobee device on the Vera dashboard.
