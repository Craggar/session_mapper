require 'time'

class SessionMapper
  def self.call(old_times, new_times)
    mapper = new(old_times, new_times)
    mapper.migrate_sessions
  end

  attr_reader :old_times, :new_times
  def initialize(old_times, new_times)
    @old_times = old_times
    @new_times = new_times
  end

  def migrate_sessions_naive
    old_sessions.each_with_object({}).with_index do |(old_session, new_mappings), index|
      new_mappings[old_session.starts_at] = new_sessions[index].tap do |new_session|
        new_session.set_state(old_session.state)
      end
    end
  end

  def migrate_sessions
    Logging.log "Old Sessions: #{old_sessions.count}"
    Logging.log "      Booked: #{old_sessions_booked.count}"
    Logging.log "   Available: #{old_sessions_available.count}"
    Logging.log "New Sessions: #{new_sessions.count}"
    Logging.log "   Available: #{new_sessions_available.count}"

    Logging.log "\nmigrating booked sessions"
    migrate_booked_sessions

    Logging.log "\nNew Sessions: #{new_sessions.count}"
    Logging.log "   Available: #{new_sessions_available.count}"
  end

  private

  def migrate_booked_sessions
    ranker = Ranker.new(old_sessions_booked, new_sessions_available)
    ranker.apply_best_fit

  end

  def new_sessions_available
    new_sessions.select(&:available?)
  end

  def new_sessions
    @new_sessions ||= Session::New.collection(new_times)
  end

  def old_sessions_booked
    @old_sessions_booked = old_sessions.select(&:booked?)
  end

  def old_sessions_available
    @old_sessions_available = old_sessions.select(&:available?)
  end

  def old_sessions
    @old_sessions ||= Session::Old.collection(old_times)
  end
end

class Ranker
  attr_reader :old_sessions, :new_sessions

  def initialize(old_sessions, new_sessions)
    @old_sessions = old_sessions
    @new_sessions = new_sessions
    Logging.log "ranking #{old_sessions.count} old sessions into #{new_sessions.count} new_sessions"
  end

  def apply_best_fit
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

module Session
  class Base
    def self.collection(sessions_hash)
      sessions_hash.map {|attrs| new(attrs) }
    end

    attr_reader :starts_at, :ends_at, :state

    def initialize(opts = {})
      @starts_at = Time.parse(opts[:starts_at])
      @ends_at = Time.parse(opts[:ends_at])
      @state = opts[:state] || "available"
    end

    def set_state(new_state)
      @state = new_state
    end
  end

  class New < Base
    attr_reader :old_session

    def assign(old_session)
      old_session.assign_new_session(self)
      @old_session = old_session
    end

    def available?
      old_session.nil?
    end
  end

  class Old < Base
    attr_reader :new_session

    def deltas_from(new_sessions)
      new_sessions.each_with_object({}) do |new_session, hash|
        hash[new_session] = (new_session.starts_at - starts_at).abs
      end
    end

    def assign_new_session(new_session)
      @new_session = new_session
    end

    def booked?
      state == "booked"
    end

    def available?
      state == "available"
    end
  end
end

class Logging
  ENABLED = true

  def self.log(msg)
    return unless ENABLED

    puts msg
  end
end

old_times = [{
  starts_at: '2021-06-23T09:00:00Z',
  ends_at: '2021-06-23T09:45:00Z',
  state: 'booked'
},{
  starts_at: '2021-06-23T09:45:00Z',
  ends_at: '2021-06-23T10:30:00Z',
  state: 'suspended'
},{
  starts_at: '2021-06-23T10:30:00Z',
  ends_at: '2021-06-23T11:15:00Z',
  state: 'booked'
},{
  starts_at: '2021-06-23T11:15:00Z',
  ends_at: '2021-06-23T12:00:00Z',
  state: 'suspended'
},{
  starts_at: '2021-06-23T13:30:00Z',
  ends_at: '2021-06-23T14:15:00Z',
  state: 'available'
},{
  starts_at: '2021-06-23T14:15:00Z',
  ends_at: '2021-06-23T15:00:00Z',
  state: 'available'
},{
  starts_at: '2021-06-23T15:00:00Z',
  ends_at: '2021-06-23T15:45:00Z',
  state: 'booked'
},{
  starts_at: '2021-06-23T15:45:00Z',
  ends_at: '2021-06-23T16:30:00Z',
  state: 'booked'
}]

new_times = [{
  starts_at: '2021-06-23T09:00:00Z',
  ends_at: '2021-06-23T09:50:00Z'
},{
  starts_at: '2021-06-23T10:00:00Z',
  ends_at: '2021-06-23T10:50:00Z'
},{
  starts_at: '2021-06-23T11:00:00Z',
  ends_at: '2021-06-23T11:50:00Z'
},{
  starts_at: '2021-06-23T13:00:00Z',
  ends_at: '2021-06-23T13:50:00Z'
},{
  starts_at: '2021-06-23T14:00:00Z',
  ends_at: '2021-06-23T14:50:00Z'
},{
  starts_at: '2021-06-23T15:00:00Z',
  ends_at: '2021-06-23T15:50:00Z'
}]

SessionMapper.call(old_times, new_times)
