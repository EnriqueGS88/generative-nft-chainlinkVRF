// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    // Variables to call requestRandomness() at VRFConsumeBase.sol
    bytes32 public keyHash;
    uint256 public fee;

    // Variables for the standard ERC721
    uint256 public tokenCounter;
    uint256 public requestCounter;
    uint256 public price;
    address payable public owner;

    // Variables to create SVG code
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathsCommands;
    uint256 public size;
    //uint256 public vrfRandomNumber;
    string[] public pathCommands;
    string[] public colors;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;
    // Extension: mapping require to let people mint their own NFT
    mapping(uint256 => address) public tokenIdToNftOwner;

    event RequestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId);
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the contract owner");
        _;
    }
    //https://docs.chain.link/docs/get-a-random-number/
constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint256 _fee) 

    VRFConsumerBase( _VRFCoordinator, _LinkToken)
    ERC721("RandomSVG","rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;
        tokenCounter = 0;
        requestCounter = 0;
        price = 10000000000000000; // 0.01 ETH
        owner = payable(msg.sender);
        //vrfRandomNumber = 1;

        maxNumberOfPaths = 10;
        maxNumberOfPathsCommands = 5;
        size = 500;
        pathCommands = ["L"];
        colors = [
            "blue",
            "red",
            "green",
            "yellow",
            "black",
            "white",
            "darkmagenta",
            "darkred",
            "indigo",
            "gold",
            "brown",
            "chocolate",
            "crimson",
            "cadetblue",
            "darkblue",
            "violet",
            "magenta",
            "slategrey"
            ];

    }
        /* Step by Step
        // 1) get a random number https://docs.chain.link/docs/get-a-random-number/
        // 2) use random number to gen random SVG code
        // 3) base64 to encode SVG code
        // 4) get tokenURI and mint NFT
        */

    function create() public payable returns(bytes32 requestId) {
        // This sets the minimum price at 0.01 ETH to mint the NFT
        require(msg.value == price, "Need to send more ETH");
        // main piece to get a Random number
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        requestCounter = requestCounter +1;
        emit RequestedRandomSVG(requestId, tokenId);


    }


    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        // there is a caveat: Chainlink VRF has max gas = 200,000 gwei
        // Solution: computation to be done by this Contract, Chainlink node only to deliver random number
        // address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];

        // Store the randomNumber provided by Chainlink VRF
        //vrfRandomNumber = randomNumber;
        
        // we can't call generateRandomSVG->this would be too expensive
        // instead we'll store the randomNumber in a variable
        // and then later we'll send another tx using that variable

        //randomNumber = randomNumber % 9999;
        tokenIdToRandomNumber[tokenId] = randomNumber;
        

        for(uint256 i = 1; i < 4; i++) {
            tokenIdToRandomNumber[tokenId + i] = uint256(keccak256(abi.encode(randomNumber, i)));
        }
        

        /*
        for(uint256 i = 1; i < 10; i++) {
            tokenIdToRandomNumber[tokenId + i] = randomNumber + i;
        }
        */



    }



    // This function uses the randomNumber previously stored to then generate a random SVG
    function finishMint(uint256 _tokenId) public {
        // tokenIds and randomNumber from Mappings
        // Then mint a token for the nftOwner
        address nftOwner = msg.sender;
        uint256 tokenId = _tokenId;
        tokenIdToNftOwner[_tokenId] = msg.sender;

        _safeMint(nftOwner, tokenId);
        tokenCounter = tokenCounter +1;

        // [] check to see if it's been minted and a random number is returned
        // [] generate some random SVG code
        // [] turn that into an image URI
        // [] use that imageURI to format into tokenURI

        // check if that tokenURI has already been assigned  
        // require(bytes(tokenURI(_tokenId)).length ==0, "TokenURI has already all set!");
        // check if the tokenId has been really minted
        // require(tokenCounter > _tokenId, "TokenId has not been minted yet");
        // Checking if a random number has already been provided by Chainlink VRF
        // require(tokenIdToRandomNumber[_tokenId] > 0, "Need to wait for ChainlinkVRF response");
        // retrieve the tokenId to set the random number
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];

        // standard process generate SVG => create an image URI => save it as token URI
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, tokenURI);
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
        emit CreatedRandomSVG(_tokenId, svg);
    }

    // This function was copied from previous SVGNFT.sol Contract
    function formatTokenURI(string memory _imageURI) public pure returns (string memory)
    {

        // this will give us the format, but it is not what we need
        // string memory json = string(abi.encodePacked('{"name":"SVG NFT", "description":"An NFT based on SVG!", "attributes": "", "image": " ', imageURI,'"}'));

        string memory baseURL = "data:application/json;base64,";
        return string(abi.encodePacked(
        // below is what we need to format - use single '' to let Solidity concatenates them
            baseURL,    
            Base64.encode(
                bytes(abi.encodePacked(
                    '{"name": "SVG NFT", ',
                    '"description":"An NFT based on SVG!", ',
                    '"attributes":"", ',
                    '"image":"', _imageURI, '"}'
                )
            ))));

        // function formatTokenURI should return something like below:
        // data:application/json;base64

    }

        // This function got copied from previous SVGNFT.sol Contract
        function svgToImageURI(string memory _svg) public pure returns (string memory) {
        // Input here the code that generates the SVG
        // <svg xmlns="http://www.w3.org./2000/svg" height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" /></svg>
        // it has to have the following prefix:
        // data:image/svg+xml;base64,<Base64-encoding/>
        string memory baseURL = "data:image/svg+xml;base64,";

        // Pass the SVG code into "svg"
        // But you have to pack it in Abi -> then convert it to string, bytes and then again run Base64 from library
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(_svg))));

        // This is the way to concatenate strings in Solidity
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;

    }

    function generateSVG(uint256 _randomNumber) public view returns (string memory finalSvg) {
        // pass the random number through a mod of the max number of paths
        uint256 numberOfPaths = (_randomNumber % maxNumberOfPaths) + 1;

        // concatenate strings to generate the SVG code
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='",uint2str(size),"' width='", uint2str(size),"'>"));
        for(uint i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));

    }

    function generatePath(uint256 _randomNumber) public view returns( string memory
    pathSvg) {
        uint256 numberOfPathCommands = (_randomNumber % maxNumberOfPathsCommands ) + 1;
        pathSvg = "<path d='M";
        string memory pathL;
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            // Create a new Random Number
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size + i)));
            string memory pathCommand = generatePathCommand(newRNG);
            // Fix this pathCommand below - it is repeating too much
            pathL = string(
                abi.encodePacked( 
                    pathCommand,
                    " ") 
                );
        }
        // Parameters to set the origin pixel coordinate on the SVG
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size * 2))) % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size * 5))) % size;
        string memory color = colors[_randomNumber % colors.length];
        pathSvg = string(
            abi.encodePacked(
                pathSvg,
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo),
                " ",
                pathL,
                "' fill='transparent' stroke='",
                color,
                "'/>")
            );
    }

    function generatePathCommand(uint256 _randomNumber) public view returns (string
    memory pathCommand) {
        // pathCommand = pathCommands[_randomNumber % pathCommands.length];
        pathCommand = "L";
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size * 2))) % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size * 3))) % size;
        pathCommand = string(
            abi.encodePacked(
                pathCommand, uint2str(parameterOne)," ", uint2str(parameterTwo)
                )
            );
    }



    // function to convert uint256 to String
    // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity/65707309#65707309
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}