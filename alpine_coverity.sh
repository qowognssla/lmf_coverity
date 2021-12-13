#!/bin/bash

CODE_BASE_DIR=`pwd`
HERE=$(dirname $(realpath $0))
IDIR_NAME=idir_kernel
IDIR_DIR=$CODE_BASE_DIR/$IDIR_NAME
ALPINE_COVERITY_DIR=$HERE/alpine_coverity
COVERITY_PLUGIN_DIR=$HOME/.synopsys/desktop/controller/logs
CONFIGS_DIR=$ALPINE_COVERITY_DIR/configs/latest-release
COVERITY_ID_PASS="telechips07"

# if [ -d "/home/coverity" ]; then
#     CONFIGS_DIR=/home/coverity/cov-analysis-linux64/telechips-config/latest-release
# fi

echo CONFIGS_DIR : $CONFIGS_DIR

STREAM_ID=

if [ -d $COVERITY_PLUGIN_DIR ]; then
    PLUGIN_IDIR_PATH=`find $COVERITY_PLUGIN_DIR -type f -print | \
    xargs grep -i "cov-analysis-linux64/bin/cov-run-desktop --dir" 2>/dev/null | \
    grep "$CODE_BASE_DIR"  | head -1 | awk -F'--dir|--code-base-dir' '{print $2}'`

    PLUGIN_IDIR_PATH=${PLUGIN_IDIR_PATH/idir_full/idir}

    echo PLUGIN_IDIR_PATH : $PLUGIN_IDIR_PATH
else 
    echo "No COVERITY_PLUGIN_DIR"
fi

echo Base Code Directory : $CODE_BASE_DIR

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;33m'

if [ -f $CODE_BASE_DIR/coverity.conf ]; then
    STREAM_ID=`cat $CODE_BASE_DIR/coverity.conf | python3 -c "import sys, json; print(''.join(json.load(sys.stdin)['settings']['stream']))"`
    echo Stream Information : $STREAM_ID
fi

# get options:
while (( "$#" )); do
    case "$1" in
        -c|--config)
            mapfile array < <(find $ALPINE_COVERITY_DIR -maxdepth 1 -type f -name "*.conf" -exec basename {} \;)
            LIST_LENGTH=${#array[@]}
            if [ $LIST_LENGTH -ne 0 ]; then

                clear
                echo
                echo "##########################################"
                echo "########## SELECT CONFIG FILE ############"
                echo "##########################################"
                echo

                INDEX=0
                for i in "${array[@]}"; do echo $INDEX.$i; let "INDEX++"; done
                echo $INDEX.exit
                echo 
                echo -n "Select config file index : "
                read CONFIG_INDEX

                if [ $CONFIG_INDEX -eq $INDEX ]; then exit 1; fi

                echo -e "Selected config file is ${GREEN}"${array[$CONFIG_INDEX]}"${NC}"
                cp -r $ALPINE_COVERITY_DIR/${array[$CONFIG_INDEX]} $CODE_BASE_DIR/coverity.conf

                if [ -d $CODE_BASE_DIR/tc_coverity ]; then
                    echo "already has tc_coverity dir, re-set up"
                    rm -rf $CODE_BASE_DIR/tc_coverity
                fi
                
                echo setting up tc_coverity directory
                ln -s $HERE/alpine_coverity $CODE_BASE_DIR/alpine_coverity

            else   
                echo "${RED}Error: there are no conf file in tc_coverity directory${NC}"
            fi
            exit 1
            ;;
        -s|--setup)
            if [ -f $CODE_BASE_DIR/coverity.conf ]; then
                if [ -d $IDIR_DIR ]; then
                    rm -rf $IDIR_DIR
                fi
                BUILD_CMD="./build-all-script.sh 3"
                CLEAN_CMD="touch ./kernel/drivers/char/vpu/*"
                
                source build/envsetup.sh 
                eval $CLEAN_CMD
                
                cov-build --dir $IDIR_NAME  --emit-complementary-info --config $ALPINE_COVERITY_DIR/alpine_config/custom_coverity.xml $BUILD_CMD
                
                if [ -d $PLUGIN_IDIR_PATH ]; then
                    rm -rf $PLUGIN_IDIR_PATH
                fi
                echo "Linking in plugins dir $IDIR_DIR"
                echo "to $PLUGIN_IDIR_PATH"
                ln -s $IDIR_DIR $PLUGIN_IDIR_PATH
                exit 1
            else
                echo "Error: the coveirty.conf file isn't exist"
                exit 1
            fi
            ;;
        -l|--link)
            if [ -d $PLUGIN_IDIR_PATH ]; then
                rm -rf $PLUGIN_IDIR_PATH
            fi
            if [ ! -d $IDIR_DIR ]; then
                echo "Not exist builded Idir dir" 
                exit 1
            fi
            echo "Linking in plugins dir $IDIR_DIR"
            echo "to $PLUGIN_IDIR_PATH"
            ln -s $IDIR_DIR $PLUGIN_IDIR_PATH
            exit 1
            ;;
        -a|--analysis)
            if [ -d $IDIR_DIR ]; then
                COV_ANALYZE_OPTIONS="--dir $IDIR_NAME --disable-default \
                --strip-path $CODE_BASE_DIR \
                --coding-standard-config $CONFIGS_DIR/cert-c-telechips-210714.config \
                --coding-standard-config $CONFIGS_DIR/cert-c-recommendation-telechips-210714.config \
                --config $ALPINE_COVERITY_DIR/alpine_config/custom_coverity.xml \
                --parse-warnings-config $CONFIGS_DIR/parse_warnings_telechips_211119.conf \
                @@$CONFIGS_DIR/runtime_rules_telechips_211119.txt"
