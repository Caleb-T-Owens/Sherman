class PuzzleCompletionsController < ApplicationController
  before_action :set_puzzle
  before_action :set_puzzle_completion, except: %i[mark_completed_untimed start_timed]

  def edit; end

  def update
    respond_to do |format|
      if @puzzle_completion.update(puzzle_completion_params)
        format.html { redirect_to @puzzle.site, notice: "Puzzle completion was successfully updated." }
        # format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit, status: :unprocessable_entity }
        # format.json { render json: @puzzle_completion.errors, status: :unprocessable_entity }
      end
    end
  end

  def mark_completed_untimed
    return redirect_to @puzzle.site notice: "Completion already exists" if PuzzleCompletion.exists?(user: current_user, puzzle: @puzzle)

    @puzzle_completion = PuzzleCompletion.new(
      user: current_user,
      puzzle: @puzzle,
      completed_untimed: true
    )

    if @puzzle_completion.save
      flash[:notice] = "Succesfully saved"
    else
      flash[:notice] = "Something went wrong"
    end

    redirect_to @puzzle.site
  end

  def start_timed
    return redirect_to @puzzle.site notice: "Completion already exists" if PuzzleCompletion.exists?(user: current_user, puzzle: @puzzle)

    @puzzle_completion = PuzzleCompletion.new(
      user: current_user,
      puzzle: @puzzle,
      started_at: DateTime.now
    )

    if @puzzle_completion.save
      flash[:notice] = "Succesfully saved"
    else
      flash[:notice] = "Something went wrong"
    end

    redirect_to @puzzle.site
  end

  def finish_timed
    @puzzle_completion.finished_at = DateTime.now

    if @puzzle_completion.save
      flash[:notice] = "Succesfully saved"
    else
      flash[:notice] = "Something went wrong"
    end

    redirect_to @puzzle.site
  end

  private

  def set_puzzle
    @puzzle = Puzzle.find(params[:puzzle_id])
  end

  def set_puzzle_completion
    @puzzle_completion = PuzzleCompletion.find(params[:id])
  end

  def puzzle_completion_params
    params
      .require(:puzzle_completion)
      .permit(:started_at, :finished_at, :completed_untimed)
  end
end
