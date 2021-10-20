#! /bin/bash

read -p "Enter your search query: "  query
echo ""
echo ""

## Create a link from query
query="${query//" "/"%20"}"
query="https://html.duckduckgo.com/html?q="$query

## Scrape html from duckduckgo
html=$( curl -s "$query" ) # grep -oP "uddg=\K.*(?=&)" )

## Links
## Grab links, grep magic
links=$( echo "$html" | grep -oP "uddg=\K.*(?=&)" | uniq | grep -v "&amp" )
## Format the links, so the urls make sense
links=${links//"%3A"/":"}
links=${links//"%2F"/"/"}

## Format the results to include only titles and descriptions of search results
results=$( echo "$html" | grep -e "result__snippet" -e "result__a" )
results="${results//"<b>"/""}"
results="${results//"</b>"/""}"
results="${results//"</a>"/""}"
results=$( echo "$results" | awk -F\>  '{print $2}'  )

## Set the separator to be only new line character, so the for loop iterates over lines, not words
IFS=$'\n'

index=1
for Line in $results
do
	## Limit the number of results to (15-1)/2 = 7
	if (($index == 15))
	then
		break
	fi
	
	## Check if the line is a title, if yes color it
	if (( $index % 2 == 1 ))
	then
		echo -n $'\e[0;32m'$Line$'\e[0m'
	else
		echo -n "$Line"
	fi
	
	## Check wheter or not to put URL after previous if statement's output
	if (( $index % 2 == 1 ))
	then
		echo -n " -  "
		head=$( echo "$links" | sed -n $(( (index + 1) / 2 ))\p )
		echo $'\e[0;34m'$head$'\e[0m'
	else
		echo ""
	fi

	echo ""
	index=$(( index + 1 ))
done

