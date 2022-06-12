class Logging
  ENABLED = true

  def self.log(msg)
    return unless ENABLED

    puts msg
  end
end
