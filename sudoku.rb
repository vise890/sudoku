require 'pry'

class SudokuBoard

  def initialize(board)
    raise ArgumentError.new('Invalid input length') if board.length != 81
    @board = board
  end

  # rows are numbered 0..8
  # returns the elements in row r
  def row(r)
    r = r.to_i
    beginning_idx = 9 * r
    ending_idx = 9 * (r + 1) - 1
    @board[beginning_idx..ending_idx]
  end

  # iterates over every row
  def each_row
    (0..8).each do |r|
      yield row(r)
    end
  end

  # columns are numbered 0..8
  # returns the elements in row n
  def column(c)
    c = c.to_i
    column = ''
    each_row do |row|
      column += row[c]
    end
    return column
  end

  # iterates over every column
  def each_column
    (0..8).each do |c|
      yield column(c)
    end
  end
  
  # returns the elements in box
  # for a given row and column
  def box(row, column)

    top_row = (row / 3) * 3
    bottom_row = top_row + 2

    leftmost_column = (column / 3) * 3
    rightmost_column = leftmost_column + 2

    box = ''
    (top_row..bottom_row).each do |row_n|
      box += row(row_n)[leftmost_column..rightmost_column]
    end
    return box

  end

  # iterates over every box
  def each_box
    boxes = [[1,1], [1,4], [1,7], [4,1], [4,4], [4,7], [7,1], [7,4], [7,7]]
    boxes.map! { |coordinates| box(coordinates[0], coordinates[1]) }
    boxes.each do |box|
      yield box
    end
  end
  
  # iterates over every cell
  def each_cell
    @board.split('').each_with_index do |cell, n|
      yield cell, n
    end
  end

  # iterates over every *empty* cell
  def each_empty_cell
    each_cell do |cell, n|
      yield(cell, n) if cell == '0'
    end
  end

  # cells are numbered 0..80
  # returns the coordinates (row,column)
  # for cell n
  def coordinates_for_cell(n)
    raise "Invalid cell index" unless (0..80).include? n
    row = n / 9
    column = n % 9
    return row, column
  end

  # returns the cell index (n) for a given row and column
  def cell_for_coordinates(row, column)
    raise "Invalid row" unless (0..8).include? row
    raise "Invalid column" unless (0..8).include? column
    row * 9 + column
  end

  # returns the box number for a cell with coordinates (row, column)
  def box_for_coordinates(row, column)
    3 * (row / 3) + (column / 3)
  end

  # returns the content of the cell at coordinates (row, column)
  def [](row, column)
    n = cell_for_coordinates(row, column)
    @board[n]
  end

  # replaces the contents of cell at coordinates (row, column)
  # with new_cell_content
  def []=(row, column, new_cell_content)
    unless new_cell_content.to_s.length == 1
      raise "Invalid cell content #{new_cell_content}"
    end
    n = cell_for_coordinates(row, column)
    @board[n] = new_cell_content.to_s
  end

  # returns a string representation of the board
  def to_s
    str = ''
    each_row do |r|
      # substitute blank cells (0) with "_"
      # separate 
      str += r.to_s.gsub('0', '_').to_a.join(" ") + "\n"
    end
    return str
  end

  # checks whether the board contains duplicates
  # and returns true or false accordingly
  def has_duplicates?

    each_row do |row|
      return true unless row.to_a.only_uniq_elements?
    end

    each_column do |column|
      return true unless column.to_a.only_uniq_elements?
    end

    each_box  do |box|
      return true unless box.to_a.only_uniq_elements?
    end

    return false
    
  end

end

class ImpossibleBoard < StandardError
  # raised whenever there's a cell
  # with no feasible candidates
end

class SmartSudokuBoard < SudokuBoard

  # returns all the feasible candidates
  # for the cell at index n
  def candidates_for_cell(n)

    r, c = coordinates_for_cell(n)

    row_contents = row(r).split('')
    column_contents = column(c).split('')
    box_contents = box(r, c).split('')

    others = (row_contents + column_contents + box_contents).uniq
    candidates = ((1..9).to_a.map(&:to_s) - others)

    return candidates

  end

  # tries to solve the board by filling in cells
  # with only one feasible candidate
  def solve_by_logic

    no_edits_this_run = false

    until no_edits_this_run

      min_candidates_n = min_candidates = nil
      no_edits_this_run = true

      each_empty_cell do |_, n|

        candidates = candidates_for_cell(n)

        case candidates.length
        when 0
          # there are no candidates!?
          # .. the board must be impossible to solve
          raise ImpossibleBoard
        when 1
          # there's only one candidate!?
          # ..that's the only possible value
          # that the cell can have.
          # so fill it in
          @board[n] = candidates.first
          no_edits_this_run = false
        else

          # only save the candidates if we need them for later
          if no_edits_this_run && (min_candidates.nil? || (candidates.length < min_candidates.length))
            min_candidates = candidates
            min_candidates_n = n
          end

        end

      end

    end

    # return the index of the cell with the least number candidates
    # and the possible candidates
    # if the board is solved, return (nil, nil)
    return min_candidates_n, min_candidates

  end

  # returns whether or not the board is solved
  def solved?
    ! @board.include?(0.to_s)
  end
  
  # returns a (deep) copy of itself
  def clone
    # REFACTOR:
    # why doesn't self.new work?
    SmartSudokuBoard.new(@board.dup)
  end
  
end