#               --coding-standard-config $CONFIGS_DIR/misrac2012-telechips-210728.config \
                cov-analyze $COV_ANALYZE_OPTIONS
            else
                echo "the captured directory not exist"
            fi
            exit 1
            ;;
        -e|--commit)
            if [ -d $IDIR_DIR ]; then
                if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                    cov-commit-defects --dir $IDIR_NAME --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --stream $2
                else
                    #echo "Error: Argument for $1 is missing" >&2
                    cov-commit-defects --dir $IDIR_NAME --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --stream $STREAM_ID
                fi
            else
                echo "the captured directory not exist"
            fi
            exit 1
            ;;
        -f|--filter)
            if  [ $3 == "-s" ] || [ $3 == "--stream" ]; then
                STREAM_ID=$4
                echo "set stream to $STREAM_ID"
            fi

            if [ $2 == "get" ]; then 
                cov-manage-findings --dir $IDIR_NAME --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --action readFromConnect --report my_findings_report_output.xlsx
                chmod 777 my_findings_report_output.xlsx
            fi

            if [ $2 == "check" ]; then 
                cov-manage-findings --dir $IDIR_NAME --priority-filter my_findings_report_output_up.xlsx --action readFromReport --report my_findings_report_output_test.xlsx
            fi
            if [ $2 == "set" ]; then 
                cov-manage-findings --dir $IDIR_NAME --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --action sendToConnect --priority-filter my_findings_report_output_up.xlsx
            fi
            exit 1
            ;;
         -h|--help)
             echo "[option] config -> setup -> analysis -> commit"
             echo " -c : config (select : cdk-audio, libomxil-telechips, gst-plugins-telechips)"
             echo " -s : setup (cleanall, build)"
             echo " -a : analysis (config dir: $CONFIGS_DIR)"
             echo " -e : commit (parsing from converity.conf, if it has addtional stream_id then will be applied"
             echo " -f : filter"
             echo "      get   : get execl file from stream server. please check telechips wiki https://wiki.telechips.com:8443/pages/viewpage.action?pageId=208798206"
             echo "      check : check the filter is correct"
             echo "      set  : update filter excel (if want to result in web server, please commit after done set"
             echo " -h : help"
             exit 1
             ;;
    esac
done