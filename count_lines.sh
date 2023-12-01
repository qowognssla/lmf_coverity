#!/bin/bash

# 사용자로부터 경로를 인자로 받음
INPUT_DIRECTORY=$1

# 경로가 제공되지 않은 경우 에러 메시지 출력 후 종료
if [ -z "$INPUT_DIRECTORY" ]; then
    echo "Usage: $0 /path/to/dir"
    exit 1
fi

# 입력된 경로의 절대 경로를 구함
ABSOLUTE_DIRECTORY=$(realpath "$INPUT_DIRECTORY")

echo "Counting lines in each .c and .h file in $INPUT_DIRECTORY and its subdirectories"

# .c 파일과 .h 파일을 찾고 각 파일의 라인 수를 계산하여 출력
find "$INPUT_DIRECTORY" -name "*.c" -o -name "*.h" | while read file
do
    if [ -f "$file" ]; then
        # 파일의 절대 경로를 구함
        absolute_file=$(realpath "$file")

        # 입력된 경로에 대한 상대 위치를 계산
        relative_file=${absolute_file#$ABSOLUTE_DIRECTORY/}

        # 라인 수 계산
        lines=$(wc -l < "$file")

        # 결과 출력
        echo "$relative_file: $lines lines"
    fi
done
