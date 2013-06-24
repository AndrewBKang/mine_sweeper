require 'yaml'

#To play, run:
#load 'mine_sweeper.rb'
#game = Minesweeper.new
#game.play


class Board
  # REV: maybe get rid of size instance variable. 
  # => might be easier to create the board with the right 
  # => size and use that to find boundaries later.
  # => Too many instance vars can be a bit overwhelming at times
  def initialize(input)
    @size = 9 if input == 1
    @size = 16 if input == 2
    board_coord
    @bomb_coord = bomb_coord
    @fringe_hash = fringe_hash
    @empty_coord = empty_coord
    @board_hash = board_hash
    @board_hash
  end

  def board_coord
    @board_coord = []
    @size.times do |n|
      @size.times do |m|
        @board_coord << [n,m]
      end
    end
    @board_coord
  end

  # REV: Perhaps it could be good to allow different amount of bomb coords
  # => maybe with a class var or some input to instantiate that
  # => can be passed to this method
  # => could be nice to just set @bomb coord in here
  # => instead of setting it equal to the value of this
  def bomb_coord
    bomb_coord = []
    until bomb_coord.length == @size + 1
      x, y = (0..@size - 1).to_a.shuffle.first, (0..@size - 1).to_a.shuffle.first
      pos_coord = [x,y]
      bomb_coord << pos_coord unless bomb_coord.include? pos_coord
    end
    bomb_coord
  end

  def fringes(coord)
    results = []
    (-1..1).each do |n|
      # REV: might be nice to split this out to make 
      # => it easier to understand
      (-1..1).each do |m|
        next if n == 0 && m == 0
        x,y = coord[0] + n, coord[1] + m
        results << [x,y] if (0..@size - 1).to_a.include?(x) && (0..@size - 1).to_a.include?(y)
      end
    end
    results
  end

  # REV: interesting take on setting the numbers!
  # => I like this strategy of setting them relative to the 
  # => bombs instead of the moves like me and my pair did.
  def fringe_hash
    all_fringes = []
    @bomb_coord.each do |coord|
      all_fringes += fringes(coord)
    end
    keys = all_fringes.uniq - @bomb_coord
    values = []
    keys.each do |key|
      values << all_fringes.count(key)
    end
    all_fringes_hash = Hash[keys.zip(values)]
  end

  # REV: again, I like the way you kept track of everything
  # => in a way which made the actual move conditions easier
  def empty_coord
    @board_coord - @fringe_hash.keys - @bomb_coord
  end

  def board_hash
    board_hash = {}
    @bomb_coord.each do |coord|
      board_hash[coord] = 'b'
    end
    @empty_coord.each do |coord|
      board_hash[coord] = '_'
    end
    board_hash = board_hash.merge(@fringe_hash)
    board_hash
  end

  def hidden_board_hash
   hidden_board = []
   #REV: maybe put this nested block in a helper method
    @size.times do |n|
      row = []
      @size.times do |m|
        row << ''
      end
     hidden_board << row
    end
    board_hash.keys.each do |key|
      x = key[0]
      y = key[1]
     hidden_board[x][y] = @board_hash[key].to_s
    end
   hidden_board
  end

end

class Minesweeper

  def initialize
    @player = Player.new
  end

  # REV: Might be nice to make a helper method
  def play
    print_screen
    input = gets.to_i
    input == 1 ? @size = 9 : @size = 16
    unless input == 3
      @board_object = Board.new(input)
      @board = @board_object.board_hash
      show_board(initial_display_board)
      until win? || lose? || !run
      end
      puts "saved" if save
      puts "winner!" if win?
      puts "loser!" if lose?
    end
    puts "bye-bye"
  end

  def print_screen
    puts "[1] Beginner"
    puts "[2] Intermediate"
    puts "[3] quit"
  end
  
  def run
    puts "Reveal (r) or Flag (f) or Save (s) or Load (l)"
    move = @player.move
    if move == 's'
      save
      false
    elsif move == 'l'
      load
      show_board(@display_board)
    else
      coord_and_move = move if move.length == 2
      new_board = change_display_board(coord_and_move[0],coord_and_move[1])
      show_board(new_board)
    end
  end

  def show_board(new_board)
    print "   0  1  2  3  4  5  6  7  8" if @size == 9
    print "   0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15" if @size == 16
    print "\n"
    i = 0
    new_board.each do |line|
      i < 10 ? print("#{i}  ") : print("#{i} ")
      print line.join("  ")
      print "\n"
      i += 1
    end
  end

  def initial_display_board
    @display_board = []
    @size.times do |n|
      row = []
      @size.times do |m|
        row << '*'
      end
      @display_board << row
    end
    @display_board
  end
  
  def change_display_board(coord, move)
    x = coord[0]
    y = coord[1]
    if move == 'f'
      if @display_board[x][y] == '*'
        @display_board[x][y] = 'F'
      elsif @display_board[x][y] == 'F'
        @display_board[x][y] = '*'
      end
    elsif move == 'r'
      reveal(coord)
    end
    @display_board
  end

  def reveal(start_coord)
    check = @board[start_coord]
    x,y = start_coord[0], start_coord[1]

    # bomb or number
    if check == 'b' || check.to_i == check
      @display_board[x][y] = check

    # empty
    else
      reveal_adjacents(x,y,check)
    end

  end

  def reveal_adjacents(x, y, check)
    @display_board[x][y] = check
    arr = [[x,y]]
    visited = []

    until arr.empty?
      current_coord = arr.shift
      next if visited.include? current_coord

      adj_coords(current_coord).each do |adj_coord|
        x,y  = adj_coord[0],adj_coord[1]
        next unless @display_board[x][y] == '*'
        arr << adj_coord if @board[adj_coord] == '_'
        @display_board[x][y] = @board[adj_coord]
      end

      visited << current_coord
    end
  end

  def adj_coords(coord)
    results = []
    (-1..1).each do |n|
      (-1..1).each do |m|
        next if n == 0 && m == 0
        x,y = coord[0] + n, coord[1] + m
        results << [x,y] if (0..@size - 1).to_a.include?(x) && (0..@size - 1).to_a.include?(y)
      end
    end
    results
  end

  def win?
    spots_left = @display_board.flatten.count('*') + @display_board.flatten.count('F')
    spots_left == 10 && @size == 9 || spots_left == 40 && @size == 16
  end

  def lose?
    @display_board.flatten.include?("b")
  end

  # REV: Can simplify with File.write(filename, self.to_yaml)
  def save
    File.open('save1.yaml','w'){|f| f << YAML::dump([@board_object, @display_board, @size])}
  end

  # REV: Can simplify with YAML::load_file(filename)
  def load
    object_arrays = YAML::load(File.open('save1.yaml'))
    @board = object_arrays[0].board_hash
    @display_board = object_arrays[1]
    @size = object_arrays[2]
    true
  end


end

class Player
  #REV: I like this short, straightforward class
  # => does exactly what it needs to and nothing more
  def move
    move = gets.chomp
    if move == 'r' || move == 'f'
      puts "Enter coordinates (ex. 1,2)"
      coord1 = gets.chomp
      coord = coord1.split(",").map { |s| s.to_i }
      p [coord, move]
      return [coord, move]
    elsif move == 's'
      's'
    elsif move == 'l'
      'l'
    end

  end

end
