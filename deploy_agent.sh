#!/bin/bash 

script_folder=$(dirname "$0")
names=("Chinedu Okafor" "Amara Adebayo" "Tunde Balogun" "Chioma Nwosu" "Olumide Popoola" "Zainab Abubakar" "Emeka Igwe" "Funmi Bello" "Tariq Musa" "Nneka Okeke")
emails=("chinedu.okafor@email.com" "amara.adebayo92@email.com" "tunde.balogun.dev@email.com" "chioma.nwosu@email.com" "olumide.popoola@email.com" "zainab.abubakar@email.com" "emeka.igwe.tech@email.com" "funmi.bello88@email.com" "tariq.musa@email.com" "nneka.okeke@email.com" )
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
     if cp "$script_folder/templates/attendance_checker.py" "$project_folder/"; then
             echo "Successfully copied attendance_checker.py"
     else
             echo "Error! Failed to copy attendance_checker.py"
             return 1
     fi
     if cp "$script_folder/templates/config.json" "$project_folder/Helpers/"; then
             echo "Successfully copied config.json"
     else
             echo "Error! Failed to copy config.json"
             return 1
     fi 
     while true; do
        read -p "Copy from the template (a) or Generate a fresh roster (b): " choice 
            case "$choice" in
            a|A)
              read -p "How many students to copy: " number
              if ! [[ "$number" =~ ^[0-9]+$ ]]; then
                 echo "Please enter a whole number"
                 return 1
              fi
               if [ "$number" -ge 1 ] && [ "$number" -le 10 ]; then
                 echo "Within specified range of 1-10"
              else
                 echo "Out of range! Please select a number between 1-10"
                 return 1
              fi
              if head -n $(( number + 1 )) "$script_folder/templates/assets.csv" > "$project_folder/Helpers/assets.csv"; then
                 echo "$number successfully copied"
              else
                 echo "Error! Failed to copy"
                 return 1
              fi
              break
              ;;
            b|B)
              read -p "How many students to generate: " generate
              if ! [[ "$generate" =~ ^[0-9]+$ ]]; then
                 echo "Please enter a whole number"
                 return 1
              fi
              if [ "$generate" -ge 1 ] && [ "$generate" -le 10 ]; then
                 echo "Within specified range of 1-10"
              else
                 echo "Out of range! Please select a number between 1-10"
                 return 1
              fi
                 echo "Email,Names,Attendance Count,Absence Count" > "$project_folder/Helpers/assets.csv"
              for (( i=0; i<generate; i++ )); do
                 echo "${emails[$i]},${names[$i]},0,0" >> "$project_folder/Helpers/assets.csv"
              done
                 echo "Generated successfully"
              if sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$project_folder/Helpers/config.json"; then
                 echo "Successfully reset total_sessions to 1"
              else
                 echo "Failed to update total_sessions in config.json"
                 return 1
              fi
              break
              ;;
              *)
              echo "Invalid input!!"
              ;;
            esac
     done
              if chmod +x "$project_folder/attendance_checker.py"; then
                 echo "Set execute permission for attendance_checker.py"
               else
                 echo "Failed to set permission"
                 return 1
              fi
              if chmod 600 "$project_folder/Helpers/config.json"; then
                 echo "Set owner-only read/write (600) for config.json"
              else
                 echo "Failed to set permission"
                 return 1
              fi
           read -p "Update attendance alert thresholds?(y/n): " alert
              case "$alert" in
            y|Y)
               read -p "Input warning threshold (default 75): " warning
               read -p "Input failure threshold (default 50): " failure
               warning=${warning:-75}
               failure=${failure:-50}
              if ! [[ "$warning" =~ ^[0-9]+$ ]]; then
                 echo "Please enter a whole number"
                 return 1
              fi
              if ! [[ "$failure" =~ ^[0-9]+$ ]]; then
                 echo "Please enter a whole number"
                 return 1
              fi
              if [ "$warning" -ge 1 ] && [ "$warning" -le 100 ]; then
                 echo "Within specified range of 1-100"
              else
                 echo "Out of range! Please select a number between 1-100"
                 return 1
              fi
              if [ "$failure" -ge 1 ] && [ "$failure" -le 100 ]; then
                 echo "Within specified range of 1-100"
              else
                 echo "Out of range! Please select a number between 1-100"
                 return 1
              fi
              if [ "$warning" -le "$failure" ]; then
                 echo "Error! Warning threshold must be greater than the failure threshold"
                 return 1
              fi
              if sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" "$project_folder/Helpers/config.json"; then
                 echo "Successfully updated config.json (warning)"
              else
                 echo "Failed to update config.json (warning)"
                 return 1
              fi
              if sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" "$project_folder/Helpers/config.json"; then
                 echo "Successfully updated config.json (failure)"
              else 
                 echo "Failed to update config.json (failure)"
                 return 1
              fi
               ;;
            n|N)
               echo "Alert thresholds will not be changed"
               ;;
              *)
               echo "Default alert threshold"
               ;;
            esac
               echo "Your project folder is $project_folder"
               echo "Deploy completed. Running now to verify.."
               run_feature "$project_folder"
}

run_feature () {
           if [ -z "$1" ]; then
               read -p "Enter your project name: " name
               project_folder="attendance_tracker_$name"
           else
               project_folder="$1"
           fi
               echo "Project folder is $project_folder"
           if [ -d "$project_folder" ]; then
               echo "Folder exists"
           else
               echo "Folder does not exist!"
               return 1
           fi
           if ( cd "$project_folder" && python3 attendance_checker.py ); then
               echo "Application ran successfully"
           else
               echo "Unable to run application"
               return 1
           fi
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
