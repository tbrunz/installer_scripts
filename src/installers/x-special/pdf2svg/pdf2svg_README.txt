
*** This is now in the Ubuntu repositories since Trusty 14.04 ***

pdf2svg  v0.2.2
http://www.cityinthesky.co.uk/opensource/pdf2svg/

Under Linux there aren't many freely available vector graphics editors and as 
far as I know there are none that can edit EPS (encapsulated postscript) and PDF 
(portable document format) files. I produce lots of these files in my day-to-day 
work and I would like to be able to edit them. The best vector graphics editor 
I have found so far is Inkscape but it only reads SVG files... (Edit: recent 
versions can import PDFs but I'm not entirely happy with how text is imported; 
in particular, that fonts are not imported from the PDF.)

To overcome this problem I have written a very small utility to convert PDF 
files to SVG files using Poppler and Cairo. Version 0.2.2 is available here 
(with modifications by Matthew Flaschen and Ed Grace). This appears to work on 
any PDF document that Poppler can read (try them in XPDF or Evince since they 
both use Poppler).

So now it is possible to easily edit PDF documents with your favorite SVG 
editor! One other alternative would be to use 'pstoedit' but the commercial SVG 
module costs (unsurprisingly!) and the free SVG module is not very good at 
handling text... 

To install:

    Suggestion: Do this in a virtual machine, as it installs a large number of 
    support packages.

    Download pdf2svg-0.2.2.tar.gz.
    Unpack the files and make the executable.

    # tar -zxf pdf2svg-0.2.2.tar.gz
    # cd pdf2svg-0.2.2
    # apt-get install libcairo2-dev
    # apt-get install libpoppler-glib-dev
    # apt-get install gtk+-2.0
    # ./configure --prefix=/usr/local
    # make
    # make install

To use:

    $ pdf2svg <input.pdf> <output.svg> [<pdf page no. or "all" >]

Note: if you specify all the pages you must give a filename with %d in it (which 
will automatically be replaced by the appropriate page number). E.g.

    $ pdf2svg input.pdf output_page%d.svg all


