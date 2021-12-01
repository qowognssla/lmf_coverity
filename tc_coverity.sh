#!/bin/bash

export CODE_BASE_DIR=`pwd`
HERE=$(dirname $(realpath $0))
IDIR_DIR=$CODE_BASE_DIR/idir
TC_COVERITY_DIR=~/source/100.common/tc_coverity
COVERITY_PLUGIN_DIR=~/.synopsys/desktop/controller/logs
CONFIGS_DIR=$TC_COVERITY_DIR/configs/latest-release

if [ -d "/home/coverity" ]; then
    CONFIGS_DIR=/home/coverity/cov-analysis-linux64/telechips-config/latest-release
fi
echo CONFIGS_DIR : $CONFIGS_DIR

CLI_MAKE=$TC_COVERITY_DIR/cli_make.sh
CLI_CLEAN=$TC_COVERITY_DIR/cli_clean.sh
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
            mapfile array < <(find $TC_COVERITY_DIR -maxdepth 1 -type f -name "*.conf" -exec basename {} \;)
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
                cp -r $TC_COVERITY_DIR/${array[$CONFIG_INDEX]} $CODE_BASE_DIR/coverity.conf

                if [ -f $CODE_BASE_DIR/tc_coverity ]; then
                    rm -rf $CODE_BASE_DIR/tc_coverity
                fi

                echo setting up tc_coverity directory
                ln -s $HERE/tc_coverity $CODE_BASE_DIR/tc_coverity

            else   
                echo "Error: there are no conf file in tc_coverity directory"
            fi
            exit 1
            ;;
        -s|--setup)
            if [ -f $CODE_BASE_DIR/coverity.conf ]; then
                if [ -d $IDIR_DIR ]; then
                    rm -rf $IDIR_DIR
                fi
                BUILD_CMD=`cat $CODE_BASE_DIR/coverity.conf | python3 -c "import sys, json; print(' '.join(json.load(sys.stdin)['settings']['cov_run_desktop']['build_cmd']))"`
                CLEAN_CMD=`cat $CODE_BASE_DIR/coverity.conf | python3 -c "import sys, json; print(' '.join(json.load(sys.stdin)['settings']['cov_run_desktop']['clean_cmd']))"`
                
                echo $BUILD_CMD

                if [ -f $CODE_BASE_DIR/autolinux ]; then
                    CLEAN_CMD=${CLEAN_CMD/build /build \"}
                    CLEAN_CMD=${CLEAN_CMD/cleanall/cleanall\"}
                fi
                eval $CLEAN_CMD
                
                cov-build --dir $IDIR_DIR  --emit-complementary-info --config $TC_COVERITY_DIR/lmf_coverity_config/coverity_configure_lmf.xml $BUILD_CMD
                
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
                cov-analyze --dir $IDIR_DIR --disable-default \
                --coding-standard-config $CONFIGS_DIR/misrac2012-telechips-210728.config \
                --coding-standard-config $CONFIGS_DIR/cert-c-telechips-210714.config \
                --coding-standard-config $CONFIGS_DIR/cert-c-recommendation-telechips-210714.config \
                --config $TC_COVERITY_DIR/lmf_coverity_config/coverity_configure_lmf.xml \
                --parse-warnings-config $CONFIGS_DIR/parse_warnings_telechips_211119.conf \
                @@$CONFIGS_DIR/runtime_rules_telechips_211119.txt

            else
                echo "the captured directory not exist"
            fi
            exit 1
            ;;
        -e|--commit)
            if [ -d $IDIR_DIR ]; then
                cov-commit-defects --dir $IDIR_DIR --url http://coverity.telechips.com:8080 --user telechips07 --password telechips07 --stream $STREAM_ID
            else
                echo "the captured directory not exist"
            fi
            exit 1
            ;;
        -f|--filter)
            if [ $2 == "get" ]; then 
                cov-manage-findings --dir $IDIR_DIR --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user telechips07 --password telechips07 --action readFromConnect --report my_findings_report_output.xlsx
                chmod 777 my_findings_report_output.xlsx
            fi

            if [ $2 == "check" ]; then 
                cov-manage-findings --dir $IDIR_DIR --priority-filter my_findings_report_output_up.xlsx --action readFromReport --report my_findings_report_output_test.xlsx
            fi
            if [ $2 == "set" ]; then 
                cov-manage-findings --dir $IDIR_DIR --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user telechips07 --password telechips07 --action sendToConnect --priority-filter my_findings_report_output_up.xlsx
            fi
            exit 1
            ;;
        -h|--help)
            echo ""

            exit 1
            ;;
        -t|--test)
            echo ""
                eval $CLI_MAKE omx
            exit 1
            ;;
    esac
done