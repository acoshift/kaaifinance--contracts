//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract KaaiMaiKub is Ownable, ReentrancyGuard {
    event NewFile(address indexed sender, uint256 id);
    event SetFileActive(uint256 indexed id, bool active);
    event SetFileDownloadFee(uint256 indexed id, uint256 fee);
    event PayFile(address indexed sender, uint256 id);

    address public receiver; // platform's fee receiver wallet
    address public signer; // api signer

    struct File {
        address sender;
        uint256 maxSize;
        uint256 uploadFee;
        uint256 downloadFee;
        bool active;
        uint256 paidCount;
    }

    uint256 public total; // total files
    mapping (uint256 => File) public files;
    mapping (uint256 => mapping (address => bool)) public paidFiles;
    uint256 public constant FEE = 10; // 10%
    uint256 public constant MIN_DOWNLOAD_FEE = 0.1 ether;

    constructor(
        address _receiver,
        address _signer
    ) {
        setReceiver(_receiver);
        setSigner(_signer);
    }

    function setReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0), "!wow");
        receiver = _receiver;
    }

    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "!wow");
        signer = _signer;
    }

    function newFile(
        uint256 maxSize,
        uint256 downloadFee,
        uint256 deadline,
        bytes memory signature
    ) external payable nonReentrant returns (uint256) {
        require(maxSize > 0, "!size");
        require(downloadFee >= MIN_DOWNLOAD_FEE, "!dfee");
        require(block.timestamp <= deadline, "!deadline");

        bytes32 h = hashNewFile(msg.sender, maxSize, msg.value, deadline);
        require(SignatureChecker.isValidSignatureNow(signer, h, signature), "!sig");

        total++;
        uint256 id = total;
        files[id] = File(
            msg.sender,
            maxSize,
            msg.value,
            downloadFee,
            true,
            0
        );
        emit NewFile(msg.sender, id);

        payable(receiver).transfer(msg.value);

        return id;
    }

    function hashNewFile(
        address sender,
        uint256 maxSize,
        uint256 fee,
        uint256 deadline
    ) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(
            sender,
            maxSize,
            fee,
            deadline
        )));
    }

    modifier onlyFileOwner(uint256 id) {
        require(files[id].sender == msg.sender, "!own");
        _;
    }

    function setFileActive(uint256 id, bool active) external onlyFileOwner(id) {
        File storage file = files[id];
        file.active = active;
        emit SetFileActive(id, active);
    }

    function setFileDownloadFee(uint256 id, uint256 fee) external onlyFileOwner(id) {
        require(fee >= MIN_DOWNLOAD_FEE, "!dfee");
        File storage file = files[id];
        file.downloadFee = fee;
        emit SetFileDownloadFee(id, fee);
    }

    function payFile(uint256 id) external payable nonReentrant {
        require(!paidFiles[id][msg.sender], "paid");

        File storage file = files[id];
        require(msg.value == file.downloadFee, "!fee");
        paidFiles[id][msg.sender] = true;
        file.paidCount++;

        uint256 platformFee = (FEE * msg.value) / 100;
        payable(receiver).transfer(platformFee);
        payable(file.sender).transfer(msg.value - platformFee);

        emit PayFile(msg.sender, id);
    }
}
