import os
import sys

###
# Script to count the total number of test cases per generated chipsalliance vector unit test.  Result should be passed as an argument to verilator_main to verify that all test cases have actually been tested (in case of an RTL control flow issue)
###

n = len(sys.argv)
if (n != 2):
    sys.exit("ERROR: Bad input arguments.  Correct usage 'python3 count_test_cases.py [path to test case asm file]'")

test_case_asm = open(sys.argv[1], "r")
test_case_dict = []
for line in test_case_asm:
    test_case_dict.append(line)

for line in reversed(test_case_dict):
    if "TEST_CASE" in line:
        line=line.replace(",","(")
        line=line.split("(")
        print(str(line[1]), end="")
        sys.exit()