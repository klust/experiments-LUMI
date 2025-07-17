# Status

UPDATE: The root issue is that the X11 bundle we were using, also secretly installed
a GLib version that was too old for other things we wanted to do. So if X11 was loaded
after GLib, packages picked up the older GLib which broke things.


## cairo

There are two suspicious lines in the output of the configure step that need further 
investigation:

```
Run-time dependency gobject-2.0 found: YES 2.72.2
Run-time dependency glib-2.0 found: YES 2.72.2
```

This is likely where the trouble starts in the subsequent builds.


## GObject-Introspection

Use version 1.80.1 as that one is compatible with the version of GLib we've
chosen.

Taking out cairo seems to solve a lot of issues while it should not really 
influence the working of the package. It is really loading the cairo module,
even when running with cairo disabled, that breaks the build of GObject-Introspection.
Maybe one of the libraries in cairo is not built properly?

With cairo, GObject-Introspection does find the right GLib module so 
doesn't try to rebuild GLib it appears. However, for that it needs a 
temporary installation of some scripts and while running some scripts that it has
built itself, it looks like it is picking up the system libgio-2.0.so.0 rather
than the one from our GLib installation. That might explain why some symbols are
not found while they should be present in our GLib installation (and appear to be
so when checking).

The system GLib version is 2.72.2, so if that is picked up for some reason at runtime,
this can explain the issues with symbols that are not found.


## HarfBuzz

Even with just the cairo module loaded but cairo otherwise disabled in the build,
there is an issue with a strange error message:

```
../harfbuzz-11.2.1/src/meson.build:1002:29: ERROR: Dependency lookup for gobject-introspection-1.0 with method 'pkgconfig' failed: Could not generate cflags for gobject-introspection-1.0:
Package 'gobject-introspection-1.0' requires 'glib-2.0 >= 2.80.0' but version of glib-2.0 is 2.72.2
```

so somehow as soon as cairo is brought in, the wrong version of glib is detected.


## Pango

Why is Pango imune for the issues with cairo?

To check: Is in the Meson build introspection turned off by default?
