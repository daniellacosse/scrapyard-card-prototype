#!/bin/bash

bundle install

printf "Printing Components..."
cd component/
ruby deck.rb
ruby analyzer.rb

printf "Printing Scraps..."
cd ../scrap/
ruby deck.rb
ruby analyzer.rb
cp -f -v cache.csv ../blueprint/scrap_cache.csv

printf "Printing Component Blueprints..."
cd ../blueprint/
ruby deck.rb
ruby analyzer.rb
cp -f -v results.csv ../scrap/blueprint_edited_results.csv

cd ../scrap
vi blueprint_edited_results.csv
ruby deck.rb

cd ../mastersheets
ruby assemble_pdf.rb

printf "DONE. You can print out mastersheets/decks.pdf now!"
