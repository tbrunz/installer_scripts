#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Scrape a website
# ----------------------------------------------------------------------------
#

if (( $# != 1 && $# != 2 )); then

    echo "scrape: Need a URL or URL and path..."
    exit 1
fi

#
# Remove trailing '/' from the domain name,
# and remove leading '/' from the website (folder) name;
#
DOMAIN=${1#http*://}
DOMAIN=${DOMAIN%/}

(( $# == 2 )) && WEBSITE=/${2#/}

#echo "Scraping '${DOMAIN}' + '${WEBSITE}' "
#exit

#
# Scrape away...
#
wget \
     --recursive \
     --no-clobber \
     --page-requisites \
     --html-extension \
     --convert-links \
     --restrict-file-names=windows \
     --domains ${DOMAIN} \
     --no-parent \
         ${DOMAIN}${WEBSITE}


#
: <<'__COMMENT'

This command downloads the Web site 'www.website.org/tutorials/html/':

$ wget \
     --recursive \
     --no-clobber \
     --page-requisites \
     --html-extension \
     --convert-links \
     --restrict-file-names=windows \
     --domains website.org \
     --no-parent \
         www.website.org/tutorials/html/

The options are:

    --recursive : download the entire Web site.

    --domains website.org : don't follow links outside 'website.org'.

    --no-parent : don't follow links outside the directory 'tutorials/html/'.

    --page-requisites : get all the page elements (images, CSS and so on).

    --html-extension : save files with the '.html' extension.

    --convert-links : convert links so that they work locally, off-line.

    --restrict-file-names=windows : modify filenames so they work in Windows.

    --no-clobber : don't overwrite existing files
                   (used in case the download is interrupted and resumed).

__COMMENT
