module UserMetricsHelper
  def total_rankings
    User.all.map do |user|
      total = user.puzzle_completions.size
      timed = user.puzzle_completions.reject { _1.completed_untimed }.size

      { username: user.username, total:, timed: }
    end.sort_by { _1[:total] }
  end
end
