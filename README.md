# carboniser (UK Carbon Intensity utility)

## What is?
Carboniser is a simple macos app, inspired by a feature on [octopus.energy](https://octopus.energy/).  It runs in your status bar and tells you the current 'carbon intensity' in your UK region.  If conditions are met, it suggests you disconnect mains/grid power for a while - it does this if:
- Your battery is quite full
- You're currently connected to grid power
- Carbon intensity is high

The logic is that if your battery is full, and you're plugged in, you could probably disconnect for a while and run on battery power.  If power in your region is being generated from fossil fuels, you could run on battery power for a while with the hope that after a few hours the intensity might have dropped and you can charge up again with green electrons :)

If you're generating or storing your own power at home (solar / battery) then this logic doesn't necessarily apply.  This widget can't tell whether you're charging your laptop battery from the grid, or from your home battery.

## How?
### Install
Download the latest `.zip` file from the 'Releases' page, extract it, and drag to your Applications folder.

### Configure
Choose your region from the dropdown.  The app doesn't do any geolocation (yet!).

If you don't get any popup alerts, you may need to enable them in your System Settings.

### Use
If you're alerted to do so, consider unplugging your power adapter.  Similarly if you see a leaf icon, it could be a good time to run energy-intensive but time-insensitive things like the dishwasher or washing.

## Contribute
Pull requests or suggestions are always welcome.
