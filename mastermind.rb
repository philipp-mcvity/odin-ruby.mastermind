#!/usr/bin/env ruby
# frozen_string_literal: true

# input handler
module Input
  def user_input(regex, prompt)
    prompt.call
    input = gets.chomp
    until input.match(regex)
      print "\n> INVALID: please "
      prompt.call
      input = gets.chomp
    end
    input
  end

  def input_instruction
    print "You guess the secret code!

The usual rules apply, besides these notes:
  > The 'colors' are replaced by the letters A - F.
  > Instead of _blank_ as optional 7th color, you can opt-in the letter G.
  > Allow dublicates in the secret code if you feel like it.
  > Choose between 8 and 12 tries to figure out the secret code.
  > Hints:
    +: a correct letter is guessed, but in the wrong position (= white peg)
    $: a correct letter is guessued in the correct position (= black peg)
  Enjoy!\n\n"
  end
end

module CPUPlay
  include Input

  def cpuplay_instruction
    print "You are the Codemaker!

The usual rules apply, besides these notes:
  > The 'colors' are replaced by the letters A - F.
  > Respond to each guess the computer will make with:
    +   for a correct letter, but in the wrong position
    *   for a correct letter in the correct position
    e. g. '*+' or '****' or '+**' or '' (just enter)

The Computer starts guessing, please respond accordingly!\n"
  end

  def print_guess(guess)
    print "
    ...how about   #{guess[0]} #{guess[1]} #{guess[2]} #{guess[3]}   ?\n\n"
  end

  def get_response
    user_input(/^[+*]{0,4}$/, response).to_i
  end


end

# a top-level description
class Mastermind
  include Input, CPUPlay
  attr_reader :role, :code, :variant, :rounds, :guess, :round_count
  attr_accessor :cpu_guess, :response

  def initialize
    @role = user_input(/^[12]$/, creator).to_i
    puts
    if role == 1
      input_instruction
      @variant = user_input(/^[1234]$/, variants).to_i
      puts
      @rounds = user_input(/^[89]$|^1[012]$/, rounds_to_guess).to_i
      @round_count = 0
      @guess = %w[? ? ? ?]
      new_game
    else
      @variant = 1
      @rounds = 12
      cpu_guess = new_code
      cpuplay_instruction
      print_guess(cpu_guess)
      cpu_play
    end
  end

  def cpu_play
    response = get_response
    print "\n- no further development here for now -

Restart the game as the Codebreaker if you feel like it.\n"
    if user_input(/^[yn]$/, restart) == 'y'
      print "\n\n*** NEW GAME ***\n\n"
      initialize
    end
  end

  def new_game
    new_code
    print "\n***** OK, let's play! *****\n"
    draw_board
    play
  end

  def play
    round_count_add
    print "ROUND #{round_count} of #{rounds}:\n"
    guess_get
    draw_board(evaluate)
    next_event
  end

  def draw_board(evaluation = %w[. . . .])
    print "\n[ #{guess[0]} #{guess[1]} #{guess[2]} #{guess[3]} ]\
   >   #{evaluation.join}\n".center(30)
    puts
  end

  def next_event
    game_over = round_count == rounds
    victory = evaluate.count('$') == 4
    print "YOU LOST. No more attempts left :(\n\n" if game_over
    print "VICTORY!!! You found the secret code: #{code.join} :)\n\n" if victory
    case game_over || victory
    when true
      if user_input(/^[yn]$/, restart) == 'y'
        print "\n\n*** NEW GAME ***\n\n"
        initialize
      end
    else play
    end
  end

  def evaluate
    black = 0
    white = 0
    ('A'..(71 - variant % 2).chr).each do |e|
      next if code.count(e).zero? || guess.count(e).zero?

      matches = 0
      guess.each_with_index do |ge, gi|
        next unless e == ge

        matches += 1 if code[gi] == guess[gi]
      end
      white += %W[#{code.count(e)} #{guess.count(e)}].min.to_i - matches
      black += matches
    end
    eva_ary(black, white)
  end

  def eva_ary(black, white)
    evaluate_arry = []
    black.times { evaluate_arry << '$' }
    white.times { evaluate_arry << '+' }
    (4 - black - white).times { evaluate_arry << '.' }
    evaluate_arry
  end

  # procs, regexp & infos
  def creator
    @creator = proc do
      print "choose whether you want to guess or create the code
  1 - guess
  2 - create
> role: "
    end
  end

  def variants
    @variants = proc do
      print "choose variant
  1 - standard
  2 - standard + additional color 'G'
  3 - allow dublicates
  4 - allow dublicates + additional color 'G'
> variant: "
    end
  end

  def rounds_to_guess
    @rounds_to_guess = proc do
      print 'choose available rounds to guess, between 8 and 12
> rounds: '
    end
  end

  def guess_pattern
    @guess_pattern = proc do
      print "enter your guess, four characters \
between A and #{variant.even? ? 'G' : 'F'}
> guess: "
    end
  end

  def response
    respond = proc do
      print "enter your response (+, * or leave empty, zero to 4 digits)
> resonse: "
    end
  end

  def restart
    @restart = proc do
      print "choose if you want to play again
  y - yes
  n - no
> decide: "
    end
  end

  def regex_guess
    return /^[ABCDEFabcdef]{4}$/ if variant.odd?
    return /^[ABCDEFGabcdefg]{4}$/ if variant.even?
  end

  private

  def new_code
    arry = []
    until arry.length == 4 do
      arry << rand(65..71 - variant % 2).chr
      arry.uniq! if variant < 3
    end
    @code = arry
  end

  def guess_get
    @guess = user_input(regex_guess, guess_pattern).upcase.split('')
  end

  def round_count_add
    @round_count += 1
  end
end

print "\nWelcome to MASTERMIND RUBY!\n\n"

Mastermind.new
