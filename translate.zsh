#!/bin/zsh

SOURCE_LANGUAGE="$1"
DESTINATION_LANGUAGE="$2"
SOURCE_LANGUAGE_DISPLAYED_NAME="$3"

# Transform the text to something Google translate understands
set +o histexpand
TEXT_TO_TRANSLATE=$(echo "$4" | sed 's/ /+/g')

# Make the clipboard able to handle international characters
export __CF_USER_TEXT_ENCODING=0x1F5:0x8000100:0x8000100

if $(echo "$TEXT_TO_TRANSLATE" | grep '+' > /dev/null 2>&1); then # if inputs more then one word
  # Call Google and ask for the answer
  TEXT=$(curl -s -A "Mozilla/5.0" "http://translate.google.com/translate_a/t?client=t&text=$TEXT_TO_TRANSLATE&hl=pt-BR&sl=$SOURCE_LANGUAGE&tl=$DESTINATION_LANGUAGE&multires=1&ssel=0&tsel=0&sc=1" | awk -F'"' '{print $2}')

  echo '<?xml version="1.0"?><items>
  <item uid="translation" arg="'$TEXT'">
    <title>'$TEXT'</title>
    <icon>icon.png</icon>
    <subtitle>'$SOURCE_LANGUAGE_DISPLAYED_NAME'</subtitle>
  </item>
</items>'

else # or if inputs only one word
  # Call Google and ask for the answer
  TEXT=$(curl -s -A "Mozilla/5.0" "http://translate.google.com/translate_a/t?client=t&text=$TEXT_TO_TRANSLATE&hl=pt-BR&sl=$SOURCE_LANGUAGE&tl=$DESTINATION_LANGUAGE&multires=1&ssel=0&tsel=0&sc=1")

  # Read the results
  RES=($(echo "$TEXT" | grep -o '[^\[]*\[[^\[]*,,[0-9]' | awk -F'"' '{print $2}'))

  # Read the results2
  RESS=($(echo "$TEXT" | grep -o '[^\[]*\[[^\[]*,,[0-9]' | grep -o '\[.*\]' | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g'))

  # Read the suggestions
  DO_YOU_MEAN=$(echo "$TEXT" | grep -o '<i>[^<]*</i>' | sed 's/<i>//g' | sed 's/<\/i>//g')

  # Write output XML header
  OUTP='<?xml version="1.0"?><items>'

  # Check if we got any suggestions
  if [[ -n "$DO_YOU_MEAN" ]]; then
    OUTP+='
  <item uid="translation-dym" autocomplete="'$DO_YOU_MEAN'">
    <title>'$DO_YOU_MEAN'</title>
    <icon>icon.png</icon>
    <subtitle>Did you mean this?</subtitle>
  </item>'
  fi

  # Print the translations
  if [[ -n "$RES[1]" && ! ${#RES[@]} -eq '1' ]]; then
    for (( i = 1 ; i < ${#RES[@]} + 1 ; i++ )) do
      OUTP+='
  <item uid="translation'$i'" arg="'$RES[$i]'">
    <title>'$RES[$i]'</title>
    <icon>icon.png</icon>
    <subtitle>'$SOURCE_LANGUAGE_DISPLAYED_NAME' ('$(echo $RESS[$i] | sed 's/,/, /g' | sed 's/, ^//g')')</subtitle>
  </item>'
    done
    OUTP+='
</items>'
  else
    TEXT=$(echo $TEXT | awk -F'"' '{print $2}')
    OUTP+='
  <item uid="translation" arg="'$TEXT'">
    <title>'$TEXT'</title>
    <icon>icon.png</icon>
    <subtitle>'$SOURCE_LANGUAGE_DISPLAYED_NAME'</subtitle>
  </item>
</items>'
  fi
  echo "$OUTP"
fi
