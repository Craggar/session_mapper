class Ranker
  attr_reader :old_sessions, :new_sessions

  def self.rank_and_migrate!(old_sessions, new_sessions)
    new(old_sessions, new_sessions).apply_best_fit!
  end

  def initialize(old_sessions, new_sessions)
    @old_sessions = old_sessions
    @new_sessions = new_sessions
    Logging.log "ranking #{old_sessions.count} old sessions into #{new_sessions.count} new_sessions"
  end

  def apply_best_fit!
    old_sessions.each_with_index do |old_session, index|
      new_session = lowest_total_delta[index][0]
      new_session.assign(old_session)
    end
  end

  private

  def lowest_total_delta
    @lowest_total_delta ||= ranked_combinations_by_total_delta.first
  end

  def ranked_combinations_by_total_delta
    @ranked_combinations ||= viable_combinations.sort_by do |result|
      result.to_h.values.sum
    end
  end

  def viable_combinations
    @viable_combinations ||= all_combinations.reject do |result|
      result.count != result.to_h.keys.count
    end
  end

  ###################
  # Not a fan of this
  # Need to grab all possible combinations of 'preferences' for all old sessions
  # into new_sessions where preference is based on 'distance' in seconds between
  # the old time and the new time.
  def all_combinations
    @all_combinations = delta_indices.map do |indices|
      indices.map.with_index do |delta_index, old_session_index|
        session_deltas[old_session_index].to_a[delta_index]
      end
    end
  end

  def delta_indices
    @delta_indices ||= (0...new_sessions.count).to_a.repeated_permutation(old_sessions.count)
  end
  # End of Not a fan of this
  ##########################

  def session_deltas
    @session_deltas ||= old_sessions.map do |session|
      session.deltas_from(new_sessions).sort_by { |_time, delta| delta }.to_h
    end
  end
end
