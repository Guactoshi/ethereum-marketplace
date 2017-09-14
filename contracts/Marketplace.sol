pragma solidity 0.4.15;

contract Marketplace {
    // the owner of the marketplace
    address public owner;

    // we use this to assign IDs to the different vendors
    uint public currentId = 1;

    // whether the entire marketplace is halted
    bool public marketHalted;

    struct Vendor {
        uint id;
        string name;
        address owner;
        bool halted;
        uint balance;
    }

    struct Listing {
        uint id;
        uint vendorId;
        string name;
        uint qty;
        uint price;
        uint blockExpiration;
        bool halted;
    }

    struct Order {
        uint id;
        uint listingId;
        uint purchasePrice;
        address customer;
        bytes32 ipfsInstructionHash;
        uint blockAutoRelease;
        OrderState state;
        bool fundsReleased;
    }

    mapping(uint => Vendor) public vendors;
    mapping(uint => Listing) public listings;
    mapping(uint => Order) public orders;

    enum OrderState {
        placed, shipped, received, reported
    }

    event LogNewVendor(string indexed name, address indexed benefactor);
    event LogNewListing(string indexed name, uint indexed vendorId);
    event LogNewOrder(uint indexed vendorId, uint indexed listingId, address customer);
    event LogOrderStateChange(uint indexed orderId, OrderState indexed newState);
    event LogVendorWithdraw(uint indexed vendorId, uint indexed amount);

    modifier marketNotHalted() {
        require(!marketHalted);
        _;
    }

    modifier vendorNotHalted(uint vendorId) {
        require(!vendors[vendorId].halted);
        _;
    }

    modifier listingNotHalted(uint listingId) {
        require(!listings[listingId].halted);
        _;
    }

    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    function Marketplace() {
        owner = msg.sender;
    }

    function toggleHalted(uint id) ownerOnly() {
        if (id == 0) {
            marketHalted = !marketHalted;
        } else if (vendors[id].id == id) {
            vendors[id].halted = !vendors[id].halted;
        } else if (listings[id].id == id) {
            listings[id].halted = !listings[id].halted;
        }
    }

    function registerVendor(string name) 
        marketNotHalted() 
    {
        uint id = currentId++;
        vendors[id] = Vendor({
            id: id,
            name: name,
            owner: msg.sender,
            halted: false,
            balance: 0
        });
        LogNewVendor(name, msg.sender);
    }

    function createListing(uint vendorId, string name, uint initialQty, uint price, uint numBlocks)
        marketNotHalted()
        vendorNotHalted(vendorId)
     {
        // only the vendor can list an item on behalf of the vendor
        require(msg.sender == vendors[vendorId].owner);

        uint id = currentId++;
        listings[id] = Listing({
            id: id,
            vendorId: vendorId,
            name: name,
            qty: initialQty,
            price: price,
            blockExpiration: numBlocks+block.number,
            halted: false
        });

        LogNewListing(name, vendorId);
    }

    function placeOrder(uint listingId, bytes32 ipfsInstructionHash)
        listingNotHalted(listingId) 
        vendorNotHalted(listings[listingId].vendorId)
        marketNotHalted()
        payable
    {
        Listing storage listing = listings[listingId];
        require(listing.id > 0);
        require(listing.qty > 0);
        require(listing.blockExpiration > block.number);
        require(listing.price == msg.value);

        // one of them was sold
        listing.qty--;

        uint id = currentId++;
        orders[id] = Order({
            id: id,
            listingId: listingId,
            customer: msg.sender,
            purchasePrice: listing.price,
            ipfsInstructionHash: ipfsInstructionHash,
            blockAutoRelease: block.number + (14 days / 15),
            state: OrderState.placed,
            fundsReleased: false
        });

        LogNewOrder(listing.vendorId, listing.id, msg.sender);
    }

    // indicate that the order was shipped
    function markOrderShipped(uint orderId) {
        require(vendors[listings[orders[orderId].listingId].vendorId].owner == msg.sender);
        orders[orderId].state = OrderState.shipped;
        LogOrderStateChange(orderId, OrderState.shipped);
    }

    // indicate that the order was received and give the vendor the balance
    function markOrderReceived(uint orderId) {
        // the customer has to mark it received, or the order has to be ready for automatic release
        // once ready, anyone can release the funds to the vendor to mark the order received
        require(
            orders[orderId].customer == msg.sender || 
            orders[orderId].blockAutoRelease > block.number
        );
        orders[orderId].state = OrderState.received;
        
        if (!orders[orderId].fundsReleased) {
            orders[orderId].fundsReleased = true;
            vendors[listings[orders[orderId].listingId].vendorId].balance += orders[orderId].purchasePrice;
        }

        LogOrderStateChange(orderId, orders[orderId].state);
    }

    // put the order in a state such that it cannot be withdrawn after the block autorelease date
    function reportOrder(uint orderId) {
        require(orders[orderId].customer == msg.sender);
        orders[orderId].state = OrderState.reported;
        LogOrderStateChange(orderId, OrderState.reported);
    }

    function withdrawBalance(uint vendorId, uint amount)
        marketNotHalted()
        vendorNotHalted(vendorId)
    {
        require(vendors[vendorId].owner == msg.sender);
        require(amount <= vendors[vendorId].balance);

        vendors[vendorId].balance -= amount;
        vendors[vendorId].owner.transfer(amount);
        LogVendorWithdraw(vendorId, amount);
    }
}