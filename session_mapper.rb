require 'time'

class SessionMapper
  def self.call(old_times, new_times)
    mapper = new(old_times, new_times)
    pp mapper.migrate_sessions
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
    puts "New Sessions: #{new_sessions.count}"
    puts "Old Sessions: #{old_sessions.count}"
    puts "      Booked: #{old_sessions_booked.count}"
    puts "   Available: #{old_sessions_available.count}"
  end

  private

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

    def available?
      old_session.nil?
    end
  end

  class Old < Base
    def deltas_from(new_sessions)
      new_sessions.each_with_object({}) do |new_session, hash|
        hash[new_session] = (new_session.starts_at - starts_at).abs
      end
    end

    def booked?
      state == "booked"
    end

    def available?
      state == "available"
    end
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
