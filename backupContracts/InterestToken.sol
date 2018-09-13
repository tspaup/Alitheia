pragma solidity ^0.4.24;

contract InterestToken{
	// Creation Year
    uint private contractYear;

    // Creation Month
    uint private contractMonth;
    
    // At least once paid
    mapping(address => bool) private interestPaid;

    // Last Paid Year
    mapping(address => uint) private interestYear;

    // Last Paid Month
    mapping(address => uint) private interestMonth;

    // Address -> Year -> Month -> Amount
    mapping(address => mapping (uint => mapping (uint => uint256))) private interestTokens;
    
    constructor(uint _year, uint _month) public{
    	contractYear = _year;
    	contractMonth = _month;
    }

	// Clear Interests : We clear the interests on the very first day of the next month
    function clearInterests(address _owner, uint _year, uint _month) private returns (bool){
        uint endYear = _year;
        uint endMonth = _month;

        if(endMonth == 1){
            endMonth = 12;
            endYear--;
        }else
            endMonth--;

        if(contractYear > endYear || (contractYear == endYear && contractMonth >= endMonth)){
            return true;
        }else{
            uint startYear = 0;
            uint startMonth = 0;

            if(!interestPaid[_owner]){
                startYear = contractYear;
                startMonth = contractMonth;
            }else{
                if(interestYear[_owner] > endYear || (interestYear[_owner] == endYear && interestMonth[_owner] >= endMonth)){
                    return true;
                }else{
                    if(interestMonth[_owner] == 12){
                        startYear = interestYear[_owner] + 1;
                        startMonth = 1;
                    }else{
                        startYear = interestYear[_owner];
                        startMonth = interestMonth[_owner] + 1;
                    }
                }
            }

            bool flag = true;
            while(flag){
                clearOneInterest(_owner, startYear, startMonth);

                if(startMonth == 12){
                    startMonth = 1;
                    startYear++;
                }else
                    startMonth++;

                if(startYear > endYear || (startYear == endYear && startMonth > endMonth))
                    flag = false;
            }
        }
    }

    // Clear One Interest
    function clearOneInterest(address _owner, uint year, uint month) private returns (bool) {
        if(holderDays[_owner][year][month].length > 0){
            

            for(uint i = 0; i < holderDays[_owner][year][month].length; i++){
                uint day = holderDays[_owner][year][month][i];

                if(holderTokens[_owner][year][month][day].packages.length > 0){
                    for(uint j = 0; j < holderTokens[_owner][year][month][day].packages; j++){
                        Package memory _package = holderTokens[_owner][year][month][day].packages[j];


                    }
                }
            }
        }

        if(!interestPaid[_owner])
            interestPaid[_owner] = true;
        interestYear[_owner] = year;
        interestMonth[_owner] = month;

        return true;
    }
}