def solve_by_brute_force(board)

  # until the board is solved
  #   # substitute as many candidates as possible by logic (scan)
  #   min_n, min_candidates = board.solve_by_logic
  #
  #   if it's solved?
  #     print board
  #     return
  #   else it isn't
  #     for each min_candidate:
  #       substitute cell n with min_candidate
  #       begin
  #         solve that board (solve_by_brute_force(board))
  #       rescue ImpossibleBoard
  #         # by going to the next candidate
  #         next
  #       end


  board = board.clone

  min_n, min_candidates = board.solve_by_logic

  if board.solved?
    # if the board is solved, print it and return
    puts board
    puts 'Has duplicates?: ' + board.has_duplicates?.to_s
    return
  else

    r, c = board.coordinates_for_cell(min_n)

    min_candidates.each do |candidate|

      board[r,c] = candidate

      begin
        return solve_by_brute_force(board)
      rescue ImpossibleBoard
        next
      end

    end

    raise ImpossibleBoard
  end

end

class Array
  def only_uniq_elements?
    self.length == self.uniq.length
  end
end

class String
  def to_a
    self.split('')
  end
end

##############################################################################################################
##############################################################################################################
#################################          DRIVER CODE             ###########################################
##############################################################################################################
##############################################################################################################

# b = SmartSudokuBoard.new('703800000020000013400000000000680401009700500000405306000000600000501000580060000')
# b = SmartSudokuBoard.new('081702500095010080400009630006078200710040090520001408000560804207000000000903067')

unsolved_boards = '105802000090076405200400819019007306762083090000061050007600030430020501600308900
005030081902850060600004050007402830349760005008300490150087002090000600026049503
096040001100060004504810390007950043030080000405023018010630059059070830003590007
105802000090076405200400819019007306762083090000061050007600030430020501600308900
005030081902850060600004050007402830349760005008300490150087002090000600026049503
290500007700000400004738012902003064800050070500067200309004005000080700087005109
080020000040500320020309046600090004000640501134050700360004002407230600000700450
608730000200000460000064820080005701900618004031000080860200039050000100100456200
370000001000700005408061090000010000050090460086002030000000000694005203800149500
000689100800000029150000008403000050200005000090240801084700910500000060060410000
030500804504200010008009000790806103000005400050000007800000702000704600610300500
000075400000000008080190000300001060000000034000068170204000603900000020530200000
300000000050703008000028070700000043000000000003904105400300800100040000968000200
302609005500730000000000900000940000000000109000057060008500006000000003019082040'

unsolved_boards.split("\n").each do |unsolved_board|
  # p unsolved_board
  puts
  puts
  b = SmartSudokuBoard.new(unsolved_board)
  solve_by_brute_force(b)
  # b.solve_by_logic
  # puts b
end

##############################################################################################################
##############################################################################################################
#################################          TESTING                 ###########################################
##############################################################################################################
##############################################################################################################
require 'rspec'


describe 'SudokuBoard' do

  before(:each) do
    board = '123456789' * 9
    @b = SudokuBoard.new(board)
    board2 = '786252943888277352549159278278355684537511675227872545564487142339567826932888419'
    @b2 = SudokuBoard.new(board2)
  end

  it 'should allow to return row in a board' do
    @b.row(1).should == '123456789'
    @b.row(2).should == '123456789'
    @b.row(8).should == '123456789'
  end

  it 'should allow to iterate over a column in a board' do
    @b.column(0).should == '111111111'
    @b.column(4).should == '555555555'
  end

  it 'should return the contents of a box, given the coordinates of a cell within it' do
    @b2.box(0,1).should == '786888549'
    @b2.box(4,4).should == '355511872'
    @b2.box(0,8).should == '943352278'
    @b2.box(3,5).should == '355511872'
    @b2.box(5,7).should == '684675545'
  end

  it 'should return the right coordinates for a cell' do
    @b.coordinates_for_cell(0).should == [0,0]
    @b.coordinates_for_cell(4).should == [0,4]
    @b.coordinates_for_cell(80).should == [8,8]
    @b.coordinates_for_cell(31).should == [3,4]
  end

  it 'should return the right cell for a set of coordinates' do
    @b.cell_for_coordinates(0,0).should == 0
    @b.cell_for_coordinates(3,6).should == 33
    @b.cell_for_coordinates(6,0).should == 54
    @b.cell_for_coordinates(8,8).should == 80
    @b.cell_for_coordinates(3,4).should == 31
  end

  it 'should return the right box for a set of coordinates' do
    @b.box_for_coordinates(0,0).should == 0
    @b.box_for_coordinates(1,4).should == 1
    @b.box_for_coordinates(4,7).should == 5
    @b.box_for_coordinates(6,8).should == 8
    @b.box_for_coordinates(8,3).should == 7
  end

  it 'should return the right value of the cell, given a set of coordinates' do
    @b2[8,6].should == 4.to_s
    @b2[3,0].should == 2.to_s
    @b2[1,7].should == 5.to_s
  end

  it 'should be able to change a cell, given the right coordinates' do
    @b[0,0] = 0
    @b.row(0).should == '023456789'

    @b[0,6] = 0
    @b.row(0).should == '023456089'

    @b[3,4] = 0
    @b.row(3).should == '123406789'

    @b2[5,4] = 0
    @b2[5,2] = 0
    @b2[5,0] = 9
    @b2.row(5).should == '920802545'
  end

  it 'should be able to return a string representation itself' do
    board_s = "123456789\n" * 9
    @b.to_s.should == board_s
  end

end
