#!/bin/bash

bundle install

# (1) procedurally generate addtional stats
# => and write the final cards to CSVs for printing
printf "Setting up..."
echo && cd scripts
ruby pre_processing.rb

# (2)
printf "Printing Modules..."
echo && cd ../gut/
ruby deck.rb

# (3)
printf "Printing Blueprints..."
echo && cd ../blueprint/
ruby deck.rb

# (4)
printf "Printing Scraps..."
echo && cd ../scrap/
ruby deck.rb

# (5)
printf "Printing Contestants..."
echo && cd ../contestant/
ruby deck.rb

# (6)
printf "Compiling final PDF..."
echo && cd ..
ruby print.rb
