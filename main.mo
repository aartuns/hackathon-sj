import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

actor Marketplace {
  // Product structure
  public type Product = {
    id : Nat;
    name : Text;
    description : Text;
    price : Nat;
    seller : Principal;
    createdAt : Int;
    isActive : Bool
  };


  // Error types
  public type MarketplaceError = {
    #ProductNotFound;
    #InsufficientFunds;
    #Unauthorized;
    #ProductInactive;
    #InvalidProduct
  };

  private var nextProductId : Nat = 1;
  private var products = HashMap.HashMap<Nat, Product>(10, Nat.equal, Hash.hash);


  // Helper function to generate test principal
  private func generateTestPrincipal() : Principal {
    Principal.fromText("2vxsx-fae")
  };

  // Add a new product
  public shared (msg) func addProduct(name : Text, description : Text, price : Nat) : async Result.Result<Nat, MarketplaceError> {
    if (Text.size(name) == 0 or Text.size(description) == 0) {
      return #err(#InvalidProduct)
    };

    if (price == 0) {
      return #err(#InvalidProduct)
    };

    let newProduct : Product = {
      id = nextProductId;
      name = name;
      description = description;
      price = price;
      seller = msg.caller;
      createdAt = Time.now();
      isActive = true
    };

    products.put(nextProductId, newProduct);
    let productId = nextProductId;
    nextProductId += 1;
    #ok(productId)
  };

  // Get all products
  public query func getAllProducts() : async [Product] {
    let productBuffer = Buffer.Buffer<Product>(0);
    for ((id, product) in products.entries()) {
      productBuffer.add(product)
    };
    Buffer.toArray(productBuffer)
  };

  // Update product
  public shared (msg) func updateProduct(productId : Nat, name : Text, description : Text, price : Nat) : async Result.Result<(), MarketplaceError> {
    switch (products.get(productId)) {
      case (null) {
        return #err(#ProductNotFound)
      };
      case (?existingProduct) {
        if (Principal.notEqual(existingProduct.seller, msg.caller)) {
          return #err(#Unauthorized)
        };

        if (Text.size(name) == 0 or Text.size(description) == 0 or price == 0) {
          return #err(#InvalidProduct)
        };

        let updatedProduct : Product = {
          id = productId;
          name = name;
          description = description;
          price = price;
          seller = existingProduct.seller;
          createdAt = existingProduct.createdAt;
          isActive = existingProduct.isActive
        };

        products.put(productId, updatedProduct);
        #ok()
      }
    }
  };

  // Toggle product status
  public shared (msg) func toggleProductStatus(productId : Nat) : async Result.Result<(), MarketplaceError> {
    switch (products.get(productId)) {
      case (null) {
        return #err(#ProductNotFound)
      };
      case (?existingProduct) {
        if (Principal.notEqual(existingProduct.seller, msg.caller)) {
          return #err(#Unauthorized)
        };

        let updatedProduct : Product = {
          id = existingProduct.id;
          name = existingProduct.name;
          description = existingProduct.description;
          price = existingProduct.price;
          seller = existingProduct.seller;
          createdAt = existingProduct.createdAt;
          isActive = not existingProduct.isActive
        };

        products.put(productId, updatedProduct);
        #ok()
      }
    }
  };



  // Get products by seller
  public query func getProductsBySeller(seller : Principal) : async [Product] {
    let sellerProducts = Buffer.Buffer<Product>(0);
    for (product in products.vals()) {
      if (Principal.equal(product.seller, seller)) {
        sellerProducts.add(product)
      }
    };
    Buffer.toArray(sellerProducts)
  };



  // Add test product (helper function for testing)
  public func addTestProduct() : async Result.Result<Nat, MarketplaceError> {
    await addProduct("Test Product", "This is a test product", 100)
  }
};
