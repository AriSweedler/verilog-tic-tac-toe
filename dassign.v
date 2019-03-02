/* For my internal state, X is 1, O is 0 */

// reset signal starts the game. As long as the reset = 1'b1, the game is in reset

// Each occ_pos signal is 1'b0 to indicate unoccupied, 1'b1 to indicate
// occupied by X, and flashing 1'b1 at a rate of ½ flash_clk ~to indicate
// occupied by O~

// 8 signals, game_st[7:0] (an ASCII character), to indicate the state of the
// game. 'X' to indicate the winner is X's player, 'O' to indicate the winner
// is O's player, 'C' to indicate a tie ('Cats-Game'), and 'E' to indicate an
// error.
  // An error is detected if a player tries to place and X or O on an occupied
  // square, tries to place more than 1 X or O at a time, or if an X or O is
  // being played during the other player's turn.
module game(turnX, turnO, occ_pos, game_st, reset, clk, flash_clk, sel_pos, buttonX, buttonO);
  output turnX, turn0;
  output occ_pos[8:0];
  output game_st[7:0];

  input reset, clk, flash_clk;
  input sel_pos[8:0];
  input buttonX, buttonO;

  /**************************** begin game logic *****************************/
  //TODO 2x9 array (occupied, if so by which player)

endmodule


/* A move is valid if it is player X's turn and an X is placed in an
 * unoccupied square. Or if it is player O's turn and an O is placed in an
 * unoccupied square.
 */
module move_validity();
  output valid;

  input cur_game_st[???]; //who's turn is it?
  input buttonX, buttonO; //who tried to make a move?
  input occ_pos[8:0]; //this the half of our state where it's occupied or not, not about X or O
  input sel_pos[8:0]; //where is the move going?


endmodule

/* 3 in a row means a winner.
 * No winner with 9 occupied spaces means cat's game.
 * No winner with less than 9 occupied spaces means the game is still going
 */
/* First bit being high ==> there's a winner. If there's a winner, second bit
 * says who */
`DEFINE ST_NONE 2'd0
`DEFINE ST_CATS 2'd1
`DEFINE ST_WIN0 2'd2
`DEFINE ST_WINX 2'd3
module check_win();
  output result[1:0]; //output state
  input occ_pos[8:0]; //is there an X or O here?
  input occ_player[8:0]; //if so, which one is it.

  /* The grid looks like this:
   * 8 | 7 | 6
   * --|---|---
   * 5 | 4 | 3
   * --|---|---
   * 2 | 1 | 0
   */

  /* Winning combinations:
   * 852, 741, 630, 876, 543, 210, 840, 642
   */
  wire trey_winner[7:0];
  wire trey_player[7:0];
  check_trey col0 (trey_winner[0], trey_player[0], {occ_pos[8], occ_pos[5], occ_pos[2]}, {occ_player[8], occ_player[5], occ_player[2]});
  check_trey col1 (trey_winner[1], trey_player[1], {occ_pos[7], occ_pos[4], occ_pos[1]}, {occ_player[7], occ_player[4], occ_player[1]});
  check_trey col2 (trey_winner[2], trey_player[2], {occ_pos[6], occ_pos[3], occ_pos[0]}, {occ_player[6], occ_player[3], occ_player[0]});
  check_trey row0 (trey_winner[3], trey_player[3], {occ_pos[8], occ_pos[7], occ_pos[6]}, {occ_player[8], occ_player[7], occ_player[6]});
  check_trey row1 (trey_winner[4], trey_player[4], {occ_pos[5], occ_pos[4], occ_pos[3]}, {occ_player[5], occ_player[4], occ_player[3]});
  check_trey row2 (trey_winner[5], trey_player[5], {occ_pos[2], occ_pos[1], occ_pos[0]}, {occ_player[2], occ_player[1], occ_player[0]});
  check_trey dag0 (trey_winner[6], trey_player[6], {occ_pos[8], occ_pos[4], occ_pos[0]}, {occ_player[8], occ_player[4], occ_player[0]});
  check_trey dag1 (trey_winner[7], trey_player[7], {occ_pos[6], occ_pos[4], occ_pos[2]}, {occ_player[6], occ_player[4], occ_player[2]});

  assign wire isWinner = (& trey_winner);
  assign wire winningPlayer = (| trey_player);

  always @(*) begin
    if (isWinner) begin
      result = {isWinner, winningPlayer};
    end else if (& occ_pos) begin
      result = `ST_CATS;
    end else begin
      result = `ST_NONE;
    end
  end
endmodule

/* checks 3 inline squares (row/column/diagonal) (a.k.a. a "trey") to see if
 * a victory has been scored across them */
module check_trey(win, player, occ_square, occ_XorO);
  output win; //was there a winner in this trey?
  output player; //who won?
  input occ_square[2:0]; // is there an X or an O in this spot
  input occ_XorO[2:0]; // if so, which one is it

  /* Is the same player in all squares of this trey? */
  assign samePlayer = (occ_XorO[0] == occ_XorO[1]) & (occ_XorO[0] == occ_XorO[2]);

  /* If so, and all the squares are occupied (meaning the occ_XorO data isn't
   * garbage), then that means someone won */
  assign win = samePlayer & (& occ_square);
  /* filter the player output s.t. ORing them all together will give the
   * winning player (default 'player' to 0, unless there was a winner. Then
   * let it have it's true value */
  assign player = win & occ_XorO[0];
endmodule
/********************************** plan ***********************************/
/*
 * (1) a state machine that determines behavior of each LED ~???~
 * (2) logic that checks a move for validity
 *   * Driver between internal state and ASCII representation
 * (3) logic that checks a Win or Cats-Game.
 */
