# gMatlabToolbox
Scripts I've generated through the years to facilitate all things in Matlab

~~Most if not all scripts written post Oct 2014 are currently omitted, as they may require permission from my current employter in order to share publicly.~~ 

Post-Oct 2014 scripts have now been added, with permission from my previous employer, and with sensitive information redacted as needed. This toolbox now contains useful tools for processing very large images, and from a variety of sources and formats. For instance

* `CDDImgHandling`: scripts for processing images from a high-performance CCD camera (e.g. a Hamamatsu Orca; as opposed to raster scanned 2-photon images)
* `HDF5FileHandling`: scripts for processing images in HDF5 format, and converting to HDF5 from various other common microscope software formats
* `RawImgFileHandling`: scripts for processing images of no format (i.e. just a raw stream of bytes)

Some routines leveraged interoperability between Matlab and ImageJ using [MIJI](https://imagej.net/Miji); others leveraged interoperability between Linux commandline tools and Windows via calling Cygwin from Matlab.

Most if not all scripts written post Oct 2014 are currently omitted, as they may require permission from my current employer in order to share publicly.