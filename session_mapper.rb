class SessionMapper
  def self.call(old_times, new_times)
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
