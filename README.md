# OpenMarket
OpenMarket is a decentralized agricultural marketplace that allows public market vendors and wholesalers to buy directly from local farmers. The local farmers can list their harvest to expedite the process of finding a buyer for their produce.

This documentation provides an overview of the OpenMarket, its features, and the technologies used in its development.

## Table of Contents

- [What Problem We Solve](#what-problem-we-solve)
- [Our Solution](#introduction)
- [Userflow](#userflow)
- [Libraries](#libraries)
- [Future Developments](#future-developments)
- [Dev Guide](#dev-guide)

## What Problem We Solve

There is a huge inefficiency in the country’s agricultural supply chain as we find many consumers willing to buy more produce yet farmers are struggling to get paid a fair price because of too many middlemen. By the time their products reach the market, their price has tripled or even quadrupled from what the farmers had sold them for. 

## Introduction

OpenMarket is a decentralized ecommerce app that allows public market vendors and wholesalers buy directly from local farmers and track the full cycle of their order, from planting to distribution.

Our app will enable farmers to sell directly to wholesalers, get paid a fair price, and conveniently have them delivered to the public market. On the buyer side, people who buy raw crops from Openmarket get to enjoy huge discounts that they may not find elsewhere.

As a side benefit, putting farmers’ produce on a public listing prevents wastage and enables complete traceability of the crops, making it harder to smuggle agricultural products in the country. If implemented widely, it will also enable monitoring of the incoming supply and demand for crops and make coordinated planting (and procuring farm inputs) possible.

## Userflow

We have two main users in OpenMarket, the Farmer and the Buyer. Each has a simple userflow.

Userflow for Farmer:

1. Connects Wallet and Registers as a Farmer
2. Uploads Crops with Estimated Date
3. Accept or Reject an offer
4. Ship the Product
5. Get Paid


Userflow for Buyer:

1. Connects Wallet and Browses for Crops
2. Sends an Offer
3. Escrows the payment when the offer is accepted
4. Receives the crops 


## Technologies Used

OpenMarket uses the following Frameworks, Libraries, and Technology:

**Smart Contract Development**: Hardhat and Solidity, Openzeppelin

**Testing and Deploying**: EthersJS and Mocha Framework

**Frontend**: ReactJS, NextJS, and TailwindCSS

**Backend**: Polybase (A decentralized database)

**Marketplace Currency**: USDC



## Future Development

OpenMarket is an ongoing project, and I will keep adding features and fixes to improve the platform. But the upcoming features are:

* Deployment on AVAX Subnet, a special blockchain meant especially for the smooth running of the dApp
* Putting escrowed payments on yield-bearing vaults
* Integration of Zero-Knowledge (ZK) technology to enhance user privacy
* Improvements on User Interface for better mobile experience
* Implementation of advanced search and filtering capabilities


## Dev Guide

### Libraries

Initializable
Reentrancy Guard
Polybase

### State Variables

1. Item struct
2. Order struct
3. Farmer struct
4. Farmers mapping
5. Items mapping
6. Orders per user mapping
7. Private variables for counters

### Modifiers

1. onlyOwner
2. onlyFarmer

### Functions

1. addFarmer - Registers a farmer. Only farmers can list an item
2. list - creates a new Item and adds it to the items mapping. Only farmers can call this function
3. buy (payable) - buy an item. Open to external addresses. Fetches an item, creates an order, add this order to the user, subtracts from item stock, pays the seller.
	- require that msg.value is greater than cost of item
	- require that item is in stock
4. cancel - cancels an order
5. setShipping - sets and requests shipment fee
6. payShipping - pays the farmer the shipment fee
7. deleteItem - delists an item so it can no longer be bought. Only the seller of the item can call this function.

### Unit Test Coverage (as of Feb 10, 2023)

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