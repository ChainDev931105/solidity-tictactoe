// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Tictactoe {
    enum Winner {
        None,
        PlayerOne,
        PlayerTwo,
        Draw
    }

    enum Player {
        None,
        PlayerOne,
        PlayerTwo
    }

    struct Game {
        address playerOne; // creator
        address playerTwo; // joiner
        Player turn;
        Winner winner;
        Player[3][3] board;
        uint256 emptyCells;
    }

    mapping (uint256 => Game) public games;
    uint256 private counter;

    constructor() public {
    }

    modifier isValidGame(uint256 _id) {
        require(games[_id].playerOne != address(0), "Invalid game");
        _;
    }

    function createGame() external {
        counter++;
        Game memory game;
        game.playerOne = msg.sender;

        games[counter] = game;

        emit GameCreated(counter, msg.sender);
    }
    
    function joinGame(uint256 _id) external isValidGame(_id) {
        Game storage game = games[_id];
        require(game.playerTwo == address(0), "Already matched game");
        
        game.playerTwo = msg.sender;

        bool isCreatorFirstMove = _calcFirstPlayer(game.playerOne, game.playerTwo);
        game.turn = isCreatorFirstMove ? Player.PlayerOne : Player.PlayerTwo;
        game.emptyCells = 9;
        
        emit GameJoined(_id, msg.sender, isCreatorFirstMove);
    }

    function makeMove(uint256 _id, uint _x, uint _y) external isValidGame(_id) {
        Game storage game = games[_id];
        Player turn = Player.None;
        if (game.turn == Player.PlayerOne && game.playerOne == msg.sender) {
            turn = game.turn;
        }
        else if (game.turn == Player.PlayerTwo && game.playerTwo == msg.sender) {
            turn = game.turn;
        }
        require(turn != Player.None, "Invalid Turn");
        require(_x < 3 && _y < 3 && game.board[_x][_y] == Player.None, "Invalid cell");

        game.board[_x][_y] = turn;
        game.emptyCells = game.emptyCells - 1;

        emit MoveMade(_id, msg.sender, _x, _y);

        bool win = false;

        if (game.board[0][_y] == game.board[1][_y] && game.board[1][_y] == game.board[2][_y]) win = true;
        else if (game.board[_x][0] == game.board[_x][1] && game.board[_x][1] == game.board[_x][2]) win = true;
        else if ((_x + _y) == 2 && game.board[2][0] == game.board[1][1] && game.board[1][1] == game.board[0][2]) win = true;
        else if (_x == _y && game.board[0][0] == game.board[1][1] && game.board[1][1] == game.board[2][2]) win = true;

        if (win) {
            game.winner = turn == Player.PlayerOne ? Winner.PlayerOne : Winner.PlayerTwo;
            game.turn = Player.None;
            emit GameFinished(_id, turn == Player.PlayerOne ? game.playerOne : game.playerTwo);
        }
        else if (game.emptyCells == 0) {
            game.winner = Winner.Draw;
            game.turn = Player.None;
            emit GameFinished(_id, address(0));
        }
        else {
            game.turn = turn == Player.PlayerOne ? Player.PlayerTwo : Player.PlayerOne;
        }
    }

    function getBoard(uint256 _id) public view isValidGame(_id) returns (uint256[3][3] memory board) {
        Game storage game = games[_id];
        for (uint i = 0; i < 3; i++) {
            for (uint j = 0; j < 3; j++) {
                board[i][j] = uint256(game.board[i][j]);
            }
        }
    }

    function _calcFirstPlayer(address playerOne, address playerTwo) private pure returns (bool) {
        uint256 x = uint256(keccak256(abi.encodePacked(playerOne, playerTwo)));
        uint256 y = (x >> 255);
        return y == 0;
    }

    event GameCreated(uint256 id, address creator);
    event GameJoined(uint256 id, address joiner, bool isCreatorFirstMove);
    event MoveMade(uint256 id, address player, uint x, uint y);
    event GameFinished(uint256 id, address winner);
}
