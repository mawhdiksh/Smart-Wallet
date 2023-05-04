//SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 < 0.9.0;

contract SmartWallet {
    // Contract owner.
    address payable public owner;

    // Funds that users deposits into this smart contract.
    mapping(address => uint) public pendingDeposit;
    // Giving an user(account) access to how much funds they can spend.
    mapping(address => uint) public isAllowed;

    // Set an account to be guarsian of the wallet.
    mapping(address => bool) isGuardian;
    // Is guardian already voted or no.
    mapping(address => mapping(address => bool)) isGuardianVoted;
    // `newOwner` votes.
    mapping(address => uint) countProposes;

    // New owner and new owner confirmations need to become an owner.
    address payable newOwner;
    uint constant confirmationForSetNewOwner = 3;
    
    /// Set the `owner` to `msg.sender`.
    constructor() {
        owner = payable(msg.sender);
    }
    
    /// The allowed user(account) will be able to spend funds on
    /// EAOs and Contract Account as much as
    /// the contract owner has allowed.
    function allowence(address _for, uint _amount) external {
        // Only the owner can give allowence and call this function.
        require(msg.sender == owner, "Only owner can give allowence!");

        // Set the allowence.
        isAllowed[_for] = _amount;
    }

    /// Owner will set guardians for the wallet.
    /// Guardians can propose new owner and if
    /// new owner gets >3 guardian votes of all
    /// guardians(wallet have 5 guardians), 
    /// it will become to the owner of wallet.
    function setGuardin(address _for, bool _isGuardian) external {
        // Only the owner can set or remove a guardian.
        require(msg.sender == owner, "You're not the owner!");

        // set or remove a guardian with `ture` or `false` keywords.
        isGuardian[_for] = _isGuardian;
    }

    /// The guardians of wallet can propose
    /// new owner to become the owner of wallet.
    /// Number of votes for a new owner should be
    /// >=3 to become to the owner of wallet.
    function proposeNewOwner(address payable _newOwner) public {
        // Only guardians of wallet can propose new owner.
        require(isGuardian[msg.sender], "You're not guardian of this wallet!");
        // Each guardian can only vote ones.
        require(!isGuardianVoted[msg.sender][_newOwner], "You voted before!");

        if(_newOwner != newOwner) {
            newOwner = _newOwner;
            countProposes[_newOwner] = 0;
        }

        // Guatdian have voted and it cannot vote again.
        isGuardianVoted[msg.sender][_newOwner] = true;
        // Count the new owner's votes.
        countProposes[_newOwner]++;

        // If a `newOwner` has enough vote, it will become to the owner of the wallet.
        if(countProposes[_newOwner] >= confirmationForSetNewOwner) {
            owner = _newOwner;
            // Empty the `newOwner` for next proposes owner.
            newOwner = payable(address(0));
        }
    }

    /// Any user(account) that have allowence, can transfer money
    /// and spend funds on EAOs and Contract Accounts.
    function transfer(address payable _to, uint _amount) public {
        // Users deposits should be grater than or equal to `_amount`.
        require(pendingDeposit[msg.sender] >= _amount, "The entry amount is less than your deposit!");
        // Anyone who has allowence can transfer.
        require(isAllowed[msg.sender] >= _amount, "You cannot spend more than you're allowed!");

        // Minuse amount of transfering from users totall deposits and transfer the amount.
        pendingDeposit[msg.sender] -= _amount;
        _to.transfer(_amount);

        // Minuse amount of transfering from users allowence.
        isAllowed[msg.sender] -= _amount;
    }
    
    // Receive function for receiving ether.
    receive() external payable {
        // Mapp how much ether each user has deposited.
        pendingDeposit[msg.sender] += msg.value;
    }
}

contract consumer {
    receive() external payable {}
}
