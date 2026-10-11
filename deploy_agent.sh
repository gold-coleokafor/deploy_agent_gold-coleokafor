#!/bin/bash 

deploy_feature () {
     echo "Deploy selected"
}

run_feature () {
     echo "Run selected"
}

archive_feature () {
     echo "Archive selected"
}

show_menu () { 
       echo "1. Deploy"
       echo "2. Run"
       echo "3. Archive"
       echo "4. Exit"
}

while true; do
    show_menu 
    read -p "Choose an option: " option
    case "$option" in
        1)
            deploy_feature
            ;;
        2)
            run_feature
            ;;
        3)
            archive_feature
            ;;
        4)
            break 
            ;;
        *)
            echo "Invalid input!!"
            ;;
    esac 
done

echo "Exiting menu, goodbye"

