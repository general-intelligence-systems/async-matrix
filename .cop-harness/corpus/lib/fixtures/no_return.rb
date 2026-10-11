# frozen_string_literal: true

def guard(value)
  if value
    return 1
  end

  2
end

def bare(value)
  if value
    return
  end

  3
end

def unless_guard(value)
  unless value
    return 4
  end

  5
end

def modifier(value)
  return 6 if value
  7
end

def plain
  8
end
