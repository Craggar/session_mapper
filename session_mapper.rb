require 'time'
require_relative 'session'
require_relative 'ranker'
require_relative 'logging'

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

    migrate_available_sessions

    Logging.log "\nNew Sessions: #{new_sessions.count}"
    Logging.log "   Available: #{new_sessions_available.count}"
  end

  private

  def migrate_booked_sessions
    Ranker.rank_and_migrate!(old_sessions_booked, new_sessions_available)
  end

  def migrate_available_sessions
    Ranker.rank_and_migrate!(old_sessions_available, new_sessions_available)
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
