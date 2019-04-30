import subprocess
import sys

"""
This program runs all interesting optimizations of syr2k with various sizes to
collect timing results.

# Requirements:

1.

It must be run in the directory that contains 'syr2k.hllo.chpl', 'syr2k.h' and
a folder named 'c-codes' that contains 5 versions of syr2k.

2.

There must be a utilities folder that is standard with polybench.


# Instructions:

Run this as 'python3 run-timing.py'.

You might see some meaningless output. Ignore that.

The relevant times will be in a file called 'current-timing-results-clean'.

Enjoy!
"""

# Number of Repeats
repeatCount = 5

# File to store output
timeFileName = sys.argv[1]
timeFile = open(timeFileName, "w")

# Versions of C Code
#cCodeInfixes = ["backup", "pluto", "plutotile",
#        "plutotileparallel", "dstblock"]
#cCodeInfixes = ["limlam", "plutotileparallel", "dstblock"]

#cCodeInfixes = ["plutotileparallel", "dstblock"]
#cCodeInfixes = ["dstblock", "dstblock2"]
#cCodeInfixes = ["swap"]
#cCodeInfixes = ["limlam"]
#cCodeInfixes = ["dstblock3", "dstblock-timetile", "plutotileparallel"]
#cCodeInfixes = ["dstblock3", "dstblock-tile"]
#cCodeInfixes = ["limlamtile"]
#cCodeInfixes = ["limlam", "limlam2"]
#cCodeInfixes = ["dstblock3"]
#cCodeInfixes = ["plutotileparallel"]


## OFFICIAL: April 29th
# Sequential:
#cCodeInfixes = ["pluto", "dstblock"]
# Parallel
cCodeInfixes = [ "dstblock3par", "limlam-par", "plutotileparallel", "pp-dst"]

cCodes = ["c-codes/syr2k." + i + ".c" for i in cCodeInfixes]


# Versions of Chapel Code
chplfile = "syr2k.hllo.chpl"
iterChoicePostfixes = ["original", "pluto", "ptile", "ptilepar"]
iterChoices = ["IterChoice." + i for i in iterChoicePostfixes]
chplVersions = [(i,"OriginalArr") for i in iterChoices]
transVersion = ("IterChoice.original", "TransposedArr")
chplVersions.append(transVersion)
chplVersions = []



# Sizes for C Code
#cArgs = ["SMALL", "MEDIUM", "LARGE", "HAVERLARGE", "HAVEREXTRALARGE"]
#cArgs = ["SMALL", "MEDIUM"]
#cArgs = ["HAVERLARGE", "HAVEREXTRALARGE"]
#cArgs = ["LARGE", "HAVERLARGE"]


## Official April 29th
# Sequential
#cArgs = ["MEDIUM", "LARGE", "HAVERLARGE", "EXTRALARGE"]
# Parallel
cArgs = ["MEDIUM","LARGE", "HAVERLARGE", "EXTRALARGE", "HAVEREXTRALARGE"]

cSizes = ["PLY_SIZE=-D" + i + "_DATASET" for i in cArgs]



# Sizes for Chpl Codes (N,M)
hsmall = ("hsmall", 24, 20)
medium = ("medium", 240, 200)
large = ("large",1200, 1000)
hlarge = ("hlarge", 2200, 1800)
hxlarge = ("hxlarge", 2700, 2500)
#chplSizes = [hsmall, medium, large, hlarge, hxlarge]
chplSizes = [hsmall]


def runcmd(command):
    """
    The command is a list of words without spaces.
    For command = ["echo", "2"] we run "echo 2".
    We print the output and save it to a file.
    """
    cmdRun = subprocess.Popen(command, stdout=subprocess.PIPE)
    cmdRun.wait() # always wait for termination
    output = cmdRun.communicate()[0].decode("utf-8")
    timeFile.write(output);
    timeFile.flush()
    print(output)

def myPrint(s1, *strings):
    line = str(s1)
    for s in strings:
        line += " " + str(s)
    line += "\n"
    timeFile.write(line)
    timeFile.flush()
    print(line)


def cCompile(fileName, size):
    """
    The fileName string specifies the version.
    The size is the parameter to give to the Makefile.
    The output binary is named 'syr2k'.
    """
    # Copy file to syr2k.c
    copyCmd = ["cp", fileName, "syr2k.c"]
    runcmd(copyCmd)
    base = "make"
    target = "syr2k"
    cmd = [base, target, size]
    runcmd(cmd)
    myPrint("\n\n======")
    myPrint("Compiled C Version", fileName, "on size", size)
    myPrint("======\n\n")

def cRun():
    for i in range(repeatCount):
        runcmd(["./syr2k"])

# For sequential runs on keller:
        #runcmd(["taskset","-c", "3", "./syr2k"])



def chplCompile(fileName,size,version):
    """
    fileName is a string; size = (name,N,M);
    version = (IterChoice.<choice>, <dstRecordType>)
    The compiled binary is named 'syr2kchpl'.
    """
    base = "./compilechplprog.sh"
    (sizename,n,m) = size
    (choice,recClass) = version
    cmd = [base, fileName, str(n), str(m), choice, recClass]
    runcmd(cmd);
    myPrint("\n\n======")
    myPrint("Compiled Chpl Version", version, "on size", sizename)
    myPrint("======\n\n")

def chplRun():
    for i in range(repeatCount):
        runcmd(["./syr2kchpl"])



def cTimingResults():
    for code in cCodes:
        for size in cSizes:
            cCompile(code, size)
            cRun()
            runcmd(["rm", "syr2k"])
            runcmd(["rm", "syr2k.c"])

def chplTimingResults():
    for ver in chplVersions:
        for size in chplSizes:
            chplCompile("syr2k.hllo.chpl", size, ver)
            chplRun()
            runcmd(["rm", "-f", "syr2kchpl"])



def runTimes():
    myPrint("Starting timing results. \n\n")
    myPrint("==================\n\n")
    cTimingResults()
    chplTimingResults()
    myPrint("\n\n==================")
    myPrint("Ended timing results. \n\n")

def validLine(line):
    spacer1 = line.startswith("====")
    spacer2 = line.startswith("Starting timing")
    stateVer1 = line.startswith("Compiled C Version")
    stateVer2 = line.startswith("Compiled Chpl Version")
    time1 = line.endswith("GFLOPS\n")
    time2 = line.startswith("GFLOPS rate:")
    isValid = ( spacer1
            or spacer2
            or stateVer1
            or stateVer2
            or time1
            or time2 )
    return isValid

def cleanup(fileName):
    introMsgSize = 5
    newFileName = fileName + "-clean"
    with open(fileName, "r") as givenFile:
        with open(newFileName, "w") as newFile: 
            preamb = True
            while (preamb):
                currLine = givenFile.readline()
                preamb = not currLine.startswith("uptime over")
                newFile.write(currLine)
            for line in givenFile:
                if (validLine(line)):
                    newFile.write(line)

def printStartMsg():
    wprint = ["echo", "uptime"]
    wprint2 = ["echo", "uptime over"]
    wcmd = ["w"]
    runcmd(wprint)
    runcmd(wcmd)
    runcmd(wprint2)
    print("Note that if the load average" +
        " is not low enough, these tests are invalid!")
    cont = input("Hit y to continue: ")
    return cont=="y"
    return True;



def main():
    if (printStartMsg()):
        runTimes()
        cleanup(timeFileName)
        timeFile.close()
        #subprocess.Popen(["rm", timeFileName])
    else:
        myPrint("Unsuitable conditions. We terminated.")


main()



