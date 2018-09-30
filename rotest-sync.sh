#!/usr/bin/env bash

# Reapeat an automated test multiple times.
# Synchronize the source code between programmer's workstation and the testing machine
# after a failure. Suppose a correction in the code has been made.
# Reset the counter of successful iterations on error.
# Upload the results as HTML file at server for free file transfer.
# Expect command-line parameters.
# TEST=${1:?"Error. Missing test name."}

export TEST="gcc_wifi_wep_phrase"
i=1
while true; do
    echo '====================='
    echo " Iteration: $i"
    echo '====================='
    rsync -av $SRC_CODE/* $TEST_DIR/
    sleep 2
    ./runtest.sh $TEST
    if [ $? -eq 0 ]; then
        echo -e "\nIteration: $i - PASS"
        sleep 2
        ((i++))
    else
        echo -e "\nIteration $i - FAILED" >&2
        read key
        while [[ $ANSWER != [YyNn] ]]; do
            read -p "Upload results?(Y/N): " ANSWER
            case $ANSWER in
                [Yy])
                curl --upload-file "/tmp/report_$TEST.html" "https://transfer.sh"
                echo
                echo "Upload completed"
                exit 0
                ;;
                [Nn])
                while [[ $ANSWER2 != [YyNn] ]]; do
                    read -p "Do you want to reapeat again?(Y/N): " ANSWER2
                    case $ANSWER2 in
                    [Yy])
                    echo "Restart test $TEST"
                    sleep 2
                    i=1
                    ;;
                    [Nn])
                    echo "Finished tesing"
                    sleep 2
                    exit 0
                    ;;
                    *)
                    echo "Incorrect answer $ANSWER2. Should be Y/N."
                    sleep 1
                    ;;
                    esac
                    done
                sleep 2
                ;;
                *)
                echo "Incorrect answer $ANSWER. Should be Y/N."
                sleep 2
                ;;
            esac
        done

    fi
done