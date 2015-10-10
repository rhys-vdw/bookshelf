#!/bin/bash -e

uglifyjs node_modules/knex/build/knex.js > scripts/jsdoc-static/assets/knex.min.js \
  && rm -rf ./docs/html/* && $(npm bin)/jsdoc --configure ./scripts/jsdoc.config.json \
  && rm -rf scripts/jsdoc-static/assets/knex.min.js
