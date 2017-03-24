Please see the documentation <a href="http://watou.github.io/vera-ecobee/">here</a>.


Updated versions after 1.7 have been customized for UI7 and the ecobee3. Though it still should work with UI5 and older ecobee models, the configurations have not been tested.

The plugin is designed to mimic the vera UI7 house modes: "home", "away", "sleep" and "vacation".

The ecobee 3 API has the first 3 modes by default. The first additional mode created will be sent by the API as "smart1" mode. The plugin assumes that "smart1" is your vacation mode. Every subsequent mode created on your ecobee will be named "smart2", "smart3" etc...
In order for the plugin to function correctly, please make sure that the first mode you created on the ecobee 3 is the vacation comfort setting.
