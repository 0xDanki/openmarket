// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Openmarket is Initializable, ReentrancyGuard {
    address public owner;

    //will have to add harvest date and status to this struct sometime later. eg. enum Status {Planted, Harvested, Processed, Warehouse, Transit}
    //will have to add a function to change the listing once the harvest date and status is added to this struct. As for now, we assume that the item is already harvested and ready to be bought
    struct Item {        
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

    struct Order {
        uint256 time;
        Item item;
        string buyerAddr;
        string phone;
    }

    struct Farmer {
        uint id;
        string name;
        string city;
        string barangay;
        bool isRegistered;
    }

    mapping(address => Farmer) public farmers;
    mapping(uint256 => Item) public items;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public orderCount;
    uint256 private farmerCount;
    uint256 private itemsCount;


    event FarmerRegistered (uint id, string name, string city, string barangay);
    event Buy(address buyer, uint256 orderId, uint256 itemId, string buyerAddr, string phone);
    event List(uint itemId, address seller, string sellerName, string name, string category, uint256 cost, string unit, uint256 stock);
    event Delisted(uint256 itemId, string name);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyFarmer {
         require(farmers[msg.sender].isRegistered == true, "You are not registered.");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function addFarmer(string memory _name, string memory _city, string memory _barangay) public {
        //Makes sure the required fields are filled out
        require(bytes(_name).length > 0);
        require(bytes(_city).length > 0);
        require(bytes(_barangay).length > 0);

        //Increments the farmer count and creates a new Farmer in the mappings with the msg.sender address as its ID
        farmerCount ++;
        farmers[msg.sender]=Farmer(farmerCount, _name, _city, _barangay, true);

        emit FarmerRegistered(farmerCount, _name, _city, _barangay);
    }    


    //UX consideration: do we really need the farmer to upload an image? If there's a way to display an image based on the item name in the frontend...
    function list(
        string memory _name,
        string memory _category,
        string memory _image,
        string memory _unit,
        uint256 _cost,
        uint256 _rating,
        uint256 _stock
    ) external onlyFarmer {

        //Increments the items count and creates a new Item in the mappings with the itemsCount as its ID and msg.sender as its seller
        itemsCount ++;
        address payable _seller = payable(msg.sender);
        items[itemsCount]=Item(
            itemsCount, 
            _seller, 
            _name, 
            _category, 
            _image, 
            _unit, 
            _cost, 
            _rating, 
            _stock);

        emit List(itemsCount, _seller, farmers[_seller].name, _name, _category, _cost, _unit, _stock);
    }

    //room for improvement: the msg.value will go first to an escrow instead of going straight to the creator's wallet
    //i'm not sure if putting nonReentrant is useful in an external function, but yeah i'm paranoid like that lol
    function buy(uint256 _id, string memory _buyerAddr, string memory _phone) external payable nonReentrant {
        // Fetch item
        Item storage item = items[_id];

        // Require enough ether to buy item
        require(msg.value >= item.cost, "Please submit the asking price in order to complete the purchase");

        // Require item is in stock
        require(item.stock > 0, "Item is out of stock");

        // Create order
        Order memory order = Order(block.timestamp, item, _buyerAddr, _phone);

        //Transfers fund from buyer to seller
        item.seller.transfer(item.cost);

        // Add order for user
        orderCount[msg.sender]++; // <-- Order ID
        orders[msg.sender][orderCount[msg.sender]] = order;

        // Subtract stock
        item.stock --;

        // Emit event
        emit Buy(msg.sender, orderCount[msg.sender], _id, _buyerAddr, _phone);
    }

    function deleteItem(uint256 _id) external nonReentrant {

        //Fetch item
        Item storage item = items[_id];

        //Require that the item is listed and has stock
        require(item.stock > 0, "Item must be on the market");

        //Require that the function caller is the product seller
        require(item.seller == msg.sender, "You must be the product owner ");

        //sets the item stock to zero
        item.stock = 0;
        
        emit Delisted(_id, item.name);
  }


}
