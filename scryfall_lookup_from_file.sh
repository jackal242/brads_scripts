#!/bin/bash
while read -r line
do
    # Extract card name from the Moxfield line
    name=$(echo "$line" | sed -E 's/^[0-9]+ (.*) \([A-Za-z0-9]+\).*/\1/')

    # If it contains a slash (double-faced card), keep only the front face name
    search_name=$(echo "$name" | sed 's/ \/.*//')

    echo "Name: $name"

    # Let curl handle the quote wrapping and URL encoding safely using $search_name
    curl -s -G -H "User-Agent: MyMagicApp/1.0" \
	--data-urlencode "q=!\"$search_name\"" \
        "https://api.scryfall.com/cards/search" | \
    jq -r '
    if .object == "error" then
        "Scryfall Error: \(.details)"
    else
        .data[0] | 
        if .card_faces then
            "\n-----------\n" + 
            ([.card_faces[] | 
                "Name: \((if .flavor_name then "\(.flavor_name) (\(.name))" else .name end))\n" +
                "Mana Cost: \((if .mana_cost then .mana_cost else "None" end))\n" +
                "Type: \(.type_line)\n" +
                "Text: \(.oracle_text)\n" +
                "P/T: \((if .power then "\(.power)/\(.toughness)" else "N/A" end))"
             ] | join("\n//\n")) + 
            "\n-----------\n"
        else
            "\n-----------\nName: \((if .flavor_name then "\(.flavor_name) (\(.name))" else .name end))\nMana Cost: \((if .mana_cost then .mana_cost else "None" end))\nType: \(.type_line)\nText: \(.oracle_text)\nP/T: \((if .power then "\(.power)/\(.toughness)" else "N/A" end))\n-----------\n"
        end
    end'

    sleep 1
done < "$1"
