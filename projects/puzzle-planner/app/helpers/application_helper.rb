module ApplicationHelper
  def completed_in(puzzle_completion)
    if puzzle_completion.completed_untimed
      "was untimed"
    else
      if puzzle_completion.finished_at
        "in #{distance_of_time_in_words(puzzle_completion.started_at, puzzle_completion.finished_at)}"
      else
        "#{distance_of_time_in_words(puzzle_completion.started_at, DateTime.now)} taken so far"
      end
    end
  end
end
