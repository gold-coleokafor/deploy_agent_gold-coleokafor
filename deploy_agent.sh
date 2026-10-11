#!/bin/bash 

preflight_check () { 
local found_a_missing_program=false
	for program in python3 zip; do 
	     if command -v "$program" >/dev/null 2>&1; then
	        echo "$program found"
	     else
	        echo "$program missing"
             found_a_missing_program=true 
             fi
        done
       if [ "$found_a_missing_program" = true ]; then
       exit 1 
       fi 
       check_py_version=$(python3 --version)
                echo "$check_py_version"
}

deploy_feature () {
preflight_check
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

