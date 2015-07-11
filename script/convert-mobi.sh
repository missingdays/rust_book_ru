#!/bin/sh

ROOT=$(pwd)
BOOK_DIR=${ROOT}/_book
CONVERTED_DIR=${BOOK_DIR}/converted

mkdir -p $CONVERTED_DIR
cd $BOOK_DIR

ebook-convert \
    README.html \
    "${CONVERTED_DIR}/rustbook.epub" \
    --cover="../cover.jpg" \
    --title="Язык программирования Rust" \
    --comments="" \
    --language="ru" \
    --book-producer="" \
    --publisher="" \
    --chapter="//h:h1[@class='title']" \
    --chapter-mark="pagebreak" \
    --page-breaks-before="/" \
    --level1-toc="//h:h1[@class='title']" \
    --no-chapters-in-toc \
    --max-levels="1" \
    --breadth-first \
    --dont-split-on-page-breaks

cd $ROOT