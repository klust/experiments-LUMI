# Status

UPDATE: The root issue is that the X11 bundle we were using, also secretly installed
a GLib version that was too old for other things we wanted to do. So if X11 was loaded
after GLib, packages picked up the older GLib which broke things.

So everything in here now works as expected, and we hav extended the cairo EasyConfig.
