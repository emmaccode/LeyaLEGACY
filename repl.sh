true
while true ; do
  while IFS="" read -r -e -d $'\n' options; do
    if [ "$options" = "quit" ]; then
     exit 0
    else
     echo "__________________"
     echo "|Welcome to Leya!|"
     echo "|~~~~~~~~~~~~~~~~|"
     echo "|    V 0.0.2     |"
     echo "| Copyright 2020 |"
     echo "| Emmett         |"
     echo "|    Boudreau    |"
     echo "------------------"
     while read -p "$USER in Leya 🦩 } " line;do ~/.Leya/core/interp <<< $line;echo; done
    fi
  done
done
