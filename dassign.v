/* For my internal state, X is 1, O is 0 */

// reset signal starts the game. As long as the reset = 1'b1, the game is in reset

// Each occ_pos signal is 1'b0 to indicate unoccupied, 1'b1 to indicate
// occupied by X, and flashing 1'b1 at a rate of ½ flash_clk ~to indicate
// occupied by O~

// 8 signals, game_st[7:0] (an ASCII character), to indicate the state of the
// game. 'X' to indicate the winner is X's player, 'O' to indicate the winner
// is O's player, 'C' to indicate a tie ('Cats-Game'), and 'E' to indicate an
// error. ~All 0s to indicate game is still going~
  // An error is detected if a player tries to place and X or O on an occupied
  // square, tries to place more than 1 X or O at a time, or if an X or O is
  // being played during the other player's turn.

//TODO we can be more clever with our state scheme later
`define GAME_ST_START 4'd0
`define GAME_ST_TURN_X 4'd1
`define GAME_ST_ERR_X 4'd2
`define GAME_ST_CHECK_X 4'd3
`define GAME_ST_WIN_X 4'd4
`define GAME_ST_TURN_O 4'd5
`define GAME_ST_ERR_O 4'd6
`define GAME_ST_CHECK_O 4'd7
`define GAME_ST_WIN_O 4'd8
`define GAME_ST_CATS 4'd9
module game(turnX, turnO, occ_pos, game_st, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
  output turnX, turn0;
  output occ_pos[8:0];
  output game_st[7:0];

  input reset, clk, flash_clk;
  input sel_pos[8:0];
  input buttonX, buttonO;

  wire occ_square[8:0];
  wire occ_player[8:0];
  /**************************** begin game logic *****************************/
  /* asynchronous resets */
  always @ (posedge clk, negedge reset) begin
    if (reset) begin
      occ_square <= 0;
      occ_player <= 0;
      game_state <= `GAME_ST_START;
    else begin
      if (game_state == `GAME_ST_START) begin
      end else if (game_state == `GAME_ST_TURN_X) begin
      end else if (game_state == `GAME_ST_TURN_O) begin
      end else if (game_state == `GAME_ST_ERR_X) begin
      end else if (game_state == `GAME_ST_ERR_O) begin
      end else if (game_state == `GAME_ST_CHECK_X) begin
      end else if (game_state == `GAME_ST_CHECK_O) begin
      end else if (game_state == `GAME_ST_WIN_X) begin
      end else if (game_state == `GAME_ST_WIN_O) begin
      end else if (game_state == `GAME_ST_CATS) begin
    end
  end

  wire result[1:0];
  check_win checker (result, occ_square, occ_player);

endmodule


/* A move is valid if it is player X's turn and an X is placed in an
 * unoccupied square. Or if it is player O's turn and an O is placed in an
 * unoccupied square.
 */
module move_validity();
  output valid;

  input cur_game_st[???]; //who's turn is it?
  input buttonX, buttonO; //who tried to make a move?
  input occ_square[8:0]; //this the half of our state where it's occupied or not, not about X or O
  input sel_pos[8:0]; //where is the move going?


endmodule

/* 3 in a row means a winner.
 * No winner with 9 occupied spaces means cat's game.
 * No winner with less than 9 occupied spaces means the game is still going
 */
/* First bit being high ==> there's a winner. If there's a winner, second bit
 * says who */
`define WIN_ST_NONE 2'd0
`define WIN_ST_CATS 2'd1
`define WIN_ST_WIN0 2'd2
`define WIN_ST_WINX 2'd3
module check_win(result, occ_square, occ_player);
  output result[1:0]; //output state
  input occ_square[8:0]; //is there an X or O here?
  input occ_player[8:0]; //if so, which one is it.

  /* The grid looks like this:
   * 8 | 7 | 6
   * --|---|---
   * 5 | 4 | 3
   * --|---|---
   * 2 | 1 | 0
   */

  /* Winning combinations (treys):
   * 852, 741, 630, 876, 543, 210, 840, 642
   * Check for a victory in each trey
   */
  wire trey_winner[7:0];
  wire trey_player[7:0];
  check_trey col0 (trey_winner[0], trey_player[0], {occ_square[8], occ_square[5], occ_square[2]}, {occ_player[8], occ_player[5], occ_player[2]});
  check_trey col1 (trey_winner[1], trey_player[1], {occ_square[7], occ_square[4], occ_square[1]}, {occ_player[7], occ_player[4], occ_player[1]});
  check_trey col2 (trey_winner[2], trey_player[2], {occ_square[6], occ_square[3], occ_square[0]}, {occ_player[6], occ_player[3], occ_player[0]});
  check_trey row0 (trey_winner[3], trey_player[3], {occ_square[8], occ_square[7], occ_square[6]}, {occ_player[8], occ_player[7], occ_player[6]});
  check_trey row1 (trey_winner[4], trey_player[4], {occ_square[5], occ_square[4], occ_square[3]}, {occ_player[5], occ_player[4], occ_player[3]});
  check_trey row2 (trey_winner[5], trey_player[5], {occ_square[2], occ_square[1], occ_square[0]}, {occ_player[2], occ_player[1], occ_player[0]});
  check_trey dag0 (trey_winner[6], trey_player[6], {occ_square[8], occ_square[4], occ_square[0]}, {occ_player[8], occ_player[4], occ_player[0]});
  check_trey dag1 (trey_winner[7], trey_player[7], {occ_square[6], occ_square[4], occ_square[2]}, {occ_player[6], occ_player[4], occ_player[2]});

  assign wire isWinner = (& trey_winner);
  assign wire winningPlayer = (| trey_player);

  always @(*) begin
    if (isWinner) begin
      result = {isWinner, winningPlayer};
    end else if (& occ_square) begin
      result = `WIN_ST_CATS;
    end else begin
      result = `WIN_ST_NONE;
    end
  end
endmodule

/* checks 3 inline squares (row/column/diagonal) (a.k.a. a "trey") to see if
 * a victory has been scored across them */
module check_trey(win, player, occ_square, occ_player);
  output win; //was there a winner in this trey?
  output player; //who won?
  input occ_square[2:0]; // is there an X or an O in this spot
  input occ_player[2:0]; // if so, which one is it

  /* Is the same player in all squares of this trey? */
  //assign samePlayer = (occ_player[0] == occ_player[1]) & (occ_player[0] == occ_player[2]);
  assign samePlayer = (& occ_player) == (| occ_player);

  /* If so, and all the squares are occupied (meaning the occ_player data isn't
   * garbage), then that means someone won */
  assign win = samePlayer & (& occ_square);
  /* filter the player output s.t. ORing them all together will give the
   * winning player (default 'player' to 0, unless there was a winner. Then
   * let it have it's true value */
  assign player = win & occ_player[0];
endmodule
/********************************** plan ***********************************/
/*
 * (1) a state machine that determines behavior of each LED ~???~
 * (2) logic that checks a move for validity
 *   * Driver between internal state and ASCII representation
 */
