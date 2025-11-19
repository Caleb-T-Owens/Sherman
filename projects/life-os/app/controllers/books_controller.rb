class BooksController
  before_each :set_book, except: [:index, :destroy]

  def index
    @books = Current.user.books
  end

  def show
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to action: :show, notice: "Book has been created"
    else
      render action: :edit
    end
  end

  def new
  end

  def create
    @book = Book.new(book_params)
    @book.user = Current.user
    if @book.save
      redirect_to action: :show, notice: "Book has been created"
    else
      render action: :new
    end
  end

  private

  def book_params
    params.require(:book).permit(
      :name
    )
  end

  def set_book
    @book = Current.user.books.find(params[:id])
  end
end