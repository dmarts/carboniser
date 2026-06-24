# carboniser (UK Carbon Intensity utility)

<img width="327" height="365" alt="image" src="https://github.com/user-attachments/assets/4c246d2d-55fb-4a8e-bb63-e791157318a5" />

## What is this?
Carboniser is a simple macos app, inspired by a feature on [octopus.energy](https://octopus.energy/).  It runs in your status bar and tells you the current 'carbon intensity' in your UK region.  If conditions are met, it suggests you disconnect mains/grid power for a while - it does this if:
- Your battery is quite full
- You're currently connected to grid power
- Carbon intensity is high

### Why?
The logic is that if your battery is full, and you're plugged in, you could probably disconnect for a while and run on battery power.  If power in your region is being generated from fossil fuels, you could run on battery power for a while with the hope that after a few hours the intensity might have dropped and you can charge up again with green electrons :)

The data for this utility is provided by [NESO](https://www.neso.energy/about-neso/our-progress-towards-net-zero/carbon-intensity-dashboard) and [their API](https://carbonintensity.org.uk/).

If you're generating or storing your own power at home (solar / battery) then this logic doesn't necessarily apply.  This widget can't tell whether you're charging your laptop battery from the grid, or from your home battery.

### Using the information for other appliances
The dialog will also tell you the next major change in the carbon intensity forecast for your region, e.g. 'getting less polluting in 3 hours'.  While the carbon 'saving' from deferring charging is small on a modern Mac device, you might also choose to bring forward or delay electricity consumption e.g. running a dishwasher.  A washing machine can use 0.5-1kWh per cycle, so deferring a cycle from CI=250g to CI=100g could save up to 150g.  Over a year this could save the equivalent of ~200 miles of driving for each household using the app.

## How?
### Install
Download the latest `.zip` file from the '[Releases](https://github.com/dmarts/carboniser/releases)' page, extract it, and drag to your Applications folder.

### Configure
Choose your region from the dropdown.  The app doesn't do any geolocation (yet!).  To find your location, you can check [here](https://carbonintensity.org.uk/) or use [this map](https://api.neso.energy/dataset/bf3d723b-b4ae-4ec7-9fc9-e584c651a9da/resource/1d817f4c-a126-45c8-baf0-218bf57d37be/download/neso-ci-regional-methodology_v2.pdf):

<img width="587" height="807" alt="image" src="https://github.com/user-attachments/assets/629503f9-1999-43c2-9b26-1df7d34858de" />



If you don't get any popup alerts on your device, you may need to enable them in your System Settings by allowing notifications from carboniser.

### Use
If you're alerted to do so, consider unplugging your power adapter.  Similarly if you see a leaf icon, it could be a good time to run energy-intensive but time-insensitive things like the dishwasher or washing.

## Contribute
Pull requests or suggestions are always welcome.
