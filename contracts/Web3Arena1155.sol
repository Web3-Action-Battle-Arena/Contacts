// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Arena1155 is ERC1155, ERC1155Burnable, ERC1155Pausable, Ownable {
    constructor() ERC1155("https://api.web3arena.com/api/v1/nft/{id}") {}

    // free mint credits for winning games
    mapping(address => uint256) public mintCredits;

    struct Game {
        uint256 gameId;
        address creator;
        bool waitingForPlayers;
        address challenger;
        uint256[] playersTokens;
        address winner;
        bool finished;
        uint256 createdAt;
        bool player1ResultSubmitted;
        address player1Winner;
        bool player2ResultSubmitted;
        address player2Winner;
    }
    // store active and completed games
    mapping(uint256 => Game) public games;

    // lock wallet address to prevent multiple games
    mapping(address => bool) public lockedWallets;

    // Armor types
    uint256 public constant HEAD = 0;
    uint256 public constant CHEST = 1;
    uint256 public constant LEGS = 2;
    uint256 public constant WEAPON = 3;

    // Armor rarity
    uint256 public constant COMMON = 0;
    uint256 public constant RARE = 1;
    uint256 public constant EPIC = 2;
    uint256 public constant LEGENDARY = 3;

    // Armor stats
    uint256 public constant ATTACK = 0;
    uint256 public constant DEFENSE = 1;
    uint256 public constant SPEED = 2;
    uint256 public constant HEALTH = 3;

    // Armor stats values
    uint256 public constant COMMON_ATTACK = 1;
    uint256 public constant COMMON_DEFENSE = 1;
    uint256 public constant COMMON_SPEED = 1;
    uint256 public constant COMMON_HEALTH = 1;

    uint256 public constant RARE_ATTACK = 2;
    uint256 public constant RARE_DEFENSE = 2;
    uint256 public constant RARE_SPEED = 2;
    uint256 public constant RARE_HEALTH = 2;

    uint256 public constant EPIC_ATTACK = 3;
    uint256 public constant EPIC_DEFENSE = 3;
    uint256 public constant EPIC_SPEED = 3;
    uint256 public constant EPIC_HEALTH = 3;

    uint256 public constant LEGENDARY_ATTACK = 4;
    uint256 public constant LEGENDARY_DEFENSE = 4;
    uint256 public constant LEGENDARY_SPEED = 4;
    uint256 public constant LEGENDARY_HEALTH = 4;

    // mint a commont set for a fixed price

    function mintCommonSet(address _to) public payable {
        require(msg.value == 10 ether, "Not enough ETH");
        _mint(_to, HEAD, 1, "");
        _mint(_to, CHEST, 1, "");
        _mint(_to, LEGS, 1, "");
        _mint(_to, WEAPON, 1, "");
    }

    // generate a pseudo random item with random rarity

    function randomItem(uint256 _seed) public view returns (uint256) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(block.timestamp, _seed))
        );
        uint256 itemType = rand % 4;
        uint256 itemRarity = rand % 4;
        return itemType + itemRarity * 4;
    }

    // mint a random item for a fixed price or using mint credits

    function mintRandomItem(address _to, uint256 _seed) public payable {
        require(msg.value == 1 ether || mintCredits[_to] > 0, "Not enough ETH");
        if (mintCredits[_to] > 0) {
            mintCredits[_to] -= 1;
        }
        _mint(_to, randomItem(_seed), 1, "");
    }

    // create game which takes users tokens and locks them during the game

    function createGame(uint256[] memory _tokens) public {
        require(!lockedWallets[msg.sender], "Wallet is locked");
        require(_tokens.length == 4, "Invalid tokens");
        uint256 gameId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        games[gameId] = Game({
            gameId: gameId,
            creator: msg.sender,
            waitingForPlayers: true,
            challenger: address(0),
            playersTokens: _tokens,
            winner: address(0),
            finished: false,
            createdAt: block.timestamp,
            player1ResultSubmitted: false,
            player1Winner: address(0),
            player2ResultSubmitted: false,
            player2Winner: address(0)
        });
        lockedWallets[msg.sender] = true;
    }

    // join an existing game which takes users tokens and locks them during the game

    function joinGame() public payable {
        require(msg.value == 1 ether, "Not enough ETH");
        require(!lockedWallets[msg.sender], "Wallet is locked");
        require(
            balanceOf(msg.sender, HEAD) >= 1 &&
                balanceOf(msg.sender, CHEST) >= 1 &&
                balanceOf(msg.sender, LEGS) >= 1 &&
                balanceOf(msg.sender, WEAPON) >= 1,
            "Not enough tokens"
        );
        uint256 gameId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        require(games[gameId].waitingForPlayers, "Game not found");
        lockedWallets[msg.sender] = true;
        games[gameId].challenger = msg.sender;
        games[gameId].waitingForPlayers = false;
    }

    // resolve game which takes the winner and loser and distributes the tokens to the winner and burns the losers tokens, can only resolve if both players have submitted their results or 1 day has passed has passed from a single submission
    // if no submission has been made the game is cancelled and tokens are returned to the players

    function resolveGame(uint256 gameId) public {
        require(games[gameId].finished, "Game not finished");
        require(
            games[gameId].player1ResultSubmitted &&
                games[gameId].player2ResultSubmitted,
            "Both players must submit results"
        );
        require(
            games[gameId].player1Winner == games[gameId].creator ||
                games[gameId].player2Winner == games[gameId].creator,
            "You are not the winner"
        );
        require(
            games[gameId].player1Winner == games[gameId].challenger ||
                games[gameId].player2Winner == games[gameId].challenger,
            "You are not the winner"
        );
        if (games[gameId].player1Winner == games[gameId].creator) {
            _safeBatchTransferFrom(
                games[gameId].creator,
                games[gameId].challenger,
                games[gameId].playersTokens,
                new uint256[](4),
                ""
            );
        } else {
            _safeBatchTransferFrom(
                games[gameId].challenger,
                games[gameId].creator,
                games[gameId].playersTokens,
                new uint256[](4),
                ""
            );
        }
        lockedWallets[games[gameId].creator] = false;
        lockedWallets[games[gameId].challenger] = false;
        _burnBatch(
            games[gameId].creator,
            games[gameId].playersTokens,
            new uint256[](4)
        );
        _burnBatch(
            games[gameId].challenger,
            games[gameId].playersTokens,
            new uint256[](4)
        );
    }

    // player 1 result submission, true if won, false if lost

    function player1ResultSubmission(bool _result, uint256 gameId) public {
        require(games[gameId].creator == msg.sender, "You are not the creator");
        require(
            !games[gameId].player1ResultSubmitted,
            "Result already submitted"
        );
        games[gameId].player1ResultSubmitted = true;
        if (_result) {
            games[gameId].player1Winner = games[gameId].creator;
        } else {
            games[gameId].player1Winner = games[gameId].challenger;
        }
        if (games[gameId].player2ResultSubmitted) {
            games[gameId].finished = true;
        }
    }

    // player 2 result submission, true if won, false if lost

    function player2ResultSubmission(bool _result, uint256 gameId) public {
        require(!games[gameId].finished, "Game is finished");
        require(
            games[gameId].challenger == msg.sender,
            "Only challenger can submit result"
        );
        require(
            !games[gameId].player2ResultSubmitted,
            "Result already submitted"
        );
        games[gameId].player2ResultSubmitted = true;
        if (_result) {
            games[gameId].player2Winner = msg.sender;
        } else {
            games[gameId].player2Winner = games[gameId].creator;
        }
        if (games[gameId].player1ResultSubmitted) {
            resolveGame(gameId);
        }
    }

    // cancel game unlocks back the tokens

    function cancelGame(uint256 _gameId) public {
        require(
            games[_gameId].creator == msg.sender ||
                games[_gameId].challenger == msg.sender,
            "Not your game"
        );
        require(
            games[_gameId].createdAt + 1 days < block.timestamp,
            "Game not finished"
        );
        require(!games[_gameId].finished, "Game already finished");
        _safeBatchTransferFrom(
            games[_gameId].creator,
            msg.sender,
            games[_gameId].playersTokens,
            new uint256[](4),
            ""
        );
        _safeBatchTransferFrom(
            games[_gameId].challenger,
            msg.sender,
            games[_gameId].playersTokens,
            new uint256[](4),
            ""
        );
        lockedWallets[games[_gameId].creator] = false;
        lockedWallets[games[_gameId].challenger] = false;
        games[_gameId].finished = true;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
