//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Aliens is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;

    bool public revealed = false;
    bool public isMintEnabled = false;
    string public baseTokenUri;
    string public hiddenTokenUri;
    uint256 public totalSupply;
    uint256 public constant MAX_POPULATION = 5000;
    uint256 public maxMintPerWallet = 20;
    uint256 public cost = 0.01 ether;

// ? when I call numInWallet this returns zero? why?
    mapping(address => uint256) public numInWallet;

    constructor() ERC721('Aliens', 'ALN') {}

//* Minting Functions
    function mint(uint256 num) public payable nonReentrant {
        require(num > 0, "You must mint at least 1 NFT");
        require (isMintEnabled, 'Minting not enabled');
        require(totalSupply + num <= MAX_POPULATION, 'Sold out');
        require(msg.value == num * cost, 'Wrong ether value');
        require(numInWallet[msg.sender] + num <= maxMintPerWallet, 'Exceeds max per wallet');

        for(uint256 i = 0; i < num; i++) {
            totalSupply++;
            uint256 tokenId = totalSupply;
            _safeMint(msg.sender, tokenId);
        }
    }

// function to Enable the Mint Function, only the owner and deployer can enable this
    function setIsMintEnabled(bool isMintEnabled_) external onlyOwner {
        isMintEnabled = isMintEnabled_;
    }
// Adjust the cost of the mint
    function setCost(uint256 cost_) external onlyOwner {
    cost = cost_;
    }

//* URI Functions *//
// Setting the URI for images, only the owner can set this.
    function setBaseTokenUri(string memory baseTokenUri_) public onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
// Setting the URI for Hidden image, only the owner can set this.
     function setNotRevealedURI(string calldata hiddenTokenUri_) public onlyOwner {
        hiddenTokenUri = hiddenTokenUri_;
     }
// Sets a boolean for the collection images to be revealed
      function setRevealed(bool revealed_) public onlyOwner {
        revealed = revealed_;
     }

   function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

// This is the function that opensea calls to grab the images. This function displays the images on opensea
// and connects the tokenUri, Id, and json extension
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), 'token does not exist!');
        if(revealed == false) {
            return hiddenTokenUri;
         }  return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), '.json'));
    }

//* Withdrawal Functions (2) *//
// The withdraw function, for only owner, this allows us to withdraw the funds to the withdraw wallet we specified
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, 'Withdrawal of funds failed');
    }

// ? is this function safe?
// Enable non-eth withdrawals
    function withdrawTokens(IERC20 token) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
    }
}