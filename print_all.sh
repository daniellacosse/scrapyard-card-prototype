#!/bin/bash

bundle install

# (1)
printf "Printing Modules..."
echo && cd scrapper_module/
ruby deck.rb
# ruby analyzer.rb

# (2)
printf "Printing Component Blueprints..."
echo && cd ../blueprint/
ruby deck.rb

# (3.1)
printf "Inferring Scrap card counts..."
echo && cd ../scrap/
ruby get_cache.rb # get scrap cache for blueprint analysis

cd ../blueprint/
ruby analyzer.rb # spits out inferred scrap card counts

#(3.2)
printf "Printing Scraps..."
echo && cd ../scrap/
ruby deck.rb
# ruby analyzer.rb

# (4)
printf "Printing Contestants..."
echo && cd ../contestant/
ruby deck.rb

# (5)
printf "Compiling PDF..."
echo && cd ..
ruby assemble_pdf.rb
