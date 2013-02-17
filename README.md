<!--	Vera Plugin for ecobee Thermostats	-->

![Devices in Vera](http://cocu.la/vera/ecobee/shot1.jpg)

## Purpose ##
This plugin will monitor and control your [ecobee][] thermostat(s) through your [Vera][] home automation gateway.

[ecobee]: http://www.ecobee.com
[vera]: http://www.micasaverde.com

## Features ##

* Monitor thermostat mode, fan mode, current and set point temperatures, humidity level and running states.

* Control temperature set points, thermostat mode and fan mode.

## How to Use the Plugin ##

Upon installing the ecobee plugin, it will attempt to connect with the ecobee.com servers and obtain a four-character PIN, in order to authorize the plugin to access your `ecobee.com` account.  This PIN will be displayed on the ecobee device that was created on installation.  You then have about ten minutes to enter this PIN in the My Apps widget in your `ecobee.com` web portal.  Also choose a polling frequency (in seconds) if you want to poll more or less often than the default 120 seconds.  You may not poll more often than every 60 seconds, as this might be considered abusive by the `ecobee.com` servers.

### Choosing which thermostats to monitor and control ###

If you are a non-commercial customer with one or more ecobee SI thermostats, you can skip this section.

If you are an EMS (energy management system) commercial customer, you must also set values for two variables on the Advanced tab of the ecobee device.  The variables are `selectionType` and `selectionMatch` and must be set according to the following rules:

<table>
<tr><th>selectionType</th><th>selectionMatch</th><th>examples</th></tr>
<tr><td>thermostats</td><td>comma-separated list of thermostat identifiers (no spaces and 25 identifiers maximum)</td><td>276075669054,276181238912</td></tr>
<tr><td>managementSet</td><td>path to the management set of thermostats (these sets are managed through the ecobee.com EMS Management Portal.)</td><td>/Washington/Warren/Floor2<br />/</td></tr>
</table>

*Note:* Please make sure that you specify the proper upper- and lowercase letters for `thermostats` and `managementSet`.

After the initial polling interval, the plugin will attempt to retrieve information about the thermostats that you specified in the selection criteria above.  The plugin will create a thermostat and humidistat device for each thermostat it discovers.  It will name each device as it is named in the thermostat itself, or if there is no name, it will name the device using the thermostat's serial number.  You can change this name in the Advanced tab of the thermostat and/or humidistat devices with no ill effects.

## Notes and Limitations ##

* Only works with Vera UI5 1.5.408 or later.

* Updates to the state of thermostat and humidistat devices can take up to the polling number of seconds (120 by default) to be reflected in the UPnP devices (or as quickly as 5 seconds).

[me]: http://forum.micasaverde.com/index.php?action=profile;u=19018

* The humidistat device currently only implements the humidity sensor service.

* The thermostat device creates the `UserSuppliedWattage` variable, set initially to `0,0,0`, but it doesn't yet do anything else to implement the `urn:micasaverde-com:serviceId:EnergyMetering1` service.

## License ##

Copyright &copy; 2013  John W. Cocula and others

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>

The source code repository and issue list can be located at <https://github.com/watou/vera-ecobee-thermostat>.

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

`futzle`, `garretwp`, `guessed`, `RichardTSchaefer` and others on the forum for their kind assistance.
`hugheaves` for his `decompressScript` shell script workaround for the problem with deploying compressed modules and for providing his open-source plugin for a different make/model thermostat.

## Future Plans ##

* See about integrating historical energy usage data into the plugin.
* Report the heating or cooling stage, since ecobee supports multiple heating and cooling stages.
* More automation.
* Implement Humidistat functionality to control humidity from Vera.

## History ##

### 2013-0X-XX    v0.5

* Initial plugin upload to <http://apps.mios.com>

