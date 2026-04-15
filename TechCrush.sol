//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract bankProject1 {
    struct accounts {
        string name;
        uint256 accountBalance;
        address accountAddress;
        bool AccountStatus;
    }

    uint256 public totalAmountInBank;
    mapping(address => accounts) public differentAccounts;

    // Events for logging
    event AccountCreated(address indexed user, string name);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event AccountClosed(address indexed user);

    // Modifier to check if account exists and is active
    modifier accountExists() {
        require(differentAccounts[msg.sender].AccountStatus, "Account does not exist or is closed");
        _;
    }

    // Modifier to check if recipient account exists
    modifier recipientExists(address _recipient) {
        require(differentAccounts[_recipient].AccountStatus, "Recipient account does not exist or is closed");
        _;
    }

    // 1. Create account
    function createAccount(string memory _name) public {
        require(!differentAccounts[msg.sender].AccountStatus, "Account already exists");
        
        differentAccounts[msg.sender] = accounts({
            name: _name,
            accountBalance: 0,
            accountAddress: msg.sender,
            AccountStatus: true
        });
        
        emit AccountCreated(msg.sender, _name);
    }

    // 2. Deposit money
    function userDeposit() public payable accountExists {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        differentAccounts[msg.sender].accountBalance += msg.value;
        totalAmountInBank += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }

    // 3. Withdraw money (CEI Pattern applied)
    function userWithdraw(uint256 _amount) public accountExists {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(differentAccounts[msg.sender].accountBalance >= _amount, "Insufficient balance");
        
        // CHECK - already done with requires
        
        // EFFECT
        differentAccounts[msg.sender].accountBalance -= _amount;
        totalAmountInBank -= _amount;
        
        // INTERACTION
        (bool isWithdrawn, ) = payable(msg.sender).call{value: _amount}("");
        require(isWithdrawn, "Withdrawal failed");
        
        emit Withdrawn(msg.sender, _amount);
    }

    // 4. Transfer to another account
    function transfer(address _recipient, uint256 _amount) public 
        accountExists 
        recipientExists(_recipient) 
    {
        require(_amount > 0, "Transfer amount must be greater than 0");
        require(differentAccounts[msg.sender].accountBalance >= _amount, "Insufficient balance");
        require(msg.sender != _recipient, "Cannot transfer to yourself");
        
        // EFFECT
        differentAccounts[msg.sender].accountBalance -= _amount;
        differentAccounts[_recipient].accountBalance += _amount;
        
        emit Transferred(msg.sender, _recipient, _amount);
    }

    // 5. Close account
    function closeAccount() public accountExists {
        uint256 remainingBalance = differentAccounts[msg.sender].accountBalance;
        
        // Transfer any remaining balance back to user
        if (remainingBalance > 0) {
            differentAccounts[msg.sender].accountBalance = 0;
            totalAmountInBank -= remainingBalance;
            
            (bool sent, ) = payable(msg.sender).call{value: remainingBalance}("");
            require(sent, "Failed to return remaining balance");
        }
        
        // Deactivate account
        differentAccounts[msg.sender].AccountStatus = false;
        
        emit AccountClosed(msg.sender);
    }

    // Helper: Get account balance
    function getBalance() public view accountExists returns (uint256) {
        return differentAccounts[msg.sender].accountBalance;
    }

    // Helper: Check if account exists
    function accountExists(address _user) public view returns (bool) {
        return differentAccounts[_user].AccountStatus;
    }
}