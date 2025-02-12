#!/bin/bash

# 2023 Cayetas | YontaLabs

Red='\033[0;31m'
Green='\033[0;32m'
Blue='\033[0;34m'

BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIBlue='\033[1;94m'

BIRedBlk='\033[5;91m'

Uline='\033[4m'

NC='\033[0m' # No Color
NT='\033[m' # No Text

ID_ACCOUNT=""
EPOCH=""

ToBeAppend=true

# print bars: The longer it is, the greater the gain
print_bars() {
	local num=$1
		
	local result=$(echo "$num * 100" | bc )

	# Round to the nearest integer
	local squares=$(echo $result | awk '{printf "%.0f", $1}')
	
	for ((i=0; i<$squares; i++)); do
		if [ "$i" -lt 10 ]; then 
			echo -n -e "${Green}■${NC}"
		elif [ "$i" -ge 10 ] && [ "$i" -lt 45 ]; then
			echo -n -e "${BIBlue}■${NC}"
		elif [ "$i" -ge 45 ] && [ "$i" -lt 65 ]; then
			echo -n -e "${Red}■${NC}"
		elif [ "$i" -ge 65 ] && [ "$i" -lt 66 ]; then
			echo -n -e "${BIRedBlk}-->${NC}"
		fi
	done
	echo ""
}

if test -z "$1" -o "$1" = "this" -o "$1" = $(solana epoch)
then
    # Set the current Epoch
	EPOCH=$(solana epoch)
	ToBeAppend=false
elif [ "$1" = "last" ];
then
	# Set the previous epoch
	EPOCH=$(solana epoch)
	EPOCH=$(($EPOCH - 1))
elif [ "$1" -eq "$1" ] 2>/dev/null;
then
	# Set Epoch with the passed value
	EPOCH=$1
else
	# NaN
	echo "Error: First argument is not an epoch"
    exit 1
fi

if test -z "$2"
then
    # Set the default identity account
	ID_ACCOUNT="BeSovDCzhEAfgwDyXBuhmCFKsu5WQ3PaX61GEfteNzXM"
else
	#Set identity account with the passed value
	ID_ACCOUNT=$2
fi

# Find validator name
VALIDATOR_NAME=$(solana validator-info get | grep $ID_ACCOUNT -A 5 | grep Name: | cut -d ':' -f 2 | tr -d ' ')

# Create the CSV file
CSV_FILE=./leaderSlots$VALIDATOR_NAME.csv
if [[ ! -f "$CSV_FILE" && "$ToBeAppend" = true ]]; then
	touch $CSV_FILE
	echo "Sep=;" >> $CSV_FILE
	echo "Epoch,Stake Amount,Approved Slots,Rewards (SOL),Skipped Slots" >> $CSV_FILE
fi

# Imposta il cluster da usare (mainnet-beta, testnet, devnet o localhost)
#solana config set --url mainnet-beta

LASTSLOT=$(solana slot)
echo "LASTSLOT: $LASTSLOT"
echo -e "ID_ACCOUNT: $ID_ACCOUNT (${BIBlue}$VALIDATOR_NAME${NC})"
echo "EPOCH: $EPOCH"

# Get the list of slots where the validator is leader in the epoch
SLOTS=$(solana leader-schedule --epoch $EPOCH --output json | jq ".leaderScheduleEntries[] | select(.leader == \"$ID_ACCOUNT\") | .slot")

# Create a temporary file to save blocks produced by the validator
TMP_FILE=$(mktemp)

# Initialize a variable to count invalid or unconfirmed slots
INVALID_SLOTS=0
VALID_SLOTS=0

SKIPPED_SLOTS=0
PRODUCED_SLOTS=0

# Iterates through all slots in the list and saves the valid and confirmed ones in the temporary file
for SLOT in $SLOTS; do
	if [ $SLOT -gt 0 ]; then
		# Check if the slot exists and if it is confirmed
		
		if [ "$SLOT" -le "$LASTSLOT" ]; then
			echo $SLOT >> $TMP_FILE
			# echo "$SLOT"
			VALID_SLOTS=$(($VALID_SLOTS + 1))
		else
			# Otherwise, increment the invalid or unconfirmed slot counter
			INVALID_SLOTS=$(($INVALID_SLOTS + 1))
		fi
	fi
done

echo "Leader Slots for the epoch $EPOCH: $VALID_SLOTS"
# If there are invalid or unconfirmed slots, print a warning message
if [ $INVALID_SLOTS -gt 0 ]; then	
	echo "Warning: There are $INVALID_SLOTS invalid or not (yet) confirmed slots in the list. These slots will be ignored when calculating rewards."
fi

TOTAL_REWARD=0

PROCESSED=false
# Iterates over all blocks produced by the validator and adds the rewards received
while read SLOT; do

	for i in {1..3}; do	
		echo "processing Slot: $SLOT"
		
		REWARD=$(solana block $SLOT --output json | jq "[.rewards[] | select(.pubkey == \"$ID_ACCOUNT\") | .lamports] | add")
		
		if [ -n "$REWARD" ] && [ "$REWARD" -eq "$REWARD" ] 2>/dev/null; then
			#echo valid number
			PROCESSED=true
			break
		else
			echo Not a number. Retrying: $SLOT
			PROCESSED=false
			sleep 1
		fi	
	done
	
	if [ "$PROCESSED" = true ]; then
		REWARD_SOL=$(echo "scale=9; $REWARD / 1000000000" | bc)
		
		# # If reward is at least 0.1 sol (aka juicy reward)
		# if [ "$REWARD" -ge 100000000 ]; then
			# #echo -e "${Uline}SLOT $SLOT -> Reward:${NT} ${BIGreen}$REWARD${NC} (${BIGreen} $REWARD_SOL sol ${NC}) ${BIRedBlk} <- Juicy Reward ${NC}"
		# else
			# echo -e "${Uline}SLOT $SLOT -> Reward:${NT} ${Green} $REWARD ${NC} (${Green} $REWARD_SOL sol ${NC})"
		# fi
		
		echo -n -e "${Uline}SLOT $SLOT -> Reward:${NT} ${Green} $REWARD ${NC} (${Green} $REWARD_SOL sol ${NC})"
		print_bars $REWARD_SOL
		
		TOTAL_REWARD=$(($TOTAL_REWARD + $REWARD))
		PRODUCED_SLOTS=$(($PRODUCED_SLOTS + 1))
	else
		SKIPPED_SLOTS=$(($SKIPPED_SLOTS + 1))
	fi

done < $TMP_FILE

rm $TMP_FILE

# lamports to SOL
TOTAL_REWARD=$(echo "scale=9; $TOTAL_REWARD / 1000000000" | bc)

echo "Epoch: $EPOCH - $ID_ACCOUNT ($VALIDATOR_NAME) has received $TOTAL_REWARD SOL with $PRODUCED_SLOTS leader slots and $SKIPPED_SLOTS skipped"

if [[ -f "$CSV_FILE" && "$ToBeAppend" = true ]]; then
	STAKE=$(solana validators | grep $ID_ACCOUNT | grep -o -E ' [0-9]+\.[0-9]+' | tail -n 1 | cut -d '.' -f 1 | tr -d ' ')
	echo "$EPOCH;$STAKE;$PRODUCED_SLOTS;$TOTAL_REWARD;$SKIPPED_SLOTS" >> $CSV_FILE
fi