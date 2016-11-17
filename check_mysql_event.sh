# Checks a MySQL Event By Database Name

VERSION="0.2"

# Debug
#set -x 

# Help Message
help(){
        echo ""
        echo -e "DESCRIPTION:"
        echo ""
        echo -e "\t check_mysql_event.sh Designed as an NRPE checks for checking the last time an event ran"
        echo ""
        echo -e "SYNOPSIS: "
        echo ""
        echo -e "\t check_mysql_event.sh -d database -e event [ -w warning ] [ -c critical ] [ -U username] [ -P password] " 
        echo ""
        echo -e "SETTINGS: "
        echo ""
        echo -e "\t-h     Display this Help Message"
        echo -e "\t-U     Username Not Set by Default. Use my.cnf if no user"
        echo -e "\t-P     Password Not Set by Default. Use my.cnf if no pass"
        echo -e "\t-d     database (Required) "
        echo -e "\t-e     event (Required) "
        echo -e "\t-w     Warning Amount in Seconds (Defaults to 90000 / 25 Hours )"
        echo -e "\t-c     Critical Amount in Seconds (Defaults to 262800 / 73 Hours)"
        echo ""
        echo ""
}

check_event(){
    # Variable to Contain authentication info
    ass=$1
    # -N & -B No headers and Batch mod (Tabs)
    CHECKOUTPUT=$(mysql -N -B -e "select LAST_EXECUTED from INFORMATION_SCHEMA.EVENTS where EVENT_SCHEMA='$database' and EVENT_NAME='$event'" information_schema $ass)
    # Find out how long ago it ran
    last_run=$( date -d "$CHECKOUTPUT" +%s )
    # Get Today
    now=$(date +%s)
    # Get Difference Between the two
    let seconds_ago=$now-$last_run
    # See if It's bad
    if [[ $seconds_ago -gt $crit ]] ; then
        ## Throw a Critical Error
        echo -e "Critical - Last Event Ran over $crit seconds_ago | timeBack = $seconds_ago "
        exit 2
    elif [[ $seconds_ago -gt $warn ]] ; then
        ## Throw a Warning
        echo -e "Warning - Last Event Ran over $warn seconds_ago | timeBack = $seconds_ago "
        exit 1
    else
        ## We're Good
        echo -e "OK - Event is $seconds_ago fresh | timeBack = $seconds_ago "
        exit 0
    fi;
}

# Get CLI Flags
while getopts "U:P:w:c:d:e:w:c:hv" OPTIONS; do
    case $OPTIONS in
        U) DBUSER=${OPTARG};;
        P) DBPASS=${OPTARG};;
        d) database=${OPTARG};;
        e) event=${OPTARG};;
        w) warn=${OPTARG};;
        c) crit=${OPTARG};;
        v) echo Version : $VERSION; exit 0;;
        h) help; exit 0;;
    esac
done

## Check if User has been specified
if [[ $database == "" ]] ; then
    echo -e "ERROR: Requires a Database"
    help
    exit 3
elif [[ $event = "" ]] ; then
    echo -e "ERROR: Requires an Event"
    help 
    exit 3
fi;

## Set Defaults

### Set Default Warning
if [[ $warn == "" ]] ; then
    # Set it to 25 Hours in Seconds
    warn=90000
fi;

## Set Default Crit
if [[ $crit == "" ]] ; then
    # Set it to 73 Hours in Seconds
    crit=262800
fi;

if [[ $DBUSER == "" ]] ; then
    ## Do Check with No User/Password
    check_event
elif [[ $DBPASS == "" ]] ; then 
    ## Do Check with User but No Password
    check_event "--user=$DBUSER"
else
    ## Have User & Password
    check_event "--user=$DBUSER --password=$DBPASS"
fi

echo -e "Check Error Please Investigate | timeBack=0"
exit 3


