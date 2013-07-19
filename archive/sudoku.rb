class SudokuBoard

  def initialize(board)
    raise ArgumentError.new('Invalid input length') if board.length != 81
    if board.is_a? String

    end
    @board = board
  end

  # rows are numbered 0..8
  # returns the elements in row n
  # as an array
  def row(n)
    beginning_idx = 9 * n
    ending_idx = 9 * (n + 1) - 1
    s_to_a @board[beginning_idx..ending_idx]
  end

  def each_row(&block)
    (0..8).each do |r|
      yield row(r)
    end
  end

  # columns are numbered 0..8
  # returns the elements in row n
  # as an array
  def column(n)
    column = []
    each_row do |row|
      column << row[n]
    end
    return column
  end

  def each_column(&block)
    (0..8).each do |c|
      yield col(c)
    end
  end

  def box(n)

  end

  def to_s
    str = ''
    each_row do |r|
      str += r.join + "\n"
    end
  end
  private

  def s_to_a(str)
    str.each_char.to_a
  end

end

# testing
require 'rspec'


board = '123456789' * 9

describe 'SudokuBoard' do

  it 'should allow to return row in a board' do
    b = SudokuBoard.new(board)
    b.row(1).should == '123456789'.each_char.to_a
    b.row(2).should == '123456789'.each_char.to_a
    b.row(8).should == '123456789'.each_char.to_a
  end

  it 'should allow to iterate over a column in a board' do
    b = SudokuBoard.new(board)
    b.column(0).should == '111111111'.each_char.to_a
    b.column(4).should == '555555555'.each_char.to_a
  end

  it 'should be able to print itself' do
    b = SudokuBoard.new(board)

    board_s = "123456789\n" * 9
    b.to_s.should == board_s
  end

end
