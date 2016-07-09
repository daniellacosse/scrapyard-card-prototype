#!/bin/bash

bundle install

# (1)
printf "Printing Modules..."
echo && cd scrapper_module/
ruby deck.rb
ruby analyzer.rb

# (2.1)
printf "Importing Blueprints..."
echo && cd ../blueprint/
ruby import.rb # get scrap cache for blueprints

# (2.2)
printf "Importing Scraps..."
echo && cd ../scrap/
ruby import.rb # get scrap cache for scraps

# (3.1)
printf "Printing Blueprints..."
cd ../blueprint/
ruby deck.rb
ruby analyzer.rb # spits out inferred scrap card counts

# (3.2)
printf "Printing Scraps..."
echo && cd ../scrap/
ruby deck.rb
ruby analyzer.rb

# (4)
printf "Printing Contestants..."
echo && cd ../contestant/
ruby deck.rb

# (5)
printf "Compiling PDF..."
echo && cd ..
ruby assemble_pdf.rb
