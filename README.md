Starling-FFParticleSystem
=========================

Improved particle system for the [Starling framework](https://github.com/PrimaryFeather/Starling-Framework)

Short overview and live demo: http://www.flintfabrik.de/blog/improved-particle-system-for-starling

Getting started: [Starling wiki page](http://wiki.starling-framework.org/extensions/ffparticlesystem)

## Overview
This is particle system is based on and compatible to the [original](https://github.com/PrimaryFeather/Starling-Extension-Particle-System) but provides some additional features and various performance improvements. Thanks a lot to [Colin Northway](http://colinnorthway.com/) ([Incredipede](http://www.incredipede.com/)) sponsoring this extension created for his upcoming game.

**Important:** I did anything to make the code as fast as possible but to get the best performance I strongly recommend using the [ASC 2.0 compiler](http://www.bytearray.org/?p=4789) and setting it up for [inline] functions.

####New Features:
  * particle pool
  * batching (less draw calls)
  * multi buffering (avoid stalling)
  * animated particles
  * random start frames
  * filter support
  * optional custom sorting, code and variables
  * calculating bounds (optional)
  * spawnTime, fadeIn/fadeOut
  * emit angle alligned particle rotation
  * various performance improvements

Additional information about the new features and the [live demo (~ 5 MB)](http://www.flintfabrik.de/pgs/starling/FFParticleSystem/) can be found on [my page.](http://www.flintfabrik.de/blog/improved-particle-system-for-starling)
