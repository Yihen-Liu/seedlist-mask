//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";
import "./Owned.sol";

contract RandomMask is ERC721URIStorage,Owned{
    uint constant  MAX_GENESIS_MASK_NFT=21000;
    uint256 public tokenCounter;

    // SVG parameters
    uint256 public maxNumberofPaths;
    uint256 public maxNumberofPathCommands;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;
    string[] public fill;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event CreateUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor() ERC721 ("Seedlist CryptoMask", "GenesisMask") {
            tokenCounter = 0;
            maxNumberofPaths= 10;
            maxNumberofPathCommands=4;
            size=500;
            pathCommands = ["M","L","S","q"];
            colors = ["red","blue","green","black","silver","plum","papayawhip","midnightblue","firebrick"];
            fill = ["transparent","false"];
    }

/*
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {

        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        // generateRandomSVG
        tokenIdToRandomNumber[tokenId]= randomNumber;
        emit CreateUnfinishedRandomSVG(tokenId, randomNumber);
    }

*/
    function mintRandomMask(bytes32 requestId, uint256 randomNum) mintable external {
        require(requestIdToSender[requestId]==address(0), "Request id has exist");
        require(tokenCounter<MAX_GENESIS_MASK_NFT, "Genesis mask nft has been minted over.");
        requestIdToSender[requestId]=tx.origin;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter = tokenCounter + 1 ;

        _safeMint(tx.origin, tokenId);

        string memory svg = finishMint(tokenId, randomNum);
        emit CreatedRandomSVG(tokenId,svg);
    }

    function finishMint (uint _tokenId, uint256 randomNum) mintable internal returns (string memory svg){
        //generate some random SVG code
        // turn that into an image URI 
        // use that imageURI to format into a tokenURI
        // check to see if it's been minted and a random number is returned
        require(bytes(tokenURI(_tokenId)).length <=0,"tokenURI is alread all set !");
        require(tokenCounter>_tokenId, "TokenId has not been minted yet!");
        //require(tokenIdToRandomNumber[_tokenId]>0, "Need to wait for chainlink VRF");
        //uint256 randomNumber = bytes32ToUint256(randomNum);
        svg = generateSVG(randomNum);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, tokenURI);
        //return svg;
    }

    function generateSVG (uint256 _randomNumber) public view returns (string memory finalSvg) {
        uint256 numberOfPaths = (_randomNumber % maxNumberofPaths) + 1;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='", uint2str(size), "' width='", uint2str(size), "'>"));
        for(uint i = 0; i < numberOfPaths; i++){
            uint newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));

        }
        finalSvg = string(abi.encodePacked(finalSvg,"</svg>"));
    }

    function generatePath(uint256 _randomNumber) public view returns (string memory pathSvg){
        uint256 numberOfPathCommands = (_randomNumber % maxNumberofPathCommands) +1;
        pathSvg = "<path d='";
        for(uint i = 0; i< numberOfPathCommands; i++){
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size+i)));
            string memory pathCommand = generatePathCommand(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg,pathCommand));
        }
        for(uint j = 0; j< numberOfPathCommands; j++){
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size+j)));
            string memory pathCommand = generateNextPathCommand(_randomNumber);(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg,pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        string memory fills = fill[_randomNumber % fill.length];
        if (compareStrings(fills, "transparent")) {
        pathSvg = string(abi.encodePacked(pathSvg, "' fill='transparent' stroke='",color,"'/>"));
        }
        else {
            pathSvg = string(abi.encodePacked(pathSvg, "' stroke='",color,"'/>"));
        }
    }

    function generatePathCommand(uint256 _randomNumber) public view returns (string memory pathCommand){
        pathCommand = pathCommands [_randomNumber % pathCommands.length];
        if (compareStrings(pathCommand, "M") || compareStrings(pathCommand, "L")) {
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size *2)))
        % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size *3)))
        % size;
        pathCommand = string(abi.encodePacked(pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo)," "));}
        else if (compareStrings(pathCommand, "S") || compareStrings(pathCommand, "q")) {
            pathCommand = "M";
            uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size *2)))
            % size;
            uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size *3)))
            % size;
            pathCommand = string(abi.encodePacked(pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo)," "));
        }
    }

    function generateNextPathCommand(uint256 _randomNumber) public view returns (string memory pathCommand){
        pathCommand = pathCommands [_randomNumber % pathCommands.length];
        if (compareStrings(pathCommand, "q") || compareStrings(pathCommand, "S")) {
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size *2)))
        % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size *3)))
        % size;
        uint256 parameterThree = uint256(keccak256(abi.encode(_randomNumber, size *4)))
        % size;
        uint256 parameterFour = uint256(keccak256(abi.encode(_randomNumber, size *5)))
        % size;  
        pathCommand = string(abi.encodePacked(" ",pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo), " ", uint2str(parameterThree), " ", uint2str(parameterFour)));  
        }
        else if (compareStrings(pathCommand, "M") || compareStrings(pathCommand, "L")) {
            pathCommand = "S";
            uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size *2)))
        % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size *3)))
        % size;
        uint256 parameterThree = uint256(keccak256(abi.encode(_randomNumber, size *4)))
        % size;
        uint256 parameterFour = uint256(keccak256(abi.encode(_randomNumber, size *5)))
        % size;  
        pathCommand = string(abi.encodePacked(" ",pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo), " ", uint2str(parameterThree), " ", uint2str(parameterFour)));  
        
        }
    }
    // Function to compare strings : 
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    // Function to convert Uint256 to string : 
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

    function bytes32ToUint256(bytes32 x) public pure returns (uint256) {
        uint256 y;
        for (uint8 i = 0; i < 32; i++) {
            uint256 c = (uint256(x) >> (i * 8)) & 0xff;
            if (48 <= c && c <= 57)
                y += (c - 48) * 10 ** i;
            else if (65 <= c && c <= 90)
                y += (c - 65 + 10) * 10 ** i;
            else if (97 <= c && c <= 122)
                y += (c - 97 + 10) * 10 ** i;
            else break;
        }
        return y;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        //<svg xmlns="http://www.w3.org/2000/svg" height="210" width="400"><path d="M150 0 L75 200 L225 200 Z" /></svg>
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;
    }

    function formatTokenURI(string memory imageURI) public pure returns (string memory){
      string memory baseURL = "data:application/json;base64,";
      return string (abi.encodePacked(
          baseURL,
          Base64.encode(
            bytes(abi.encodePacked(
              '{"name": "SVG NFT", ',
              '"description": "An NFT based on SVG!", ',
              '"attributes": "", ',
              '"image": "', imageURI, '"}'
          )
          ))
          ));  
    }




}