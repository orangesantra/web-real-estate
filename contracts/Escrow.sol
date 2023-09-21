//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


// STEP-2 -----------------------------------------------------------------------------------------------
// setting up interface to use the tranferFrom function from deployed RealEstate.sol contract.
interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

// STEP-3 ------------------------------------------------------------------------------------------------
// creating the Escrow contract with constructor, to ensure what parameter needed for deployment with Escrow contract. 
contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public lender;

    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
    }

// STEP- 12 ------------------------------------------------------------------------------------------------
    // Creating the onlySeller modifer
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

// STEP- 11 -----------------------------------------------------------------------------
    // Create differnt mappings.
    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approval;

// STEP- 3 --------------------------------------------------------------------------------
    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

// STEP- 9 ------------------------------------------------------------------------------------
    // Modify list parameter as per requirement
// STEP- 12.1 ----------------------------------------------------------------------------------
    // Introduce onlySeller modifier and make the function payable. 
    function list(
        uint256 _nftID,
        address _buyer, // using here buyer parameter is just for understanding, it's not necessary for listing by NFT seller.
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller { // By making function payable we can call or deliver any sendTransaction method while calling this function.

// STEP- 9.1 ---------------------------------------------------------------------------------
    // Transfer NFT from seller to this contract
    // VVVVVVVIMP- The caller of this function in escrow contract
    // In depth this thing is happening -

    // await realEstate.connect(seller).approve(escrow.address, 1)
    // await realestate.connect(escrow).transferFrom(msg.sender, address(this), nftID)

    // THIS THE FINAL CONCEPT.

    // while the caller of list function is msg.sender/ seller in this case.
    IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

// STEP- 11.1 ---------------------------------------------------------------------------------
    // Asign values to different mapping Keys.
    isListed[_nftID] = true;
    purchasePrice[_nftID] = _purchasePrice;
    escrowAmount[_nftID] = _escrowAmount;
    buyer[_nftID] = _buyer;
    }

// STEP- 13 --------------------------------------------------------------------------------------
    // Put Under Contract (only buyer - payable escrow)
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]);
    }

// STEP- 15 --------------------------------------------------------------------------------------   
    // Update Inspection Status (only inspector)
    function updateInspectionStatus(uint256 _nftID, bool _passed)
        public
        onlyInspector
    {
        inspectionPassed[_nftID] = _passed;
    }

// STEP- 16 --------------------------------------------------------------------------------------
    // Approve Sale from different process users.
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

// STEP- 17 --------------------------------------------------------------------------------------
    // Finalize Sale
    // -> Require inspection status (add more items here, like appraisal)
    // -> Require sale to be authorized
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller
    function finalizeSale(uint256 _nftID) public {

// STEP- 18 -------------------------------------------------------------------------------------
        // Checking Requirememnts.
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false;
// STEP- 18.1 ----------------------------------------------------------------------------------
        // Pay the price to seller.
        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);
// STEP- 18.2 ---------------------------------------------------------------------------------
        // Transfer the NFT to buyer.

        // In depth functioning. 
        // await realEstate.connect(seller).approve(escrow.address, 1)
        // await realestate.connect(escrow).transferFrom(address(this), buyer[_nftID], nftID)
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }
// STEP- 19 -----------------------------------------------------------------------------------
    // Cancel Sale (handle earnest deposit)
    // -> if inspection status is not approved, then refund, otherwise send to seller
    function cancelSale(uint256 _nftID) public {
        if (inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance); // .transfer here is inbuilt function in solidity, used fo sending transaction.
            // .call is just advanced version of .transfer.
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
// STEP- 15 -------------------------------------------------------------------------------------------------
    // creating this function helps in recieving the money to contract. we can perform business logic inside it after recieving the amount.
    receive() external payable {}

// STEP- 14 --------------------------------------------------------------------------------------------------
    // Creating the getBalance () function to get the current balance of escrow contract.
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}