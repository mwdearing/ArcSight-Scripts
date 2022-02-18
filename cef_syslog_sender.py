import logging
import logging.handlers
# You can uncomment out the below import statment and comment out the handler_udp and uncomment handler_tcp for TCP use with this script.
import socket

# <!--- TO DO ---!> #
# <!--- Add user prompts ---!> #
 
###################
# Server settings #
###################
count = 2 # Of copies sent
host = '192.168.1.1'
port = 555
proto = 1 # 1 for UDP and 2 for TCP

# Edit the cef var to define your field values. 
# Format example
# CEF:Version|Device Vendor|Device Product|Device Version|Device Event Class ID|Name|Severity|[Extension]
cef = "CEF:0|Microsoft|Exchange Server|0.0.0|SENDEXTERNAL|LDAP_BIND|4|deviceFacility=TestInformation act=TesttUser reason=Test Event outcome=SUCCESS flexString1=cn\=Test,ou\=ctr,ou\=users,o\=thrivent cs3Label=loggedInUser src=10.10.10.10 suid=cn\=McCheese,ou\=Users,ou\=public,o\=thrivent requestMethod=GET request=/portal/mythrivent/home/summary/!ut/p/z1/04_Sj9CPykssy0xPLMnMz0vMAfIjo8ziPYL9LIx app=HTTP/1.1"


# <!--- Don't edit below here ---!>
# Initializing logger module.

ceflogger = logging.getLogger("Test Event")

# Setting syslog message level to INFO

ceflogger.setLevel(logging.INFO)

# <!--- Conditions defined to add prompts in the future ---!>
# Defining the syslog handler 
if proto == 2:
    handler = logging.handlers.SysLogHandler(address = (host,port),  socktype=socket.SOCK_STREAM)
    ceflogger.addHandler(handler)
    track = 0
    while track < count:
        ceflogger.info(cef + '\n') # Require a new line at the end of eatch message to send over TCP.
        track = track + 1
else:
    handler = logging.handlers.SysLogHandler(address = (host,port))
    ceflogger.addHandler(handler)
    track = 0
    while track < count:
        ceflogger.info(cef)
        track = track + 1
