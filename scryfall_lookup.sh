#!/bin/bash

#curl -s -H "User-Agent: MyMagicApp/1.0"  "https://api.scryfall.com/cards/named?exact=$1"  | jq -r 'paths(scalars) as $p | "\($p | join(".")): \(getpath($p))"'
#curl -s -H "User-Agent: MyMagicApp/1.0"  "https://api.scryfall.com/cards/search?q=$1"  | jq -r 'paths(scalars) as $p | "\($p | join(".")): \(getpath($p))"'


#curl -s -H "User-Agent: MyMagicApp/1.0" "https://api.scryfall.com/cards/search?q=$1" | \
#jq -r '.data[] | "\n-----------\nName: \(.name)\nMana Cost: \(.mana_cost)\nType: \(.type_line)\nText: \(.oracle_text)\nP/T: \((if .power then "\(.power)/\(.toughness)" else "N/A" end))\n-----------\n"'



curl -s -H "User-Agent: MyMagicApp/1.0" "https://api.scryfall.com/cards/search?q=name%3A%2F%5E$1%2F" | \
jq -r '.data[] | "\n-----------\nName: \(.name)\nMana Cost: \(.mana_cost)\nType: \(.type_line)\nText: \(.oracle_text)\nP/T: \((if .power then "\(.power)/\(.toughness)" else "N/A" end))\n-----------\n"'
