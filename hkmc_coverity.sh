#!/bin/bash

CODE_BASE_DIR=`pwd`
HERE=$(dirname $(realpath $0))
IDIR_DIR=$CODE_BASE_DIR/idir
HKMC_COVERITY_DIR=$HERE/hkmc_coverity
COVERITY_PLUGIN_DIR=$HOME/.synopsys/desktop/controller/logs
CONFIGS_DIR=$HKMC_COVERITY_DIR/configs
COVERITY_ID_PASS="telechips07"

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
            mapfile array < <(find $HKMC_COVERITY_DIR -maxdepth 1 -type f -name "*.conf" -exec basename {} \;)
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
                cp -r $HKMC_COVERITY_DIR/${array[$CONFIG_INDEX]} $CODE_BASE_DIR/coverity.conf

                if [ -d $CODE_BASE_DIR/hkmc_coverity ]; then
                    echo "already has tc_coverity dir, re-set up"
                    rm -rf $CODE_BASE_DIR/hkmc_coverity
                fi
                
                echo setting up tc_coverity directory
                ln -s $HERE/hkmc_coverity $CODE_BASE_DIR/hkmc_coverity

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
                
                cd $CODE_BASE_DIR

                soruce build/envsetup.sh
                lunch 15

                cd $CODE_BASE_DIR/kernel

                make tcc803x_android_avn_defconfig
                
                BUILD_CMD="make"
                CLEAN_CMD="find ./drivers/char/vpu -type f -exec touch {} \;"
                
                eval $CLEAN_CMD
                
                cov-build --dir $IDIR_DIR  --emit-complementary-info --config $HKMC_COVERITY_DIR/hkmc_config/hkmc_coverity.xml $BUILD_CMD
                
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
                COV_ANALYZE_OPTIONS="--dir $IDIR_DIR --disable-default \
                --strip-path $CODE_BASE_DIR \
                @@$CONFIGS_DIR/HKMC_C_Rule_v4.txt \
                --coding-standard-config $CONFIGS_DIR/hkmc_certc_v4.config \
                --coding-standard-config $CONFIGS_DIR/hkmc_cert_c_recommendation_v4.config \
                --coding-standard-config $CONFIGS_DIR/hkmc_misrac_v4.config \
                --parse-warnings-config $CONFIGS_DIR/hkmc_c_parse_warnings_v4.config \
                --config $HKMC_COVERITY_DIR/hkmc_config/hkmc_coverity.xml \
                --dc-config $CONFIGS_DIR/DC_CUSTOM_HKMC_C_CHECKER_v4.json"

                cov-analyze $COV_ANALYZE_OPTIONS
            else
                echo "the captured directory not exist"
            fi
            exit 1
            ;;
        -e|--commit)
            if [ -d $IDIR_DIR ]; then
                if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                    cov-commit-defects --dir $IDIR_DIR --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --stream $2
                else
                    #echo "Error: Argument for $1 is missing" >&2
                    cov-commit-defects --dir $IDIR_DIR --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --stream $STREAM_ID
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
                cov-manage-findings --dir $IDIR_DIR --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --action readFromConnect --report my_findings_report_output.xlsx
                chmod 777 my_findings_report_output.xlsx
            fi

            if [ $2 == "check" ]; then 
                cov-manage-findings --dir $IDIR_DIR --priority-filter my_findings_report_output_up.xlsx --action readFromReport --report my_findings_report_output_test.xlsx
            fi
            if [ $2 == "set" ]; then 
                cov-manage-findings --dir $IDIR_DIR --stream $STREAM_ID --url http://coverity.telechips.com:8080 --user $COVERITY_ID_PASS --password $COVERITY_ID_PASS --action sendToConnect --priority-filter my_findings_report_output_up.xlsx
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