# slotRewards
Bash script to view the rewards of a solana validator in a given epoch

This script is still under development and may not yet be optimised.
It is supplied as is.

This script sets the current or specified epoch and identity account for a Solana validator node.
It takes up to two optional arguments to customize the epoch and identity account.

Prerequisites
this script needs jq - commandline JSON processor

Parameters

    $1 (Optional): Specifies the epoch to be set. Possible values are:

        If not provided or if set to 'this', it sets the current epoch.

        If set to 'last', it sets the previous epoch and provides to append the result on a CSV file (if it does not exist it will be created).

        If set to a specific numeric value, it sets the epoch to that value.

    $2 (Optional): Specifies the identity account. If not provided, a default identity account is used.
					If you need to set identity account, you must provide the first argument too

Usage:

To run the script, use the following command:
	./slotRewards.sh [epoch] [identity_account]


# License

This project is licensed under the X11 License:

Copyright (C) 2023 Cayetas | YontaLabs

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE X CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of <copyright holders> shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Cayetas | YontaLabs.
