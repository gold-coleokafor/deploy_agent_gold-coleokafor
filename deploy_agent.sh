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
read -p "Enter your project name: " name
     if [ -z "$name" ]; then 
             echo "Empty!!. Please input the project name"
             return 1
     elif ! [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]]; then
             echo "Invalid input: Only A-Z, a-z, 0-9, _, and - allowed"
             return 1
     fi
project_folder="attendance_tracker_$name"
     if [ -d "$project_folder" ]; then
         read -p "Folder exists. Overwrite (o) or abort (a)?: " answer
            case "$answer" in
     o|O)
         rm -rf "$project_folder"
        ;;
     a|A)
         echo "Aborted!"
       return 1
        ;;
     *)
        echo "Invalid input!!"
        return 1
        ;;
            esac
     else
             echo "$project_folder doesn't exist. It will be created"
     fi

     if mkdir -p "$project_folder/Helpers" "$project_folder/reports"; then
             echo "Both folders created"
     else
             echo "Error!, folders not created."
         return 1
     fi
             echo "Your project folder is $project_folder"
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
