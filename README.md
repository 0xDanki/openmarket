# OpenMarket dApp
OpenMarket is a decentralized marketplace that allows public market vendors and wholesalers to buy directly from local farmers. The local farmers can list their harvest to expedite the process of finding a buyer for their produce.

## Libraries

Initializable
Reentrancy Guard

## State Variables

1. Item struct
2. Order struct
3. Farmer struct
4. farmers mapping
5. items mapping
6. Orders per user mapping
7. Private variables for counters

## Modifiers

1. onlyOwner
2. onlyFarmer

## Functions

1. addFarmer - Registers a farmer. Only farmers can list an item
2. list - creates a new Item and adds it to the items mapping. Only farmers can call this function
3. buy (payable) - buy an item. Open to external addresses. Fetches an item, creates an order, add this order to the user, subtracts from item stock, pays the seller.
	- require that msg.value is greater than cost of item
	- require that item is in stock
4. deleteItem - delists an item so it can no longer be bought. Only the seller of the item can call this function.

## Unit Test Coverage (as of Feb 10, 2023)

Deployment <br>
    ✔ Sets the owner<br>
Farmer Registration<br>
    ✔ Returns farmer attributes<br>
    ✔ Emits FarmerRegistered event<br>
Listing<br>
    ✔ Returns item attributes<br>
    ✔ Emits List event<br>
Buying<br>
    ✔ Updates buyer's order count<br>
    ✔ Adds the order<br>
    ✔ Updates buyer and seller balances<br>
    ✔ Emits Buy event<br>
