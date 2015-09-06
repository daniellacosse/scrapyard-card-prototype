#!/bin/bash

bundle install

# (1)
printf "Printing Components..."
cd component/
ruby deck.rb
ruby analyzer.rb

# (2)
printf "Printing Component Blueprints..."
cd ../blueprint/
ruby deck.rb

# (3.1)
printf "Inferring Scrap card counts..."
cd ../scrap/
ruby get_cache.rb # get scrap cache for blueprint analysis

cd ../blueprint/
ruby analyzer.rb # spits out inferred scrap card counts

#(3.2)
printf "Printing Scraps..."
cd ../scrap/
ruby deck.rb
ruby analyzer.rb

# (4)
printf "Compiling PDF..."
cd ..
ruby assemble_pdf.rb

printf "DONE. Print out your new PDF fo' real and slice'er'up!"
