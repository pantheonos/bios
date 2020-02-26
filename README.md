# pantheon/bios

This BIOS written in MoonScript successfully removes all CraftOS parts from it, and provides an "entrypoint" enabling you to launch CraftOS from it.

## Installing

First, clone this repository, and then [craftos2-rom](https://github.com/MCJack123/craftos2-rom) into `reference/`.

```sh
$ git clone daelvn/pantheon-bios && cd pantheon-bios
$ git clone MCJack123/craftos2-rom reference/
```

Now, to run the project you will need [COSRun 0.2](https://github.com/daelvn/cosrun). Follow the installation steps and then run:

```sh
$ cosrun image unpack project.yml    # This is only needed once
$ cosrun run bios
```

## Developing

For developing, you will need [MoonScript](http://moonscript.org) to compile the files. To compile and run, do:

```sh
$ moonc . && cosrun run bios
```

## On CraftOS

You can change the way CraftOS works since all parts that depend on it, even APIs, are loaded from `/boot/craftos.lua` (`pantheon-bios/images/craftos.lua`). You can modify the paths referring to `/rom/` to somewhere else and have fun with it.

### Changes over stock CraftOS

There are new globals: `PA_BREAK` and `PA_PRINT` which are functions (which you should not use in CraftOS), and `PA_VERSION` which is the pantheon/bios version.

## Creating a new image

Lua files put in `/boot/` (`pantheon-bios/images/`) will automatically be detected and availiable as a choice. Soon enough, this repository will also contain the image for Pantheon. If you are trying to run an existing OS, you **certainly** do not need an image entry here, since it is probably able to run normally from CraftOS.