#!/bin/bash

# 스크립트에 파일 경로가 제공되지 않았을 경우 오류 메시지 출력 후 종료
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/file"
    exit 1
fi

# 입력 파일에서 중복을 제거하여 고유한 파일 이름만 추출
sort -u "$1" | awk -F/ '{print $NF}'
