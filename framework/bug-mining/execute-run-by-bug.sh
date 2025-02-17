#!/bin/bash
WORK_DIR="bug-mining"
echo "WORK_DIR: $WORK_DIR"
cat 1.txt | while read line
do
    # read project information
    read -ra strarr <<<"$line"
    project_id=${strarr[0]} 
    project_name=${strarr[1]}
    repository_url=${strarr[2]}
    issue_tracker_name=${strarr[3]}
    issue_tracker_project_id=${strarr[4]}
    bug_fix_regex=${strarr[5]}
    sub_project=${strarr[6]:-"."}
    echo "Getting the project information ..."
    echo "PROJECT_ID: $project_id"
    echo "PROJECT_NAME: $project_name"
    echo "REPOSITORY_URL: $repository_url"
    echo "ISSUE_TRACKER_NAME: $issue_tracker_name"
    echo "ISSUE_TRACKER_PROJECT_ID: $issue_tracker_project_id"
    echo "BUG_FIX_REGEX: $bug_fix_regex"
    echo "SUB_PROJECT: $sub_project"
    # make bug-mining directory
    cd `dirname $0`
    path=$PWD
    echo "Create project directory: $path/$WORK_DIR/$project_id"
    mkdir -p $path/bug-mining/$project_id
    if [ $? != 0 ]
    then
    echo -e "Failed to create $project_id directory!\n\n"
    continue
    fi
    
    work_dir="$WORK_DIR/$project_id"
    echo "WORK_DIR: $work_dir"
   
   if [ ! -f "$WORK_DIR/$project_id/issues.txt" ]
   then
        rm -rf $work_dir
        perl ./initialize-project-and-collect-issues.pl -p $project_id \
                                                         -n $project_name \
                                                         -w $work_dir \
                                                         -r $repository_url \
                                                         -g $issue_tracker_name \
                                                         -t $issue_tracker_project_id \
                                                         -e $bug_fix_regex 
    #continue
    if [ $? != 0 ]
    then
      echo -e "Initialize project $project_id and collect issues failed!\n\n"
      echo "${project_id}, Initialization error!" >> error_info.txt
    #continue
    fi
   fi
   
    #rm -rf $work_dir
   nums=$(wc -l < $work_dir/framework/projects/$project_id/active-bugs.csv)
   nums=`expr $nums - 1`
   #3470
   #for((i=7000;i<=$nums;i++));    
   #for((i=1;i<=$nums;i++)); 
   #for((i=$nums;i>=1;i--));
   #for((i=$nums;i>=1;i--));  
   arr=( 12 15 16 35 40 44 46 47 49 55 66 67 69 76 78 94 102 103 106 109 112 117 121 129 132);
   #arr=(1019);
   for i in ${arr[@]}
do    
   # Initialize the project revisions
   perl ./initialize-revisions.pl -p $project_id -w $work_dir -s $sub_project -b $i -n $project_name
    if [ $? != 0 ]
    then
     echo -e "Initialize the project $project_id revisions failed!\n\n"
     echo "${project_id}, Initialize the revisions error!" >> error_info.txt
     continue
    fi
    echo -e "Initialize the project $project_id revisions successfully!\n\n"
   
   # Analyze all revisions of the project
   perl ./analyze-project.pl -p $project_id -w $work_dir \
                             -g $issue_tracker_name \
                             -t $issue_tracker_project_id \
               -s $sub_project -b $i
   if [ $? != 0 ]
   then
    echo -e "Analyze all revisions of the project $project_id failed!\n\n"
    echo "${project_id}, Analyze all revisions of the project error!" >> error_info.txt
    continue
   fi
   echo -e "Analyze all revisions of the project $project_id successfully!\n\n"
   
   # Determine triggering tests of the project
   perl ./get-trigger.pl -p $project_id -w $work_dir -s $sub_project -b $i
   if [ $? != 0 ]
   then
    echo -e "Determine triggering tests of project $project_id failed!\n\n"
    echo "${project_id}, Determine triggering tests of the project error!" >> error_info.txt
    continue
   fi
   perl ./get-metadata.pl -p $project_id -w $work_dir -b $i -s $sub_project
   
 
done   
   # trigger_dir="$work_dir/framework/projects/$project_id/trigger_tests";
   # if  [ "`ls -A $trigger_dir`" = "" ]
   # then
   #    rm -rf $work_dir
   # fi
done
