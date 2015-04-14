#!/bin/zsh

# Get parameters
SOURCE_LANGUAGE="$1"
DESTINATION_LANGUAGE="$2"
SOURCE_LANGUAGE_DISPLAYED_NAME="$3"

# Transform the text to something Google Translate understands
set +o histexpand
TEXT_TO_TRANSLATE=${4// /+}

# Make the clipboard able to handle international characters
export __CF_USER_TEXT_ENCODING=0x1F5:0x8000100:0x8000100

if $(echo "$TEXT_TO_TRANSLATE" | grep '+' > /dev/null 2>&1); then # if inputs more then one word
  # Call Google and get the answer directly
  TEXT=$(curl -A 'Alfred/0.1.0' "https://translate.google.com.tw/translate_a/single?client=t&sl=$SOURCE_LANGUAGE&tl=$DESTINATION_LANGUAGE&dt=bd&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&dt=at&ie=UTF-8&oe=UTF-8&clearbtn=1&prev=btn&srcrom=0&ssel=0&q=$TEXT_TO_TRANSLATE" | awk -F'"' '{print $2}')

  echo '<?xml version="1.0"?><items>
  <item uid="translation" arg="'"$TEXT"'">
    <title>'"$TEXT"'</title>
    <icon>icon.png</icon>
    <subtitle>'"$SOURCE_LANGUAGE_DISPLAYED_NAME"'</subtitle>
  </item>
</items>'

else # or if inputs only one word
  # Call Google and ask for the answer or any suggestions
  TEXT=$(curl -A 'Alfred/0.1.0' "https://translate.google.com.tw/translate_a/single?client=t&sl=$SOURCE_LANGUAGE&tl=$DESTINATION_LANGUAGE&dt=bd&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&dt=at&ie=UTF-8&oe=UTF-8&clearbtn=1&prev=btn&srcrom=0&ssel=0&q=$TEXT_TO_TRANSLATE")

  # Read the translated results
  RES=($(echo "$TEXT" | grep -o '[^\[]*\[[^\[]*,,[0-9]' | awk -F'"' '{print $2}'))

  # Read the synonyms
  SYNO=($(echo "$TEXT" | grep -o '[^\[]*\[[^\[]*,,[0-9]' | grep -o '\[.*\]' | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g'))

  # Read the suggestions
  DO_YOU_MEAN=$(echo "$TEXT" | grep -o '<i>[^<]*</i>' | sed 's/<i>//g' | sed 's/<\/i>//g')

  # Write output XML header
  OUTP='<?xml version="1.0"?><items>'

  # Check if we got any suggestions
  if [[ -n "$DO_YOU_MEAN" ]]; then
    OUTP+='
  <item uid="translation-dym" autocomplete="'"$DO_YOU_MEAN"'">
    <title>'"$DO_YOU_MEAN"'</title>
    <icon>icon.png</icon>
    <subtitle>Did you mean this?</subtitle>
  </item>'
  fi

  # Print the translations
  if [[ -n "$RES[1]" && ! ${#RES[@]} -eq '1' ]]; then
    for (( i = 1 ; i < ${#RES[@]} + 1 ; i++ )) do
      OUTP+='
  <item uid="translation'$i'" arg="'"$RES[$i]"'">
    <title>'"$RES[$i]"'</title>
    <icon>icon.png</icon>
    <subtitle>'"$SOURCE_LANGUAGE_DISPLAYED_NAME"' ('$(echo "$SYNO[$i]" | sed 's/,/, /g' | sed 's/, ^//g')')</subtitle>
  </item>'
    done
    OUTP+='
</items>'
  else
    TEXT=$(echo "$TEXT" | awk -F'"' '{print $2}')
    OUTP+='
  <item uid="translation" arg="'"$TEXT"'">
    <title>'"$TEXT"'</title>
    <icon>icon.png</icon>
    <subtitle>'"$SOURCE_LANGUAGE_DISPLAYED_NAME"'</subtitle>
  </item>
</items>'
  fi
  echo "$OUTP"
fi
