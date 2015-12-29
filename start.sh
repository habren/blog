#!/bin/bash

hexo clean
livereload -e ".md, .html, .png, .svg, .jpg, .gif, .css, .js, .json" | (hexo clean && hexo s -g)
