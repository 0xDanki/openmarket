// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Openmarket is Initializable, ReentrancyGuard {
    address public owner;

    //will have to add harvest date and status to this struct sometime later. eg. enum Status {Planted, Harvested, Processed, Warehouse, Transit}
    //will have to add a function to change the listing once the harvest date and status is added to this struct. As for now, we assume that the listing is already harvested and ready to be bought
    struct Listing {        
        uint256 id;
        address payable seller;
        string name;
        string category;
        string image;
        string unit;
        uint256 cost;
        uint256 rating;
        uint256 stock;
    }

    struct Escrow {
        address payable buyer;
        address payable seller;
        uint256 amount;
        bool released;
        bool refunded;
    }

    enum OrderStatus { Placed, Shipped, Delivered, Refunded }

    struct Order {
        uint256 time;
        Listing listing;
        address buyerAddr;
        string phone;
        OrderStatus status;
        bool shipped;
    }

    struct Farmer {
        uint id;
        string name;
        string city;
        string locality;
        bool isRegistered;
    }

    mapping(address => Farmer) public farmers;
    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public orderCount;
    mapping(uint256 => uint256) public escrow; // Order ID to escrowed amount
    mapping(uint256 => Escrow) public escrows;
    uint256 private farmerCount;
    uint256 private listingsCount;


    event FarmerRegistered (uint id, string name, string city, string locality);
    event Buy(address buyer, uint256 orderId, uint256 listingId, address buyerAddr, string phone);
    event List(uint listingId, address seller, string sellerName, string name, string category, uint256 cost, string unit, uint256 stock);
    event Delisted(uint256 listingId, string name);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyFarmer {
         require(farmers[msg.sender].isRegistered == true, "You are not registered.");
        _;
    }

    modifier onlyBuyer(uint256 _orderId) {
        Order storage order = orders[msg.sender][_orderId];
        require(msg.sender == order.buyerAddr, "You are not the buyer of this order");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function addFarmer(string memory _name, string memory _city, string memory _locality) public {
        //Makes sure the required fields are filled out
        require(bytes(_name).length > 0);
        require(bytes(_city).length > 0);
        require(bytes(_locality).length > 0);

        //Increments the farmer count and creates a new Farmer in the mappings with the msg.sender address as its ID
        farmerCount ++;
        farmers[msg.sender]=Farmer(farmerCount, _name, _city, _locality, true);

        emit FarmerRegistered(farmerCount, _name, _city, _locality);
    }    


    //UX consideration: do we really need the farmer to upload an image? If there's a way to display an image based on the listing name in the frontend...
    function list(
        string memory _name,
        string memory _category,
        string memory _image,
        string memory _unit,
        uint256 _cost,
        uint256 _rating,
        uint256 _stock
    ) external onlyFarmer {

        //Increments the listings count and creates a new listing in the mappings with the listingsCount as its ID and msg.sender as its seller
        listingsCount ++;
        address payable _seller = payable(msg.sender);
        listings[listingsCount]=Listing(
            listingsCount, 
            _seller, 
            _name, 
            _category, 
            _image, 
            _unit, 
            _cost, 
            _rating, 
            _stock);

        emit List(listingsCount, _seller, farmers[_seller].name, _name, _category, _cost, _unit, _stock);
    }

    function initiateEscrow(uint256 _orderId, address _buyer, address _seller, uint256 _amount) internal {
        Escrow storage escrowData = escrows[_orderId];
        escrowData.buyer = payable(_buyer); // Explicit typecast to address payable
        escrowData.seller = payable(_seller); // Explicit typecast to address payable
        escrowData.amount = _amount;
        escrowData.released = false;
        escrowData.refunded = false;
    }

    function releaseEscrow(uint256 _orderId) internal onlyFarmer {
        Escrow storage escrowData = escrows[_orderId];
        require(!escrowData.released, "Escrow already released");
        escrowData.released = true;
        payable(escrowData.seller).transfer(escrowData.amount);
    }

    function refundBuyer(uint256 _orderId) internal onlyFarmer {
        Escrow storage escrowData = escrows[_orderId];
        require(!escrowData.released && !escrowData.refunded, "Escrow already released or refunded");
        escrowData.refunded = true;
        payable(escrowData.seller).transfer(escrowData.amount);
    }

    function buy(uint256 _id, address _buyerAddr, string memory _phone) external payable nonReentrant {
        // Fetch listing
        Listing storage listing = listings[_id];

        // Require enough ether to buy listing
        require(msg.value >= listing.cost, "Please submit the asking price in order to complete the order");

        // Require listing is in stock
        require(listing.stock > 0, "Listing is out of stock");

        // Create order
        Order memory order = Order(block.timestamp, listing, _buyerAddr, _phone, OrderStatus.Placed, false);

        // Initiate escrow
        initiateEscrow(orderCount[msg.sender], msg.sender, listing.seller, listing.cost);
       
        // Add order for user
        orderCount[msg.sender]++;
        orders[msg.sender][orderCount[msg.sender]] = order;

       // Emit event
       emit Buy(msg.sender, orderCount[msg.sender], _id, _buyerAddr, _phone);
    }
    
    function markAsShipped(uint256 _orderId) external onlyFarmer {
        Order storage order = orders[msg.sender][_orderId];
        require(order.status == OrderStatus.Placed, "Order must be in exist");
        order.status = OrderStatus.Shipped;
        order.shipped = true;
    }

    function confirmReceipt(uint256 _orderId) external onlyBuyer(_orderId) {
        Order storage order = orders[msg.sender][_orderId];
        require(order.status == OrderStatus.Shipped, "Order must be in 'Shipped' status to confirm receipt");

        // Mark order as delivered
        order.status = OrderStatus.Delivered;

        // Release escrow to the seller
        releaseEscrow(_orderId);
    }

    function deleteListing(uint256 _id) external nonReentrant {

        //Fetch listing
        Listing storage listing = listings[_id];

        //Require that the listing is listed and has stock
        require(listing.stock > 0, "Listing must be on the market");

        //Require that the function caller is the product seller
        require(listing.seller == msg.sender, "You must be the product owner ");

        //sets the listing stock to zero
        listing.stock = 0;
        
        emit Delisted(_id, listing.name);
  }


}
