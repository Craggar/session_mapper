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

    def summary
      {
        starts_at: starts_at,
        ends_at: ends_at,
        state: state
      }
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

    def suspended?
      state == "suspended"
    end

    def new_session_summary
      new_session&.summary
    end
  end
end
