# Session Mapper
For a given collection of 8 old sessions, where 2 have been `suspended`, this maps the old `booked` sessions to a collection of 6 new available timeslots, based on the smallest total movement of time across all sessions. Remaining, old, `available` sessions are them mapped using the same strategy to any remaining `available` new sessions.


# Demo
To run the demo run the following command from the terminal:

```ruby ./demo.rb```

Optional logging can be enabled/disabled by changing the `ENABLED` flag in `./logging.rb`

# Other strategies

### Naive Map
There is a really basic mapper I've left in, called `migrate_sessions_naive` - this simply strips out the `suspended` sessions, then maps the old sessions to the new sessions based on their index within their enumerator.

### Fewest Moves
The solution here does a 'closest' match, where it is looking for the smallest cumulative amount of minutes bookings are moved by. A strategy I would have liked to try given more time, or a real world setting, would be to compare the results of this against a 'fewest moves' strategy.

For example, the strategy in my solution would move 5 sessions by 15 minutes each over moving 1 session by 90 minutes and migrating the remaing ones to  exact start-time-matches (were such a mapping possible), which could cause more people to have to adjust their schedule by a small time, rather than fewer people to have to make larger adjustments.
