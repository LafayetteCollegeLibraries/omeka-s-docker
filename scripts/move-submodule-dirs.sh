#!/bin/bash

local repo_root="/var/www/repo"
local omeka_src="$repo_root/$OMEKA_CORE_DIR"
local omeka_dest="/var/www/html"
local module_src="$repo_root/$OMEKA_MODULE_DIR"
local module_dest="$omeka_dest/modules"
local theme_src="$repo_root/$OMEKA_THEME_DIR"
local theme_dest="$omeka_dest/themes"

# clear out existing /var/www/html contents
rm -rf $omeka_dest

# move omeka-s core
mv $omeka_src $omeka_dest

# move modules
if [ -d $module_src ]; then
  rm -rf $module_dest
  mv $module_src $module_dest
fi

# move themes (if they exist)
if [ -d $theme_src ]; then
  rm -rf $theme_dest
  mv $theme_src $theme_dest
fi
