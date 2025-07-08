import os
import sys
###
# Script to compare commit logs between Spike and Vicuna Verilator simulation.  Currently, only compares vector register commits due to differences between address space for Spike and Verilator.  TODO: Find a fix for this and compare Xregs too
#
###
n = len(sys.argv)
if (n != 3):
    sys.exit("ERROR: Bad input arguments.  Correct usage 'python3 compare_commits.py [vreg_w] [test_name]'")

exitcode=0

vreg_w = int(sys.argv[1])
test_name = sys.argv[2]

cur_dir = os.getcwd()


spike_commit_log = []
vreg_commit_log = []

spike_commit_log_file = open(cur_dir + "/" + test_name + "_register_commits_Spike.txt", "r")
vreg_commit_log_file = open(cur_dir + "/" + test_name + "_vreg_commits_verilator.txt", "r")



#parse all elements in log, create ordered array of ["VREG", "VALUE"]
for line in spike_commit_log_file:
    #Filter out all non-vreg commits
    #print(line)
    line=line.replace("  ", " ")
    line=line.replace("\n", "")
    line=line.split(" ")
    #Filter out all non-vreg commits.  Vreg writes have the element width at the fifth element (e8, e16, e32).  Includes accesses to memory(vector stores)
    if (len(line) >= 10):
        if (line[6].find('e') != -1):
            e=int(line[6].replace("e", ""))
            vl=int(line[8].replace("l", ""))
            lmul=1
            if (line[7].find('f') == -1):
                lmul=int(line[7].replace("m", ""))

            vl_bytes = int(e*vl/8)

            for i in range(int((len(line)-8)/2)):
                #Filter out all commits that don't write to a vreg
                if (line[9+2*i].find('v') != -1 and line[9+2*i].find('_') == -1):
                    ## need to mask out values not written (ie outside of vl)
                    commit_data = ""
                    for j in reversed(range(int(vreg_w/8))):
                        
                        if(not vl_bytes > 0):
                            commit_data = "XX" + commit_data 
                        else:
                            commit_data = line[10+2*i][j*2+2]+ line[10+2*i][j*2+2+1] + commit_data
                            vl_bytes=vl_bytes-1

                    spike_commit_log.append([line[9+2*i], "0x"+ commit_data])
                

for line in vreg_commit_log_file:
    line=line.replace("\n", "")
    line=line.split(" ")
    vreg_commit_log.append(line)




##perform comparison between the commit logs. NOTE: it is possible for verilator commits to be in a different order than in spike (due to operations in different pipelines with no data dependencies)

print("vreg commits " + str(len(vreg_commit_log)))
print("spike commits " + str(len(spike_commit_log)))

if(len(vreg_commit_log) != len(spike_commit_log)):
    print("WARNING: COMMIT LOG LENGTH MISMATCH")
    exitcode = -1

for i in range(len(spike_commit_log)):
    if i < len(vreg_commit_log):
        

        #commit at i in each log should match
        if (spike_commit_log[i][0] == vreg_commit_log[i][0]) and (spike_commit_log[i][1] == vreg_commit_log[i][1]):
            print("Commit " + str(i) + ": VREG - " + str(spike_commit_log[i][0]) + " Value - " + str(spike_commit_log[i][1]))
        else:
            #spike commits do not give any info about masked operations, assume the vicuna mask is correct and mark as a warning.
            correct_masked = True
            for j in range(len(spike_commit_log[i][1])):
                if (spike_commit_log[i][1][j] != vreg_commit_log[i][1][j]) and (vreg_commit_log[i][1][j] != 'X'):
                    #detected a mismatch not caused by a masked out value in the vicuna commit log
                    correct_masked = False

            if correct_masked and (spike_commit_log[i][0] == vreg_commit_log[i][0]):
                print("Commit " + str(i) + ": VREG - " + str(spike_commit_log[i][0]) + " Value - " + str(spike_commit_log[i][1]) + " WARNING - Masked Operation, assuming Vicuna Mask is correct : VREG - " + str(vreg_commit_log[i][0]) + " Value - " + str(vreg_commit_log[i][1]))
            #verilator commits might be out of order.  check commit before and after previous one
            elif ((i+1) < len(vreg_commit_log)-1) and ((spike_commit_log[i][0] == vreg_commit_log[i+1][0]) and (spike_commit_log[i][1] == vreg_commit_log[i+1][1])):
                print("Commit " + str(i) + ": VREG - " + str(spike_commit_log[i][0]) + " Value - " + str(spike_commit_log[i][1]) + " WARNING - Verilator commit out of order vv Verilator : VREG - " + str(vreg_commit_log[i][0]) + " Value - " + str(vreg_commit_log[i][1]))
            elif ((i-1) > 0) and ((spike_commit_log[i][0] == vreg_commit_log[i-1][0]) and (spike_commit_log[i][1] == vreg_commit_log[i-1][1])):
                print("Commit " + str(i) + ": VREG - " + str(spike_commit_log[i][0]) + " Value - " + str(spike_commit_log[i][1]) + " WARNING - Verilator commit out of order ^^ Verilator : VREG - " + str(vreg_commit_log[i][0]) + " Value - " + str(vreg_commit_log[i][1]))
            else:
                print("\nERROR: Commit " + str(i))
                print("Spike:     VREG - " + str(spike_commit_log[i][0]) + " Value - " + str(spike_commit_log[i][1]))
                print("Verilator: VREG - " + str(vreg_commit_log[i][0]) + " Value - " + str(vreg_commit_log[i][1]) +"\n")
                exitcode = -1

exit(exitcode)

#for element in spike_commit_log:
#    print(element)

#for element in vreg_commit_log:
#    print(element)

