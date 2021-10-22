#! /bin/bash

## Bring up fuzzyfinder with search engine options - you can replace it with dmenu or rofi if you want to or you can remove it and always use one search engine
engine=$(echo -e "DuckDuckGo\nWiby.me" | fzf --prompt "Search engine: ")

## Uncomment one of these lines if you always want to use just one search engine
#engine="DuckDuckGo"
#engine="Wiby.me"

read -p "Enter your search query: "  query
echo ""
echo ""

## Create a link from query
if [[ $engine == "DuckDuckGo" ]]
then
	query="${query//" "/"%20"}"
	query="https://html.duckduckgo.com/html?q="$query
elif [[ $engine == "Wiby.me" ]]
then
	query="${query//" "/"+"}"
	query="https://wiby.me/?q="$query
fi

## Scrape html from search engine
html=$( curl -s "$query" ) 

## Links
## Grab links, grep magic

if [[ $engine == "DuckDuckGo" ]]
then
	links=$( echo "$html" | grep -oP "uddg=\K.*(?=&)" | uniq | grep -v "&amp" )
	## Format the links, so the urls make sense
	links=${links//"%3A"/":"}
	links=${links//"%2F"/"/"}
elif [[ $engine == "Wiby.me" ]]
then
	links=$( echo "$html" | grep 'tlink' | awk -F\" '{ print $4 }' )
	descs=$( echo "$html" | grep 'tlink' | awk -F"<p>" '{ print $2 }' | awk -F"</p>" '{ print $1 }' )
fi

## Format the results to include only titles and descriptions of search results
if [[ $engine == "DuckDuckGo" ]]
then
	results=$( echo "$html" | grep -e "result__snippet" -e "result__a" )
	results="${results//"<b>"/""}"
	results="${results//"</b>"/""}"
	results="${results//"</a>"/""}"
	results=$( echo "$results" | awk -F\>  '{print $2}'  )
elif [[ $engine == "Wiby.me" ]]
then
	titles=$( echo "$html" | grep 'tlink' | awk -F\> '{ print $2 }' | awk -F\< '{ print $1 }' )
	descs=$( echo "$html" | grep 'tlink' | awk -F"<p>" '{ print $2 }' | awk -F"</p>" '{ print $1 }' )
	descs="${descs//"<br>"/""}"
fi

## Set the separator to be only new line character, so the for loop iterates over lines, not words
IFS=$'\n'


## This if statement seems to be a horrible way to implement multiple search engines. I will do nothing about this.
if [[ $engine == "DuckDuckGo" ]]
then
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
			echo -n " - "
			head=$( echo "$links" | sed -n $(( (index + 1) / 2 ))\p )
			echo $'\e[0;34m'$head$'\e[0m'
		else
			echo ""
		fi

		echo ""
		index=$(( index + 1 ))
	done
elif [[ $engine == "Wiby.me" ]]
then
	index=1
	for title in $titles
	do
		echo -n $'\e[0;32m'"$title"$'\e[0m'"   -  " 
		link=$( echo "$links" | sed -n $index\p )
		echo $'\e[0;34m'"$link"$'\e[0m' 
		echo "$descs" | sed -n $index\p
		echo ""
		

		index=$(( index + 1 ))
	done	
fi

######## THE WEBSITE VIEWING PART ######## 
echo ""
echo ""
read -p "Choose the website you want to visit: " website
url=$( echo "$links" | sed -n $website\p  )

page=$( curl "$url" )

## Here I gave up trying to do stuf with awk or sed and opted for pup instead
echo "$url"

if [[ "$url" == *"wikipedia"* ]]
then
	page=$(echo $( echo "$page" | pup 'h1#firstHeading text{}' ) "\n"  $( echo "$page" | pup 'p text{}' ))
else
	page=$( echo "$page" | pup 'body text{}' )
fi


## Configure hrefs
hrefs=""
for link in $( echo $page | pup 'a attr{href}' )
do
	if [ ${link:0:1} = "." ]
	then
		hrefs=$( echo "$hrefs""\n""${link/"./"/"$url"}" )
	elif [ ${link:0:1} = "/" ]
	then
		hrefs=$( echo "$hrefs""\n""${link/\//"$url"}" )

	else
		hrefs=$( echo "$hrefs""\n""$link" )
	fi

done


echo -e "$page" | less -s -+S






