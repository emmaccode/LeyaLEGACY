true
while true ; do
  while IFS="" read -r -e -d $'\n' options; do
    if [ "$options" = "quit" ]; then
     exit 0
    else
      echo "                               /"
      echo "                      ////////"
      echo "                    ///////////"
      echo "                   ////      //"
      echo "                   //       %//"
      echo "                           ////"
      echo "                        /////"
      echo "                    (/////"
      echo "                 //////"
      echo "                ////        (/////////"
      echo "               ////      ///////////////////#"
      echo "               ////    &///////////////////////"
      echo "                /////////////////////////////////"
      echo "                 //////////////////////////////////"
      echo "                     ///////////////////////////////"
      echo "                          #////////////////// ///////&"
      echo "                               ////////////         %&"
      echo "                                 /// ///("
      echo "                                 ///   &///&"
      echo "                                 (/(      ////"
      echo "                                  /(      #////"
      echo "                                  /(#/////"
      echo "                               /////"
      echo "                            (//  //"
      echo "                           //    //"
      echo "                           /(   //"
      echo "                                //"
      echo "                                /"
      echo "                                &"
      echo "                               /"
      echo "                               /"
      echo "                               #/"
      echo "		 __    ____"
      echo "		(  )  ( ___)=========================|"
      echo "		 )(__  )__)      Version 0.0.3       |"
      echo "		(____)(____)  Copyright (C) 2020     |"
      echo "		 _  _   __|==========================|"
      echo "		( \/ ) /__\  Leya Compiler Version   |"
      echo "		 \  / /(__)\        0.0.6            |"
      echo "		 (__)(__)(__)========================|"
     while read -p "$USER in Leya 🦩 } " line;do ~/.Leya/core/Leya <<< $line;echo; done
    fi
  done
done
