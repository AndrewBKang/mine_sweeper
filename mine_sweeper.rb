require 'debugger'
class Board
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
      (-1..1).each do |m|
        next if n == 0 && m == 0
        x,y = coord[0] + n, coord[1] + m
        results << [x,y] if (0..@size - 1).to_a.include?(x) && (0..@size - 1).to_a.include?(y)
      end
    end
    results
  end

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

  def board_display
    display_board = []
    @size.times do |n|
      row = []
      @size.times do |m|
        row << ''
      end
      display_board << row
    end
    board_hash.keys.each do |key|
      x = key[0]
      y = key[1]
      display_board[x][y] = @board_hash[key].to_s
    end
    display_board
  end
end

class Minesweeper

  def initialize
    @player = Player.new
  end

  def play
    print_screen
    input = gets.to_i
    input == 1 ? @size = 9 : @size = 16
    unless input == 3
      @board = Board.new(input).board_hash
      print "   0  1  2  3  4  5  6  7  8" if @size == 9
      print "   0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15" if @size == 16
      print "\n"
      i = 0
      initial_display_board.each do |line|
        i < 10 ? print("#{i}  ") : print("#{i} ")
        print line.join("  ")
        print "\n"
        i += 1
      end
      until win? || lose?
        run
      end
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
    puts "Input coordinates and move (eg: 1,2 r)"
    coord_and_move = @player.move
    new_board = change_display_board(coord_and_move[0],coord_and_move[1])
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
    x = start_coord[0]
    y = start_coord[1]

    # bomb or number
    if check == 'b' || check.to_i == check
      @display_board[x][y] = check

    # empty
    else
      @display_board[x][y] = check
      arr = [start_coord]
      visited = []

      until arr.empty?
        current_coord = arr.shift
        next if visited.include? current_coord

        adj_coords(current_coord).each do |adj_coord|
          x = adj_coord[0]
          y = adj_coord[1]
          next unless @display_board[x][y] == '*'
          arr << adj_coord if @board[adj_coord] == '_'
          @display_board[x][y] = @board[adj_coord]
        end
        visited << current_coord
      end

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

end

class Player


  def move
    coord_and_choice = gets.split(" ")
    coord = coord_and_choice[0].split(",").map { |s| s.to_i }
    choice = coord_and_choice[1]
    [coord, choice]
  end


end