import json
import csv
import os

TARGET_PATH_SUBSTRING = os.environ.get('TARGET_PATH_SUBSTRING')

with open('tc_results.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

file_checker_counts = {}

total_misra = 0
total_cert = 0
total_his = 0
total_runtime = 0

for issue in data.get('issues', []):
    file_path = issue.get('strippedMainEventFilePathname', '')
    checker_name = issue.get('checkerName', '')
    if file_path and checker_name:
        if TARGET_PATH_SUBSTRING in file_path:
            if file_path not in file_checker_counts:
                file_checker_counts[file_path] = {}
            file_checker_counts[file_path][checker_name] = file_checker_counts[file_path].get(checker_name, 0) + 1
            
            if "MISRA C" in checker_name:
                total_misra += 1
            elif "CERT " in checker_name:
                total_cert += 1
            elif "HIS_" in checker_name:
                total_his += 1
            else:
                total_runtime += 1

file_error_counts = {}

for file_path, checker_dict in file_checker_counts.items():
    total_errors = sum(checker_dict.values())
    file_error_counts[file_path] = total_errors

with open('file_checker_counts.csv', 'w', newline='', encoding='utf-8-sig') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['파일 경로', '체커 이름', '에러 수'])
    for file_path, checker_dict in file_checker_counts.items():
        for checker_name, count in checker_dict.items():
            writer.writerow([file_path, checker_name, count])

with open('file_error_counts.csv', 'w', newline='', encoding='utf-8-sig') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['파일 경로', '전체 에러 수'])
    for file_path, total_errors in file_error_counts.items():
        writer.writerow([file_path, total_errors])

print("### 총 에러 집계 ###")
print(f"총 MISRA 갯수: {total_misra}")
print(f"총 CERT 갯수: {total_cert}")
print(f"총 Code Metric (HIS) 갯수: {total_his}")
print(f"총 Run-Time Error Check 갯수: {total_runtime}")
print("\n데이터 처리가 완료되었습니다. 'file_checker_counts.csv'와 'file_error_counts.csv' 파일을 확인하세요.")
